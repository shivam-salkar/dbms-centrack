-- ============================================================================
-- JANGANA -- City-Level Census Database Schema (Supabase / PostgreSQL)
-- ============================================================================

create extension if not exists pgcrypto;

-- 1. Administrative Hierarchy
create table if not exists city (
  city_id uuid primary key default gen_random_uuid(),
  city_name varchar(150) not null,
  state_name varchar(100) not null,
  census_year integer not null default 2026,
  created_at timestamptz not null default now(),
  unique (city_name, state_name, census_year)
);

create table if not exists ward (
  ward_id uuid primary key default gen_random_uuid(),
  city_id uuid not null references city(city_id) on delete cascade,
  ward_number integer not null,
  ward_name varchar(150),
  created_at timestamptz not null default now(),
  unique (city_id, ward_number)
);

create table if not exists enumeration_block (
  block_id uuid primary key default gen_random_uuid(),
  ward_id uuid not null references ward(ward_id) on delete cascade,
  block_code varchar(50) not null unique,
  created_at timestamptz not null default now()
);

create table if not exists address (
  address_id uuid primary key default gen_random_uuid(),
  block_id uuid not null references enumeration_block(block_id) on delete cascade,
  house_number varchar(50),
  street_name varchar(200),
  locality varchar(200),
  pin_code varchar(6),
  created_at timestamptz not null default now()
);

-- 2. Field Officers & Enumerators
create table if not exists enumerator (
  enumerator_id uuid primary key default gen_random_uuid(),
  auth_user_id uuid references auth.users(id) on delete set null,
  employee_code varchar(50) not null unique,
  name varchar(150) not null,
  mobile varchar(15),
  role varchar(50) not null default 'Enumerator',
  assigned_block_id uuid references enumeration_block(block_id) on delete set null,
  status varchar(30) not null default 'ACTIVE',
  created_at timestamptz not null default now()
);

create unique index if not exists uq_enumerator_auth_user
  on enumerator(auth_user_id)
  where auth_user_id is not null;

create table if not exists census_visit (
  visit_id uuid primary key default gen_random_uuid(),
  block_id uuid not null references enumeration_block(block_id) on delete cascade,
  enumerator_id uuid not null references enumerator(enumerator_id),
  visit_date date not null default current_date,
  phase varchar(20) not null check (phase in ('PHASE_1','PHASE_2')),
  mode varchar(30) not null default 'FIELD',
  verification_status varchar(30) not null default 'DRAFT',
  created_at timestamptz not null default now()
);

-- 3. Housing & Living Conditions (Phase 1)
create table if not exists building (
  building_id uuid primary key default gen_random_uuid(),
  address_id uuid not null references address(address_id) on delete cascade,
  building_number varchar(50) not null,
  census_house_number varchar(50) not null,
  floor_material varchar(100),
  wall_material varchar(100),
  roof_material varchar(100),
  house_use varchar(100),
  condition varchar(100),
  ownership_status varchar(100),
  dwelling_rooms integer check (dwelling_rooms is null or dwelling_rooms >= 0),
  created_at timestamptz not null default now(),
  unique (address_id, census_house_number)
);

create table if not exists household (
  household_id uuid primary key default gen_random_uuid(),
  building_id uuid not null references building(building_id) on delete cascade,
  household_number varchar(50) not null,
  residents_count integer not null default 0 check (residents_count >= 0),
  head_category varchar(30),
  married_couples_count integer check (married_couples_count is null or married_couples_count >= 0),
  mobile_contact varchar(15),
  head_person_id uuid,
  created_at timestamptz not null default now(),
  unique (building_id, household_number)
);

create table if not exists household_water (
  household_id uuid primary key references household(household_id) on delete cascade,
  source varchar(150) not null,
  availability varchar(100)
);

create table if not exists household_sanitation (
  household_id uuid primary key references household(household_id) on delete cascade,
  latrine_access boolean,
  latrine_type varchar(100),
  wastewater_outlet varchar(150),
  bathing_facility boolean
);

create table if not exists household_cooking (
  household_id uuid primary key references household(household_id) on delete cascade,
  kitchen_available boolean,
  lpg_png_connection boolean,
  main_fuel varchar(100)
);

create table if not exists household_utility (
  household_id uuid primary key references household(household_id) on delete cascade,
  lighting_source varchar(150)
);

