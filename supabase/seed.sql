insert into public.cases (slug, title, summary) values
('wenoti-arcade-001', 'Wenoti Arcade Anomaly', 'A Reckoning V character may have left its cabinet.')
on conflict (slug) do update set title = excluded.title, summary = excluded.summary;

insert into public.case_files (case_id, slug, title, kind, bucket, storage_path, mime_type, doc_date, extracted_text, meta)
select c.id, v.slug, v.title, v.kind::public.file_kind, 'case-files', v.storage_path, v.mime_type, v.doc_date::date, v.extracted_text, v.meta::jsonb
from public.cases c cross join (values
('case-debrief','Case Debrief','debrief','case-files/case-debrief.pdf','application/pdf','2026-10-24','Machine ID MJWHKZLTNBUXE5A','{}'),
('transcript-a','Transcript A','transcript','case-files/transcript-a.pdf','application/pdf','2026-10-23','10E24X10 Look at the time! Really must go','{}'),
('energy-usage-dossier','Energy Usage Dossier','dossier','case-files/energy-usage-dossier.pdf','application/pdf','2026-10-26','2,684 kWh 503.2 kWh','{"page_count":2}'),
('asset-integrity-report','Asset Integrity Report','report','case-files/asset-integrity-report-2.pdf','application/pdf','2026-10-24','REDACTED dark mark fibres worn fasteners','{}'),
('progress-assessment-log','Progress Assessment Log','log','case-files/progress-assessment-log.pdf','application/pdf','2026-10-25','Agent Nano 2026-10-25 23:54','{}'),
('original-code-reckoning','Original Code Reckoning','source_code','case-files/original-code-reckoning.txt','text/plain','2026-10-20','#include <algorithm> class Character std::clamp','{}'),
('altered-code-reckoning','Altered Code Reckoning','source_code','case-files/altered-code-reckoning.txt','text/plain','2026-10-24','#include <algorithm>','{}')
) as v(slug,title,kind,storage_path,mime_type,doc_date,extracted_text,meta)
where c.slug = 'wenoti-arcade-001'
on conflict (case_id, coalesce(owner_id, '00000000-0000-0000-0000-000000000000'::uuid), slug) do update set extracted_text = excluded.extracted_text;

insert into public.cabinets (case_id, slug, name, address, district, machine_id, map_x, map_y, status)
select id, 'wenoti-92', 'Wenoti Arcade', '92nd Avenue', 'Wenoti', 'MJWHKZLTNBUXE5A', 42.00, 37.00, 'origin' from public.cases where slug = 'wenoti-arcade-001'
on conflict (slug) do nothing;

insert into public.sightings (case_id, slug, seen_at, map_x, map_y, label, description, source, status, confidence)
select id, 'wenoti-oct23', '2026-10-23 22:31:00+05:30', 44, 39, 'POI-1', 'A figure matching the cabinet description was seen leaving the arcade.', 'transcript', 'verified', .95 from public.cases where slug = 'wenoti-arcade-001'
on conflict (slug) do nothing;

insert into public.energy_readings(case_id, day_no, reading_date, meter_kwh, reported_usage_kwh, highlighted)
select c.id, v.day_no, v.reading_date::date, v.meter_kwh, v.reported_kwh, v.highlighted
from public.cases c cross join (values
(1,'2026-10-13',210.00,210.00,false),(2,'2026-10-14',220.00,10.00,false),(3,'2026-10-15',230.00,10.00,false),(4,'2026-10-16',239.00,9.00,false),(5,'2026-10-17',250.00,11.00,false),(6,'2026-10-18',260.00,10.00,false),(7,'2026-10-19',270.00,10.00,false),(8,'2026-10-20',281.00,11.00,false),(9,'2026-10-21',290.00,9.00,false),(10,'2026-10-22',300.00,10.00,false),(11,'2026-10-23',2984.00,2684.00,false),(12,'2026-10-24',3014.70,503.20,false),(13,'2026-10-25',3020.00,5.30,true),(14,'2026-10-26',3030.00,10.00,true)
) as v(day_no,reading_date,meter_kwh,reported_kwh,highlighted) where c.slug = 'wenoti-arcade-001'
on conflict (case_id, day_no) do update set meter_kwh = excluded.meter_kwh, reported_usage_kwh = excluded.reported_usage_kwh, highlighted = excluded.highlighted;

