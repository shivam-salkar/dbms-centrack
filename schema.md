# Jangana -- City-Level Census Database Schema

## Overview

PostgreSQL/Supabase schema for the city-level Jangana DBMS mini-project.
The design normalizes the selected 36 census questions across
administrative, housing, household, person, education, employment,
migration, health, document, submission, and audit tables.

## Core SQL

``` sql
create extension if not exists pgcrypto;

create table city (
  city_id uuid primary key default gen_random_uuid(),
  city_name varchar(150) not null,
  state_name varchar(100) not null,
  census_year integer not null,
  unique (city_name, state_name, census_year)
);

create table ward (
  ward_id uuid primary key default gen_random_uuid(),
  city_id uuid not null references city(city_id) on delete cascade,
  ward_number integer not null,
  ward_name varchar(150),
  unique (city_id, ward_number)
);

create table enumeration_block (
  block_id uuid primary key default gen_random_uuid(),
  ward_id uuid not null references ward(ward_id) on delete cascade,
  block_code varchar(50) not null unique
);

create table address (
  address_id uuid primary key default gen_random_uuid(),
  block_id uuid not null references enumeration_block(block_id),
  house_number varchar(50),
  street_name varchar(200),
  locality varchar(200),
  pin_code varchar(6)
);

create table enumerator (
  enumerator_id uuid primary key default gen_random_uuid(),
  employee_code varchar(50) not null unique,
  name varchar(150) not null,
  mobile varchar(15),
  assigned_block_id uuid references enumeration_block(block_id) on delete set null,
  status varchar(30) not null default 'ACTIVE'
);

create table census_visit (
  visit_id uuid primary key default gen_random_uuid(),
  block_id uuid not null references enumeration_block(block_id),
  enumerator_id uuid not null references enumerator(enumerator_id),
  visit_date date not null default current_date,
  phase varchar(20) not null check (phase in ('PHASE_1','PHASE_2')),
  mode varchar(30) not null default 'FIELD',
  verification_status varchar(30) not null default 'DRAFT'
);

create table building (
  building_id uuid primary key default gen_random_uuid(),
  address_id uuid not null references address(address_id),
  building_number varchar(50) not null,
  census_house_number varchar(50) not null,
  floor_material varchar(100),
  wall_material varchar(100),
  roof_material varchar(100),
  house_use varchar(100),
  condition varchar(100),
  ownership_status varchar(100),
  dwelling_rooms integer check (dwelling_rooms is null or dwelling_rooms >= 0),
  unique (address_id, census_house_number)
);

create table household (
  household_id uuid primary key default gen_random_uuid(),
  building_id uuid not null references building(building_id) on delete cascade,
  household_number varchar(50) not null,
  residents_count integer not null default 0 check (residents_count >= 0),
  head_category varchar(30),
  married_couples_count integer check (married_couples_count is null or married_couples_count >= 0),
  mobile_contact varchar(15),
  unique (building_id, household_number)
);

create table household_water (
  household_id uuid primary key references household(household_id) on delete cascade,
  source varchar(150) not null,
  availability varchar(100)
);

create table household_sanitation (
  household_id uuid primary key references household(household_id) on delete cascade,
  latrine_access boolean,
  latrine_type varchar(100),
  wastewater_outlet varchar(150),
  bathing_facility boolean
);

create table household_cooking (
  household_id uuid primary key references household(household_id) on delete cascade,
  kitchen_available boolean,
  lpg_png_connection boolean,
  main_fuel varchar(100)
);

create table household_utility (
  household_id uuid primary key references household(household_id) on delete cascade,
  lighting_source varchar(150)
);

create table household_food (
  household_id uuid primary key references household(household_id) on delete cascade,
  main_cereal varchar(100)
);

create table household_asset (
  asset_id uuid primary key default gen_random_uuid(),
  household_id uuid not null references household(household_id) on delete cascade,
  asset_type varchar(100) not null,
  available boolean not null default false,
  unique (household_id, asset_type)
);

create table person (
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
  nationality varchar(100),
  religion varchar(100),
  caste_id uuid,
  father_person_id uuid references person(person_id) on delete set null,
  mother_person_id uuid references person(person_id) on delete set null,
  disability_id uuid
);

create table caste (
  caste_id uuid primary key default gen_random_uuid(),
  caste_name varchar(150) not null,
  category_type varchar(50) not null,
  unique (caste_name, category_type)
);

create table disability (
  disability_id uuid primary key default gen_random_uuid(),
  disability_type varchar(150) not null,
  severity varchar(50),
  status varchar(50)
);

alter table person add constraint fk_person_caste
  foreign key (caste_id) references caste(caste_id) on delete set null;

alter table person add constraint fk_person_disability
  foreign key (disability_id) references disability(disability_id) on delete set null;

create table language (
  language_id uuid primary key default gen_random_uuid(),
  language_name varchar(100) not null unique
);

create table person_language (
  person_id uuid not null references person(person_id) on delete cascade,
  language_id uuid not null references language(language_id) on delete restrict,
  is_mother_tongue boolean not null default false,
  proficiency_level varchar(50),
  primary key (person_id, language_id)
);

create table education_level (
  level_id uuid primary key default gen_random_uuid(),
  level_name varchar(150) not null unique
);

create table education_record (
  education_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references person(person_id) on delete cascade,
  level_id uuid references education_level(level_id) on delete set null,
  literacy_status varchar(50),
  digital_literacy_status varchar(50),
  attendance_status varchar(100),
  stream_discipline varchar(150)
);

create table occupation (
  occupation_id uuid primary key default gen_random_uuid(),
  occupation_name varchar(200) not null,
  occupation_code varchar(50) not null unique
);

create table industry (
  industry_id uuid primary key default gen_random_uuid(),
  industry_name varchar(200) not null,
  industry_code varchar(50) not null unique
);

create table employment_record (
  employment_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references person(person_id) on delete cascade,
  worked_last_year boolean,
  economic_activity_category varchar(100),
  occupation_id uuid references occupation(occupation_id) on delete set null,
  industry_id uuid references industry(industry_id) on delete set null,
  worker_class varchar(100),
  non_economic_activity varchar(150),
  seeking_or_available_for_work boolean
);

create table work_travel (
  travel_id uuid primary key default gen_random_uuid(),
  employment_id uuid not null unique references employment_record(employment_id) on delete cascade,
  mode_of_travel varchar(150),
  travel_time_minutes integer check (travel_time_minutes is null or travel_time_minutes >= 0),
  workplace_location varchar(250)
);

create table place (
  place_id uuid primary key default gen_random_uuid(),
  place_name varchar(200) not null,
  place_type varchar(100),
  district varchar(150),
  state varchar(150),
  country varchar(150) not null default 'India'
);

create table migration_record (
  migration_id uuid primary key default gen_random_uuid(),
  person_id uuid not null unique references person(person_id) on delete cascade,
  birth_place_id uuid references place(place_id) on delete set null,
  last_residence_place_id uuid references place(place_id) on delete set null,
  migration_reason varchar(200),
  duration_of_stay_years numeric(5,2) check (duration_of_stay_years is null or duration_of_stay_years >= 0),
  permanent_address_id uuid references address(address_id) on delete set null
);

create table fertility_record (
  fertility_id uuid primary key default gen_random_uuid(),
  person_id uuid not null unique references person(person_id) on delete cascade,
  children_surviving integer check (children_surviving is null or children_surviving >= 0),
  children_ever_born_alive integer check (children_ever_born_alive is null or children_ever_born_alive >= 0),
  children_born_last_year integer check (children_born_last_year is null or children_born_last_year >= 0)
);

create table covid_vaccination (
  vaccination_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references person(person_id) on delete cascade,
  vaccination_place_id uuid references place(place_id) on delete set null,
  vaccination_status varchar(100)
);

create table bank_account_summary (
  bank_summary_id uuid primary key default gen_random_uuid(),
  person_id uuid not null unique references person(person_id) on delete cascade,
  total_bank_accounts integer not null default 0 check (total_bank_accounts >= 0)
);

create table contact (
  contact_id uuid primary key default gen_random_uuid(),
  person_id uuid not null unique references person(person_id) on delete cascade,
  mobile_number varchar(15) not null
);

create table identity_document (
  document_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references person(person_id) on delete cascade,
  document_type varchar(50) not null,
  document_available boolean not null default false,
  document_token text,
  issuing_country varchar(100) default 'India',
  verified_at timestamptz,
  unique (person_id, document_type)
);

create table census_record (
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

create table audit_log (
  audit_id uuid primary key default gen_random_uuid(),
  record_id uuid not null references census_record(record_id) on delete cascade,
  actor_enumerator_id uuid references enumerator(enumerator_id) on delete set null,
  action_type varchar(100) not null,
  action_timestamp timestamptz not null default now(),
  old_value_hash text,
  new_value_hash text
);

-- Circular household-head relationship.
alter table household add column head_person_id uuid;

alter table household add constraint fk_household_head_person
  foreign key (head_person_id) references person(person_id) on delete set null;

create index idx_ward_city on ward(city_id);
create index idx_block_ward on enumeration_block(ward_id);
create index idx_address_block on address(block_id);
create index idx_enumerator_block on enumerator(assigned_block_id);
create index idx_visit_block on census_visit(block_id);
create index idx_visit_enumerator on census_visit(enumerator_id);
create index idx_building_address on building(address_id);
create index idx_household_building on household(building_id);
create index idx_person_household on person(household_id);
create index idx_person_caste on person(caste_id);
create index idx_person_disability on person(disability_id);
create index idx_employment_person on employment_record(person_id);
create index idx_migration_birth_place on migration_record(birth_place_id);
create index idx_migration_last_residence on migration_record(last_residence_place_id);
create index idx_census_record_visit on census_record(visit_id);
create index idx_census_record_household on census_record(household_id);
create index idx_audit_record on audit_log(record_id);
```