create table if not exists household_food (
  household_id uuid primary key references household(household_id) on delete cascade,
  main_cereal varchar(100)
);

create table if not exists household_asset (
  asset_id uuid primary key default gen_random_uuid(),
  household_id uuid not null references household(household_id) on delete cascade,
  asset_type varchar(100) not null,
  available boolean not null default false,
  unique (household_id, asset_type)
);

-- 4. Demographics & Persons (Phase 2)
create table if not exists caste (
  caste_id uuid primary key default gen_random_uuid(),
  caste_name varchar(150) not null,
  category_type varchar(50) not null,
  unique (caste_name, category_type)
);

create table if not exists disability (
  disability_id uuid primary key default gen_random_uuid(),
  disability_type varchar(150) not null,
  severity varchar(50),
  status varchar(50)
);

create table if not exists person (
  person_id uuid primary key default gen_random_uuid(),
  household_id uuid not null references household(household_id) on delete cascade,
  name varchar(200) not null,
  relationship_to_head varchar(100) not null,
  sex varchar(30) not null,
  date_of_birth date,
  age_completed_years integer check (age_completed_years is null or age_completed_years between 0 and 120),
  marital_status varchar(50),
  age_at_marriage integer,
  spouse_person_id uuid references person(person_id) on delete set null,
  nationality varchar(100) default 'Indian',
  religion varchar(100),
  caste_id uuid references caste(caste_id) on delete set null,
  father_person_id uuid references person(person_id) on delete set null,
  mother_person_id uuid references person(person_id) on delete set null,
  disability_id uuid references disability(disability_id) on delete set null,
  created_at timestamptz not null default now()
);

-- Circular FK link for household head
alter table household drop constraint if exists fk_household_head_person;
alter table household add constraint fk_household_head_person
  foreign key (head_person_id) references person(person_id) on delete set null;

-- 5. Language & Education
create table if not exists language (
  language_id uuid primary key default gen_random_uuid(),
  language_name varchar(100) not null unique
);

create table if not exists person_language (
  person_id uuid not null references person(person_id) on delete cascade,
  language_id uuid not null references language(language_id) on delete restrict,
  is_mother_tongue boolean not null default false,
  proficiency_level varchar(50),
  primary key (person_id, language_id)
);

create table if not exists education_level (
  level_id uuid primary key default gen_random_uuid(),
  level_name varchar(150) not null unique
);

create table if not exists education_record (
  education_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references person(person_id) on delete cascade,
  level_id uuid references education_level(level_id) on delete set null,
  literacy_status varchar(50),
  digital_literacy_status varchar(50),
  attendance_status varchar(100),
  stream_discipline varchar(150),
  created_at timestamptz not null default now()
);

-- 6. Economic & Employment
create table if not exists occupation (
  occupation_id uuid primary key default gen_random_uuid(),
  occupation_name varchar(200) not null,
  occupation_code varchar(50) not null unique
);

create table if not exists industry (
  industry_id uuid primary key default gen_random_uuid(),
  industry_name varchar(200) not null,
  industry_code varchar(50) not null unique
);

create table if not exists employment_record (
  employment_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references person(person_id) on delete cascade,
  worked_last_year boolean,
  economic_activity_category varchar(100),
  occupation_id uuid references occupation(occupation_id) on delete set null,
  industry_id uuid references industry(industry_id) on delete set null,
  worker_class varchar(100),
  non_economic_activity varchar(150),
  seeking_or_available_for_work boolean,
  created_at timestamptz not null default now()
);

create table if not exists work_travel (
  travel_id uuid primary key default gen_random_uuid(),
  employment_id uuid not null unique references employment_record(employment_id) on delete cascade,
  mode_of_travel varchar(150),
  travel_time_minutes integer check (travel_time_minutes is null or travel_time_minutes >= 0),
  workplace_location varchar(250)
);

-- 7. Geographic Places & Migration
create table if not exists place (
  place_id uuid primary key default gen_random_uuid(),
  place_name varchar(200) not null,
  place_type varchar(100),
  district varchar(150),
  state varchar(150),
  country varchar(150) not null default 'India'
);

