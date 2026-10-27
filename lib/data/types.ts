export type UUID = string;

export type Agent = {
  id: UUID;
  codename: string;
  agent_number: string;
  full_name: string | null;
  avatar_path: string | null;
  role: 'field_agent' | 'analyst' | 'admin';
  is_demo: boolean;
  created_at: string;
  updated_at: string;
};

export type Case = {
  id: UUID;
  slug: string;
  title: string;
  summary: string | null;
  status: 'open' | 'solved' | 'closed';
  opened_at: string;
};

export type CaseFile = {
  id: UUID;
  case_id: UUID;
  owner_id: UUID | null;
  slug: string;
  title: string;
  kind: string;
  bucket: 'case-files' | 'agent-uploads';
  storage_path: string;
  mime_type: string;
  size_bytes: number | null;
  doc_date: string | null;
  extracted_text: string | null;
  meta: Record<string, unknown>;
  created_at: string;
};

export type Finding = {
  id: UUID;
  agent_id: UUID;
  case_id: UUID;
  case_file_id: UUID | null;
  finding_key: string;
  kind: string;
  title: string;
  detail: Record<string, unknown>;
  confidence: number;
  severity: number;
  source: 'lens' | 'manual' | 'seed';
  verified: boolean;
  created_at: string;
};

export type Pin = {
  id: UUID;
  agent_id: UUID;
  case_id: UUID;
  finding_id: UUID | null;
  cabinet_id: UUID | null;
  sighting_id: UUID | null;
  clue_key: string | null;
  pos_x: number;
  pos_y: number;
  note: string | null;
  created_at: string;
};

export type Connection = {
  id: UUID;
  agent_id: UUID;
  case_id: UUID;
  from_pin: UUID;
  to_pin: UUID;
  link_id: UUID | null;
  is_valid: boolean;
  explanation: string | null;
  created_at: string;
};

export type Progress = {
  agent_id: UUID;
  case_id: UUID;
  links_found: number;
  links_total: number;
  required_found: number;
  required_total: number;
  theory_pct: number;
  solved_at: string | null;
  updated_at: string;
};

export type EnergyReading = {
  id: number;
  case_id: UUID;
  source_file_id: UUID | null;
  day_no: number;
  reading_date: string;
  meter_kwh: number;
  reported_usage_kwh: number;
  highlighted: boolean;
  meter_delta_kwh: number | null;
  median_kwh: number;
  is_discrepancy: boolean;
  is_spike: boolean;
};
