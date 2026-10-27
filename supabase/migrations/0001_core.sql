create extension if not exists pgcrypto;

create type public.file_kind as enum ('debrief','transcript','dossier','report','log','source_code','upload');
create type public.finding_kind as enum ('text_extraction','machine_id','code_diff','redaction','physical','inconsistency','energy','transcript_cue','other');
create type public.cabinet_status as enum ('suspect','origin','active','locked');
create type public.verification_status as enum ('unverified','verified','rejected');
create type public.activity_type as enum ('login','file_uploaded','finding_created','pin_added','pin_removed','connection_valid','connection_invalid','sighting_reported','badge_earned','case_solved');

create sequence public.agent_number_seq;

create table public.agents (
  id uuid primary key references auth.users(id) on delete cascade,
  codename text not null unique check (codename ~ '^[A-Za-z0-9_-]{3,24}$'),
  agent_number text not null unique default 'EXUN-' || lpad(nextval('public.agent_number_seq')::text, 4, '0'),
  full_name text check (char_length(full_name) <= 80),
  avatar_path text,
  role text not null default 'field_agent' check (role in ('field_agent','analyst','admin')),
  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.cases (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  summary text,
  status text not null default 'open' check (status in ('open','solved','closed')),
  opened_at timestamptz not null default now()
);

create table public.case_files (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cases(id) on delete cascade,
  owner_id uuid references public.agents(id) on delete cascade,
  slug text not null,
  title text not null,
  kind public.file_kind not null,
  bucket text not null check (bucket in ('case-files','agent-uploads')),
  storage_path text not null,
  mime_type text not null,
  size_bytes bigint check (size_bytes <= 20971520),
  sha256 text,
  doc_date date,
  extracted_text text,
  meta jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create unique index case_files_slug_uq on public.case_files (case_id, coalesce(owner_id, '00000000-0000-0000-0000-000000000000'::uuid), slug);

create table public.energy_readings (
  id bigint generated always as identity primary key,
  case_id uuid not null references public.cases(id) on delete cascade,
  source_file_id uuid references public.case_files(id),
  day_no smallint not null,
  reading_date date not null,
  meter_kwh numeric(10,2) not null,
  reported_usage_kwh numeric(10,2) not null,
  highlighted boolean not null default false,
  unique (case_id, day_no), unique (case_id, reading_date)
);
create view public.energy_readings_analyzed with (security_invoker = true) as
with readings as (
  select e.*, e.meter_kwh - lag(e.meter_kwh) over (partition by e.case_id order by e.reading_date) as meter_delta_kwh
  from public.energy_readings e
), medians as (
  select case_id, percentile_cont(0.5) within group (order by reported_usage_kwh) as median_kwh
  from public.energy_readings group by case_id
)
select r.*, m.median_kwh,
  (r.meter_delta_kwh is not null and abs(r.meter_delta_kwh - r.reported_usage_kwh) > 0.05) as is_discrepancy,
  (coalesce(r.meter_delta_kwh, r.reported_usage_kwh) > 10 * m.median_kwh) as is_spike
from readings r join medians m using (case_id);

create table public.cabinets (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cases(id) on delete cascade,
  slug text not null unique,
  name text not null,
  address text not null,
  district text,
  game_title text not null default 'The Reckoning V: Origins',
  machine_id text not null unique check (machine_id ~ '^[A-Z2-7]+$'),
  map_x numeric(5,2) not null check (map_x between 0 and 100),
  map_y numeric(5,2) not null check (map_y between 0 and 100),
  status public.cabinet_status not null default 'suspect',
  clue_key text generated always as ('cabinet.' || replace(slug, '-', '_')) stored,
  created_at timestamptz not null default now()
);

create table public.sightings (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cases(id) on delete cascade,
  cabinet_id uuid references public.cabinets(id) on delete set null,
  slug text unique,
  seen_at timestamptz not null,
  map_x numeric(5,2) not null check (map_x between 0 and 100),
  map_y numeric(5,2) not null check (map_y between 0 and 100),
  label text not null,
  description text check (char_length(description) <= 500),
  source text not null check (source in ('transcript','field_report','agent_report','simulation')),
  source_file_id uuid references public.case_files(id),
  reported_by uuid references public.agents(id) on delete set null,
  status public.verification_status not null default 'unverified',
  confidence numeric(3,2) not null default 0.50 check (confidence between 0 and 1),
  clue_key text generated always as ('sighting.' || replace(coalesce(slug, ''), '-', '_')) stored,
  created_at timestamptz not null default now()
);

create table public.findings (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references public.agents(id) on delete cascade,
  case_id uuid not null references public.cases(id) on delete cascade,
  case_file_id uuid references public.case_files(id) on delete set null,
  finding_key text not null,
  kind public.finding_kind not null,
  title text not null check (char_length(title) <= 160),
  detail jsonb not null default '{}',
  confidence numeric(3,2) not null default 0.80 check (confidence between 0 and 1),
  severity smallint not null default 1 check (severity between 1 and 3),
  source text not null default 'lens' check (source in ('lens','manual','seed')),
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  unique (agent_id, case_id, finding_key)
);

create table public.clue_nodes (
  key text primary key check (key ~ '^[a-z_]+([.][a-z0-9_-]+)+$'),
  case_id uuid not null references public.cases(id) on delete cascade,
  kind public.finding_kind not null,
  title text not null,
  story_note text
);
create table public.clue_links (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cases(id) on delete cascade,
  clue_a text not null references public.clue_nodes(key),
  clue_b text not null references public.clue_nodes(key),
  explanation text not null,
  weight smallint not null default 1 check (weight between 1 and 5),
  is_required boolean not null default false,
  check (clue_a < clue_b),
  unique (case_id, clue_a, clue_b)
);

create table public.pins (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references public.agents(id) on delete cascade,
  case_id uuid not null references public.cases(id) on delete cascade,
  finding_id uuid references public.findings(id) on delete cascade,
  cabinet_id uuid references public.cabinets(id) on delete cascade,
  sighting_id uuid references public.sightings(id) on delete cascade,
  clue_key text references public.clue_nodes(key),
  pos_x real not null default 0,
  pos_y real not null default 0,
  note text check (char_length(note) <= 280),
  created_at timestamptz not null default now(),
  check (num_nonnulls(finding_id, cabinet_id, sighting_id) = 1)
);
create unique index pins_target_uq on public.pins (agent_id, case_id, coalesce(finding_id, cabinet_id, sighting_id));

create table public.connections (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references public.agents(id) on delete cascade,
  case_id uuid not null references public.cases(id) on delete cascade,
  from_pin uuid not null references public.pins(id) on delete cascade,
  to_pin uuid not null references public.pins(id) on delete cascade,
  link_id uuid references public.clue_links(id),
  is_valid boolean not null default false,
  explanation text,
  created_at timestamptz not null default now(),
  check (from_pin < to_pin),
  unique (from_pin, to_pin)
);

create table public.case_progress (
  agent_id uuid not null references public.agents(id) on delete cascade,
  case_id uuid not null references public.cases(id) on delete cascade,
  links_found smallint not null default 0,
  links_total smallint not null,
  required_found smallint not null default 0,
  required_total smallint not null,
  theory_pct numeric(5,2) not null default 0 check (theory_pct between 0 and 100),
  solved_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (agent_id, case_id)
);

create table public.activity (
  id bigint generated always as identity primary key,
  agent_id uuid not null references public.agents(id) on delete cascade,
  case_id uuid references public.cases(id) on delete cascade,
  type public.activity_type not null,
  ref_id uuid,
  payload jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create table public.badges (key text primary key, name text not null, description text not null, icon text not null, criteria jsonb not null, sort smallint not null default 0);
create table public.agent_badges (agent_id uuid references public.agents(id) on delete cascade, badge_key text references public.badges(key), earned_at timestamptz not null default now(), primary key (agent_id, badge_key));

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = '' as $$
declare v_name text := left(regexp_replace(coalesce(new.raw_user_meta_data->>'codename',''), '[^A-Za-z0-9_-]', '', 'g'), 24);
begin
  if length(v_name) < 3 or exists (select 1 from public.agents where codename = v_name) then
    v_name := 'agent_' || substr(replace(new.id::text, '-', ''), 1, 8);
  end if;
  insert into public.agents (id, codename, is_demo) values (new.id, v_name, coalesce((new.raw_app_meta_data->>'is_demo')::boolean, false));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.recompute_progress(p_agent uuid, p_case uuid) returns public.case_progress language plpgsql security definer set search_path = '' as $$
declare result public.case_progress; total_weight numeric; found_weight numeric; required_count smallint; required_found smallint;
begin
  select coalesce(sum(weight), 0), coalesce(sum(weight) filter (where id in (select link_id from public.connections where agent_id = p_agent and case_id = p_case and is_valid)), 0), count(*) filter (where is_required), count(*) filter (where is_required and id in (select link_id from public.connections where agent_id = p_agent and case_id = p_case and is_valid)) into total_weight, found_weight, required_count, required_found from public.clue_links where case_id = p_case;
  insert into public.case_progress(agent_id, case_id, links_found, links_total, required_found, required_total, theory_pct, solved_at)
  values (p_agent, p_case, (select count(distinct link_id) from public.connections where agent_id = p_agent and case_id = p_case and is_valid), (select count(*) from public.clue_links where case_id = p_case), required_found, required_count, case when total_weight = 0 then 0 else round(found_weight / total_weight * 100, 2) end, case when required_found = required_count and required_count > 0 then now() else null end)
  on conflict (agent_id, case_id) do update set links_found = excluded.links_found, links_total = excluded.links_total, required_found = excluded.required_found, required_total = excluded.required_total, theory_pct = excluded.theory_pct, solved_at = coalesce(public.case_progress.solved_at, excluded.solved_at), updated_at = now()
  returning * into result;
  return result;
end $$;

create or replace function public.save_findings(p_case uuid, p_findings jsonb) returns setof public.findings language plpgsql security definer set search_path = '' as $$
declare item jsonb; inserted public.findings;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if jsonb_typeof(p_findings) <> 'array' or jsonb_array_length(p_findings) = 0 or jsonb_array_length(p_findings) > 200 then raise exception 'invalid_payload' using errcode = '22023'; end if;
  for item in select * from jsonb_array_elements(p_findings) loop
    if coalesce(item->>'finding_key', '') = '' or coalesce(item->>'title', '') = '' then raise exception 'invalid_payload' using errcode = '22023'; end if;
    insert into public.findings(agent_id, case_id, finding_key, kind, title, detail, confidence, severity, source, verified)
    values (auth.uid(), p_case, item->>'finding_key', (item->>'kind')::public.finding_kind, item->>'title', coalesce(item->'detail','{}'), least(coalesce((item->>'confidence')::numeric, .8), 1), coalesce((item->>'severity')::smallint, 1), coalesce(item->>'source','lens'), false)
    on conflict (agent_id, case_id, finding_key) do update set confidence = greatest(public.findings.confidence, excluded.confidence), detail = excluded.detail, title = excluded.title
    returning * into inserted;
    return next inserted;
  end loop;
end $$;

create or replace function public.create_connection(p_from uuid, p_to uuid) returns public.connections language plpgsql security definer set search_path = '' as $$
declare a public.pins; b public.pins; link public.clue_links; result public.connections;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if p_from = p_to then raise exception 'self_connection' using errcode = '22023'; end if;
  select * into a from public.pins where id = p_from and agent_id = auth.uid();
  select * into b from public.pins where id = p_to and agent_id = auth.uid();
  if a.id is null or b.id is null then raise exception 'pin_not_found' using errcode = 'P0002'; end if;
  if a.case_id <> b.case_id then raise exception 'case_mismatch' using errcode = '22023'; end if;
  select * into link from public.clue_links where case_id = a.case_id and clue_a = least(a.clue_key, b.clue_key) and clue_b = greatest(a.clue_key, b.clue_key);
  insert into public.connections(agent_id, case_id, from_pin, to_pin, link_id, is_valid, explanation)
  values (auth.uid(), a.case_id, least(a.id,b.id), greatest(a.id,b.id), link.id, link.id is not null, link.explanation)
  on conflict (from_pin, to_pin) do update set link_id = excluded.link_id, is_valid = excluded.is_valid, explanation = excluded.explanation
  returning * into result;
  perform public.recompute_progress(auth.uid(), a.case_id);
  return result;
end $$;

alter table public.agents enable row level security;
alter table public.cases enable row level security;
alter table public.case_files enable row level security;
alter table public.energy_readings enable row level security;
alter table public.cabinets enable row level security;
alter table public.sightings enable row level security;
alter table public.findings enable row level security;
alter table public.clue_nodes enable row level security;
alter table public.clue_links enable row level security;
alter table public.pins enable row level security;
alter table public.connections enable row level security;
alter table public.case_progress enable row level security;
alter table public.activity enable row level security;
alter table public.badges enable row level security;
alter table public.agent_badges enable row level security;

create policy agents_self on public.agents for select to authenticated using (id = auth.uid());
create policy agents_update on public.agents for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy cases_read on public.cases for select to authenticated using (true);
create policy files_read on public.case_files for select to authenticated using (owner_id is null or owner_id = auth.uid());
create policy energy_read on public.energy_readings for select to authenticated using (true);
create policy cabinets_read on public.cabinets for select to authenticated using (true);
create policy sightings_read on public.sightings for select to authenticated using (status = 'verified' or reported_by = auth.uid());
create policy findings_self on public.findings for select to authenticated using (agent_id = auth.uid());
create policy pins_self on public.pins for all to authenticated using (agent_id = auth.uid()) with check (agent_id = auth.uid());
create policy connections_self on public.connections for select to authenticated using (agent_id = auth.uid());
create policy progress_self on public.case_progress for select to authenticated using (agent_id = auth.uid());
create policy activity_self on public.activity for select to authenticated using (agent_id = auth.uid());
create policy badges_read on public.badges for select to authenticated using (true);
create policy agent_badges_self on public.agent_badges for select to authenticated using (agent_id = auth.uid());

grant execute on function public.save_findings(uuid, jsonb) to authenticated;
grant execute on function public.create_connection(uuid, uuid) to authenticated;
grant execute on function public.recompute_progress(uuid, uuid) to authenticated;
revoke all on public.clue_nodes, public.clue_links from authenticated, anon;