create table if not exists migration_record (
  migration_id uuid primary key default gen_random_uuid(),
  person_id uuid not null unique references person(person_id) on delete cascade,
  birth_place_id uuid references place(place_id) on delete set null,
  last_residence_place_id uuid references place(place_id) on delete set null,
  migration_reason varchar(200),
  duration_of_stay_years numeric(5,2) check (duration_of_stay_years is null or duration_of_stay_years >= 0),
  permanent_address_id uuid references address(address_id) on delete set null,
  created_at timestamptz not null default now()
);

-- 8. Fertility, Health & Identity
create table if not exists fertility_record (
  fertility_id uuid primary key default gen_random_uuid(),
  person_id uuid not null unique references person(person_id) on delete cascade,
  children_surviving integer check (children_surviving is null or children_surviving >= 0),
  children_ever_born_alive integer check (children_ever_born_alive is null or children_ever_born_alive >= 0),
  children_born_last_year integer check (children_born_last_year is null or children_born_last_year >= 0)
);

create table if not exists covid_vaccination (
  vaccination_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references person(person_id) on delete cascade,
  vaccination_place_id uuid references place(place_id) on delete set null,
  vaccination_status varchar(100)
);

create table if not exists bank_account_summary (
  bank_summary_id uuid primary key default gen_random_uuid(),
  person_id uuid not null unique references person(person_id) on delete cascade,
  total_bank_accounts integer not null default 0 check (total_bank_accounts >= 0)
);

create table if not exists contact (
  contact_id uuid primary key default gen_random_uuid(),
  person_id uuid not null unique references person(person_id) on delete cascade,
  mobile_number varchar(15) not null
);

create table if not exists identity_document (
  document_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references person(person_id) on delete cascade,
  document_type varchar(50) not null,
  document_available boolean not null default false,
  document_token text,
  issuing_country varchar(100) default 'India',
  verified_at timestamptz,
  unique (person_id, document_type)
);

-- 9. Census Record & Audit Trail
create table if not exists census_record (
  record_id uuid primary key default gen_random_uuid(),
  visit_id uuid not null references census_visit(visit_id),
  household_id uuid not null references household(household_id),
  phase varchar(20) not null check (phase in ('PHASE_1','PHASE_2')),
  captured_at timestamptz not null default now(),
  submitted_at timestamptz,
  record_status varchar(30) not null default 'DRAFT',
  data_source varchar(50) not null default 'FIELD',
  verified_by uuid references enumerator(enumerator_id) on delete set null
);

create table if not exists audit_log (
  audit_id uuid primary key default gen_random_uuid(),
  record_id uuid not null references census_record(record_id) on delete cascade,
  actor_enumerator_id uuid references enumerator(enumerator_id) on delete set null,
  action_type varchar(100) not null,
  action_timestamp timestamptz not null default now(),
  old_value_hash text,
  new_value_hash text
);

-- ============================================================================
-- Indexes for Query Performance
-- ============================================================================
create index if not exists idx_ward_city on ward(city_id);
create index if not exists idx_block_ward on enumeration_block(ward_id);
create index if not exists idx_address_block on address(block_id);
create index if not exists idx_enumerator_block on enumerator(assigned_block_id);
create index if not exists idx_visit_block on census_visit(block_id);
create index if not exists idx_visit_enumerator on census_visit(enumerator_id);
create index if not exists idx_building_address on building(address_id);
create index if not exists idx_household_building on household(building_id);
create index if not exists idx_person_household on person(household_id);
create index if not exists idx_person_caste on person(caste_id);
create index if not exists idx_person_disability on person(disability_id);
create index if not exists idx_employment_person on employment_record(person_id);
create index if not exists idx_migration_birth_place on migration_record(birth_place_id);
create index if not exists idx_migration_last_residence on migration_record(last_residence_place_id);
create index if not exists idx_census_record_visit on census_record(visit_id);
create index if not exists idx_census_record_household on census_record(household_id);
create index if not exists idx_audit_record on audit_log(record_id);