insert into public.clue_nodes(key, case_id, kind, title)
select v.key, c.id, v.kind::public.finding_kind, v.title
from public.cases c cross join (values
('code.character_class_missing','code_diff','Character class removed'),('log.escape_theory','other','Escape theory'),('code.clamp_missing','code_diff','Clamp removed'),('code.algorithm_include_orphaned','code_diff','Orphaned include'),('energy.spike_oct23','energy','October 23 energy spike'),('sighting.wenoti_oct23','other','Wenoti sighting'),('energy.discrepancy_oct24','energy','October 24 discrepancy'),('machine_id.blueshirt','machine_id','Decoded machine ID'),('cabinet.wenoti_92','other','Origin cabinet'),('transcript.bare_wrist','transcript_cue','Bare wrist gesture'),('transcript.look_at_time','transcript_cue','Look at the time'),('physical.fasteners_worn','physical','Worn fasteners'),('physical.panel_offset','physical','Offset panel'),('transcript.accent','transcript_cue','Mixed accent'),('physical.dark_mark_vent','physical','Dark vent mark'),('physical.fibres_vent','physical','Vent fibres'),('transcript.not_working','transcript_cue','Not working'),('transcript.warbling','transcript_cue','Warbling')
) as v(key,kind,title) where c.slug = 'wenoti-arcade-001'
on conflict (key) do nothing;

insert into public.clue_links(case_id, clue_a, clue_b, explanation, weight, is_required)
select c.id, v.a, v.b, v.explanation, v.weight, v.required
from public.cases c cross join (values
('code.character_class_missing','log.escape_theory','The Character class is gone from the altered source, which is Nano''s escape theory',3,true),
('code.character_class_missing','code.clamp_missing','std::clamp lived inside Character::move, the wall keeping it in the game',2,true),
('code.algorithm_include_orphaned','code.clamp_missing','The include stayed behind, but clamp was the only thing using it',2,true),
('energy.spike_oct23','sighting.wenoti_oct23','The 2,684 kWh spike falls on the night POI-1 was seen',3,true),
('code.character_class_missing','energy.discrepancy_oct24','503.2 against a 30.7 meter delta reads as Service Unavailable',3,true),
('cabinet.wenoti_92','machine_id.blueshirt','The ID decodes to blueshirt and belongs to the origin cabinet',2,true),
('transcript.bare_wrist','transcript.look_at_time','It copies the human gesture without knowing what a watch is',2,true),
('physical.fasteners_worn','physical.panel_offset','Panel and screws point to the cabinet being opened from inside',2,true),
('sighting.wenoti_oct23','transcript.look_at_time','The line is what players say on leaving',1,false),
('transcript.accent','transcript.look_at_time','The accent is a blend of many players',1,false),
('physical.dark_mark_vent','physical.fibres_vent','Fibres and heat mark near the vent are consistent with something coming out',1,false),
('energy.spike_oct23','physical.dark_mark_vent','Exit energy and the heat mark line up',1,false),
('transcript.not_working','transcript.warbling','It tried to open the cabinet for the others and failed',1,false)
) as v(a,b,explanation,weight,required) where c.slug = 'wenoti-arcade-001'
on conflict (case_id, clue_a, clue_b) do nothing;

insert into public.badges(key,name,description,icon,criteria,sort) values
('first_scan','First Scan','Saved your first finding','scan','{"type":"count","activity":"finding_created","n":1}',1),
('decoder','Decoder','Decoded the machine ID','key','{"type":"finding","key":"machine_id.blueshirt"}',2),
('code_breaker','Code Breaker','Found the missing Character class','code','{"type":"finding","key":"code.character_class_missing"}',3),
('spike_hunter','Spike Hunter','Found both energy anomalies','bolt','{"type":"finding_pair","keys":["energy.spike_oct23","energy.discrepancy_oct24"]}',4),
('cartographer','Cartographer','Pinned a cabinet and a sighting','map','{"type":"pin_pair","targets":["cabinet","sighting"]}',5),
('first_thread','First Thread','Made a valid connection','link','{"type":"count","activity":"connection_valid","n":1}',6),
('theory_90','Theory 90','Reached 90 percent theory','meter','{"type":"progress","gte":90}',7),
('case_closed','Case Closed','Solved the case','lock','{"type":"solved"}',8)
on conflict (key) do nothing;