## Supabase RLS

Enable Row Level Security on application-facing tables:

``` sql
alter table city enable row level security;
alter table ward enable row level security;
alter table enumeration_block enable row level security;
alter table address enable row level security;
alter table enumerator enable row level security;
alter table census_visit enable row level security;
alter table building enable row level security;
alter table household enable row level security;
alter table person enable row level security;
alter table census_record enable row level security;
alter table audit_log enable row level security;
```

For an academic prototype, authenticated users can initially be given
controlled read access:

``` sql
create policy "authenticated users can read census records"
on census_record
for select
to authenticated
using (true);
```

For a real deployment, replace broad policies with role/assignment-based
policies.

## Supabase Auth

Authentication can remain separate from the census domain model.

Optional integration:

``` sql
alter table enumerator
add column auth_user_id uuid references auth.users(id) on delete set null;

create unique index uq_enumerator_auth_user
on enumerator(auth_user_id)
where auth_user_id is not null;
```

## 36-Question Mapping

  Questions   Tables
  ----------- ----------------------------------------
  Q01--Q04    BUILDING
  Q05         HOUSEHOLD
  Q06         HOUSEHOLD, PERSON, CASTE
  Q07         BUILDING
  Q08         HOUSEHOLD
  Q09         HOUSEHOLD_WATER
  Q10         HOUSEHOLD_UTILITY
  Q11         HOUSEHOLD_SANITATION
  Q12         HOUSEHOLD_COOKING
  Q13         HOUSEHOLD_ASSET
  Q14         HOUSEHOLD_FOOD
  Q15         HOUSEHOLD
  Q16--Q18    PERSON
  Q19         PERSON, CASTE
  Q20         PERSON self-reference
  Q21         DISABILITY
  Q22         LANGUAGE, PERSON_LANGUAGE
  Q23--Q24    EDUCATION_RECORD, EDUCATION_LEVEL
  Q25--Q27    EMPLOYMENT_RECORD
  Q26         OCCUPATION, INDUSTRY
  Q28         WORK_TRAVEL
  Q29--Q30    MIGRATION_RECORD, PLACE, ADDRESS
  Q31         FERTILITY_RECORD
  Q32         COVID_VACCINATION, PLACE
  Q33         BANK_ACCOUNT_SUMMARY
  Q34         CONTACT
  Q35         IDENTITY_DOCUMENT
  Q36         CENSUS_VISIT, CENSUS_RECORD, AUDIT_LOG

## Important Security Rule

Do not store raw Aadhaar, Passport, Voter ID, Driving Licence, or
similar sensitive document numbers in this academic database.
`document_token` should contain only a tokenized/encrypted reference if
the prototype genuinely needs one.

## DBMS Concepts Demonstrated

-   Primary keys
-   Foreign keys
-   Candidate/unique keys
-   Composite primary key
-   1:1 relationships
-   1:N relationships
-   M:N relationship using `PERSON_LANGUAGE`
-   Self-referencing relationships
-   Normalization
-   Referential integrity
-   CHECK constraints
-   Indexes
-   Views
-   Triggers/constraint triggers where required
-   Audit logging
-   Supabase Row Level Security