-- ============================================================================
-- Supabase Row Level Security (RLS)
-- ============================================================================
alter table city enable row level security;
alter table ward enable row level security;
alter table enumeration_block enable row level security;
alter table address enable row level security;
alter table enumerator enable row level security;
alter table census_visit enable row level security;
alter table building enable row level security;
alter table household enable row level security;
alter table household_water enable row level security;
alter table household_sanitation enable row level security;
alter table household_cooking enable row level security;
alter table household_utility enable row level security;
alter table household_food enable row level security;
alter table household_asset enable row level security;
alter table caste enable row level security;
alter table disability enable row level security;
alter table person enable row level security;
alter table language enable row level security;
alter table person_language enable row level security;
alter table education_level enable row level security;
alter table education_record enable row level security;
alter table occupation enable row level security;
alter table industry enable row level security;
alter table employment_record enable row level security;
alter table work_travel enable row level security;
alter table place enable row level security;
alter table migration_record enable row level security;
alter table fertility_record enable row level security;
alter table covid_vaccination enable row level security;
alter table bank_account_summary enable row level security;
alter table contact enable row level security;
alter table identity_document enable row level security;
alter table census_record enable row level security;
alter table audit_log enable row level security;

-- Policies for Reference Tables (Public Read, Authenticated Write)
do $$
declare
  ref_table text;
begin
  for ref_table in select unnest(array[
    'city', 'ward', 'enumeration_block', 'caste', 'disability',
    'language', 'education_level', 'occupation', 'industry', 'place'
  ]) loop
    execute format('drop policy if exists "allow_read_%s" on %I;', ref_table, ref_table);
    execute format('create policy "allow_read_%s" on %I for select using (true);', ref_table, ref_table);
    execute format('drop policy if exists "allow_write_%s" on %I;', ref_table, ref_table);
    execute format('create policy "allow_write_%s" on %I for all to authenticated using (true) with check (true);', ref_table, ref_table);
  end loop;
end $$;

-- Policies for Field / Operational Tables (Authenticated full access, Anon read for demo)
do $$
declare
  op_table text;
begin
  for op_table in select unnest(array[
    'address', 'enumerator', 'census_visit', 'building', 'household',
    'household_water', 'household_sanitation', 'household_cooking', 'household_utility',
    'household_food', 'household_asset', 'person', 'person_language', 'education_record',
    'employment_record', 'work_travel', 'migration_record', 'fertility_record',
    'covid_vaccination', 'bank_account_summary', 'contact', 'identity_document',
    'census_record', 'audit_log'
  ]) loop
    execute format('drop policy if exists "auth_all_%s" on %I;', op_table, op_table);
    execute format('create policy "auth_all_%s" on %I for all to authenticated using (true) with check (true);', op_table, op_table);
    execute format('drop policy if exists "anon_read_%s" on %I;', op_table, op_table);
    execute format('create policy "anon_read_%s" on %I for select to anon using (true);', op_table, op_table);
  end loop;
end $$;

-- ============================================================================
-- Supabase Auth Auto-Sync Trigger
-- ============================================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.enumerator (
    auth_user_id,
    employee_code,
    name,
    mobile,
    role,
    status
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'employee_code', 'OFF-' || substr(new.id::text, 1, 8)),
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.phone,
    coalesce(new.raw_user_meta_data->>'role', 'Enumerator'),
    'ACTIVE'
  )
  on conflict (employee_code) do update
  set auth_user_id = new.id;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- Seed Reference Data
-- ============================================================================

-- Cities
insert into city (city_id, city_name, state_name, census_year) values
  ('11111111-1111-1111-1111-111111111111', 'Lucknow', 'Uttar Pradesh', 2026),
  ('22222222-2222-2222-2222-222222222222', 'Mumbai', 'Maharashtra', 2026),
  ('33333333-3333-3333-3333-333333333333', 'Ernakulam', 'Kerala', 2026),
  ('44444444-4444-4444-4444-444444444444', 'Jaipur', 'Rajasthan', 2026)
on conflict do nothing;

-- Wards
insert into ward (ward_id, city_id, ward_number, ward_name) values
  ('aaaa1111-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 101, 'Hazratganj Central'),
  ('aaaa1111-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 102, 'Gomti Nagar North'),
  ('aaaa2222-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 201, 'Colaba South'),
  ('aaaa3333-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', 301, 'Kochi Central')
on conflict do nothing;

-- Enumeration Blocks
insert into enumeration_block (block_id, ward_id, block_code) values
  ('bbbb1111-0000-0000-0000-000000000001', 'aaaa1111-0000-0000-0000-000000000001', 'EB-LKO-101-A'),
  ('bbbb1111-0000-0000-0000-000000000002', 'aaaa1111-0000-0000-0000-000000000001', 'EB-LKO-101-B'),
  ('bbbb2222-0000-0000-0000-000000000001', 'aaaa2222-0000-0000-0000-000000000001', 'EB-MUM-201-A'),
  ('bbbb3333-0000-0000-0000-000000000001', 'aaaa3333-0000-0000-0000-000000000001', 'EB-COK-301-A')
on conflict do nothing;

-- Castes / Social Categories
insert into caste (caste_name, category_type) values
  ('General', 'GEN'),
  ('Other Backward Classes', 'OBC'),
  ('Scheduled Caste', 'SC'),
  ('Scheduled Tribe', 'ST'),
  ('Economically Weaker Section', 'EWS')
on conflict do nothing;

-- Disabilities
insert into disability (disability_type, severity, status) values
  ('None', 'None', 'Normal'),
  ('In Seeing', 'Moderate', 'Diagnosed'),
  ('In Hearing', 'Moderate', 'Diagnosed'),
  ('In Speech', 'Mild', 'Diagnosed'),
  ('In Movement', 'Severe', 'Diagnosed'),
  ('Mental Illness', 'Moderate', 'Diagnosed')
on conflict do nothing;

-- Languages
insert into language (language_name) values
  ('Hindi'),
  ('English'),
  ('Marathi'),
  ('Malayalam'),
  ('Tamil'),
  ('Telugu'),
  ('Bengali'),
  ('Gujarati'),
  ('Kannada'),
  ('Urdu')
on conflict do nothing;

-- Education Levels
insert into education_level (level_name) values
  ('Illiterate'),
  ('Literate without formal schooling'),
  ('Primary (Class 1-5)'),
  ('Middle (Class 6-8)'),
  ('Matric / Secondary (Class 9-10)'),
  ('Higher Secondary (Class 11-12)'),
  ('Diploma / Certificate'),
  ('Graduate (Bachelor Degree)'),
  ('Post Graduate (Master Degree)'),
  ('Doctorate / Ph.D')
on conflict do nothing;

-- Occupations
insert into occupation (occupation_name, occupation_code) values
  ('Cultivator / Farmer', 'OCC-001'),
  ('Agricultural Labourer', 'OCC-002'),
  ('Government Official / Administrator', 'OCC-003'),
  ('Healthcare / Medical Worker', 'OCC-004'),
  ('Teacher / Professor', 'OCC-005'),
  ('Software / IT Engineer', 'OCC-006'),
  ('Shopkeeper / Retail Trader', 'OCC-007'),
  ('Skilled Craftsman / Artisan', 'OCC-008'),
  ('Driver / Transport Operator', 'OCC-009'),
  ('Student', 'OCC-010'),
  ('Homemaker', 'OCC-011')
on conflict do nothing;

-- Industries
insert into industry (industry_name, industry_code) values
  ('Agriculture, Forestry & Fishing', 'IND-01'),
  ('Manufacturing & Industrial', 'IND-02'),
  ('Construction & Infrastructure', 'IND-03'),
  ('Wholesale & Retail Trade', 'IND-04'),
  ('Transportation & Storage', 'IND-05'),
  ('Information Technology & Telecom', 'IND-06'),
  ('Public Administration & Defence', 'IND-07'),
  ('Education & Training', 'IND-08'),
  ('Human Health & Social Care', 'IND-09')
on conflict do nothing;

-- Seed Enumerators matching existing Supabase Auth Users
insert into enumerator (auth_user_id, employee_code, name, mobile, role, assigned_block_id, status) values
  (
    'c9a22066-588a-4046-86bc-0a3728666273',
    'OFF-2024-0142',
    'Rajesh Kumar Singh',
    '9876543210',
    'District Administrator',
    'bbbb1111-0000-0000-0000-000000000001',
    'ACTIVE'
  ),
  (
    '02399cb2-84f1-4f94-9410-eb797c36dddd',
    'OFF-2024-0089',
    'Priya Nair',
    '9876543211',
    'Enumerator',
    'bbbb3333-0000-0000-0000-000000000001',
    'ACTIVE'
  )
on conflict (employee_code) do update
set auth_user_id = excluded.auth_user_id;
