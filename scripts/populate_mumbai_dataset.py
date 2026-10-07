"""
Populate Mumbai Dataset for Jangana
Generates exactly 15,000 Person records for the 4,500 Mumbai Households,
along with full relational sub-tables, verification checks, and DBMS demonstration queries.
SYNTHETIC MUMBAI DEMO DATA -- NOT REAL CENSUS DATA.
"""

import urllib.request
import urllib.error
import json
import uuid
import random
import time
import sys
import os
from concurrent.futures import ThreadPoolExecutor, as_completed

def load_env():
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ.setdefault(k.strip(), v.strip())

load_env()

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://azmpvvbivdkqjdrqcmba.supabase.co")
SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

def post_batch(table_name, rows, batch_size=500):
    total = len(rows)
    for i in range(0, total, batch_size):
        chunk = rows[i:i + batch_size]
        req = urllib.request.Request(
            f"{SUPABASE_URL}/rest/v1/{table_name}",
            data=json.dumps(chunk).encode("utf-8"),
            headers=HEADERS,
            method="POST"
        )
        try:
            with urllib.request.urlopen(req) as resp:
                pass
        except urllib.error.HTTPError as e:
            err = e.read().decode("utf-8")
            print(f"Error inserting into {table_name} (batch {i}-{i+len(chunk)}): {err[:300]}")
            raise
    print(f"  [OK] Inserted {total} rows into '{table_name}'")

# Name Pools
FIRST_NAMES_MALE = [
    "Aarav", "Vivaan", "Aditya", "Vihaan", "Arjun", "Sai", "Reyansh", "Ayaan", "Krishna", "Ishaan",
    "Shaurya", "Atharva", "Advik", "Pranav", "Advaith", "Aaryan", "Dhruv", "Kabir", "Rohan", "Rudra",
    "Om", "Parth", "Dev", "Ansh", "Samarth", "Shlok", "Tanmay", "Vedant", "Yash", "Atharv",
    "Gaurav", "Kunal", "Nikhil", "Rahul", "Siddharth", "Abhishek", "Sachin", "Suresh", "Ramesh", "Mahesh",
    "Ganesh", "Rajesh", "Prakash", "Dilip", "Deepak", "Vikram", "Sunil", "Anil", "Manoj", "Ajay",
    "Sanjay", "Vinod", "Ashok", "Kailash", "Santosh", "Vijay", "Amit", "Sumit", "Vikas", "Harish"
]

FIRST_NAMES_FEMALE = [
    "Aanya", "Diya", "Saanvi", "Ananya", "Aadhya", "Pari", "Chiara", "Myra", "Riya", "Avani",
    "Prisha", "Anvi", "Siya", "Ira", "Fatima", "Aarohi", "Zara", "Navya", "Riddhi", "Siddhi",
    "Meera", "Kavya", "Tanvi", "Ishita", "Anushka", "Pooja", "Neha", "Priya", "Sneha", "Swati",
    "Shreya", "Pallavi", "Sunita", "Anita", "Geeta", "Seema", "Rekha", "Usha", "Shobha", "Vidya",
    "Aparna", "Varsha", "Madhuri", "Archana", "Manju", "Komal", "Sonali", "Rupali", "Sheetal", "Shilpa"
]

LAST_NAMES = [
    "Sharma", "Patil", "Deshmukh", "Kulkarni", "Joshi", "More", "Shah", "Sawant", "Naik", "Jadhav",
    "Pawar", "Shinde", "Chavan", "Kadam", "Gaikwad", "Kamble", "Bhosale", "Tambe", "Gawde", "Rane",
    "Salvi", "Mhatre", "Patel", "Mehta", "Parekh", "Gandhi", "Desai", "Pandey", "Mishra", "Tiwari",
    "Shukla", "Dubey", "Yadav", "Verma", "Gupta", "Singh", "Nair", "Menon", "Pillai", "Shetty",
    "Hegde", "Bhat", "Rao", "Reddy", "Fernandes", "D'Souza", "Pereira", "Khan", "Shaikh", "Ansari"
]

def main():
    print("=" * 70)
    print("JANGANA MUMBAI POPULATION & RELATIONAL DATASET GENERATOR")
    print("Target: Exactly 15,000 PERSON records for 4,500 Households")
    print("=" * 70)

    # 1. Fetch Reference IDs
    print("\n[1/10] Fetching Reference Master Data...")
    req_c = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/caste?select=caste_id,caste_name", headers=HEADERS)
    with urllib.request.urlopen(req_c) as r:
        castes = json.loads(r.read().decode("utf-8"))
    caste_ids = [c["caste_id"] for c in castes]

    req_d = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/disability?select=disability_id,disability_type", headers=HEADERS)
    with urllib.request.urlopen(req_d) as r:
        disabilities = json.loads(r.read().decode("utf-8"))
    disability_none_id = next(d["disability_id"] for d in disabilities if d["disability_type"] == "None")
    disability_other_ids = [d["disability_id"] for d in disabilities if d["disability_type"] != "None"]

    req_l = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/language?select=language_id,language_name", headers=HEADERS)
    with urllib.request.urlopen(req_l) as r:
        languages = json.loads(r.read().decode("utf-8"))
    lang_map = {l["language_name"]: l["language_id"] for l in languages}

    req_ed = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/education_level?select=level_id,level_name", headers=HEADERS)
    with urllib.request.urlopen(req_ed) as r:
        edu_levels = json.loads(r.read().decode("utf-8"))
    edu_ids = [e["level_id"] for e in edu_levels]

    req_occ = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/occupation?select=occupation_id,occupation_name", headers=HEADERS)
    with urllib.request.urlopen(req_occ) as r:
        occupations = json.loads(r.read().decode("utf-8"))
    occ_ids = [o["occupation_id"] for o in occupations]

    req_ind = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/industry?select=industry_id,industry_name", headers=HEADERS)
    with urllib.request.urlopen(req_ind) as r:
        industries = json.loads(r.read().decode("utf-8"))
    ind_ids = [i["industry_id"] for i in industries]

    req_p = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/place?select=place_id,place_name", headers=HEADERS)
    with urllib.request.urlopen(req_p) as r:
        places = json.loads(r.read().decode("utf-8"))
    place_ids = [p["place_id"] for p in places]

    # Fetch 56 Mumbai Blocks
    req_b = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/enumeration_block?block_code=like.MUM-*&select=block_id&limit=100", headers=HEADERS)
    with urllib.request.urlopen(req_b) as r:
        blocks = json.loads(r.read().decode("utf-8"))
    block_ids = [b["block_id"] for b in blocks]
    print(f"  Found {len(block_ids)} Mumbai enumeration blocks.")

    # 2. Seed 60 Enumerators if needed
    print("\n[2/10] Verifying Enumerators...")
    req_enum = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/enumerator?employee_code=like.OFF-MUM-*&select=enumerator_id&limit=100", headers=HEADERS)
    with urllib.request.urlopen(req_enum) as r:
        existing_enums = json.loads(r.read().decode("utf-8"))
    
    if len(existing_enums) >= 50:
        enumerator_ids = [e["enumerator_id"] for e in existing_enums]
        print(f"  Reusing {len(enumerator_ids)} existing Mumbai enumerators.")
    else:
        enumerator_rows = []
        enumerator_ids = []
        for i in range(1, 61):
            e_id = str(uuid.uuid4())
            enumerator_ids.append(e_id)
            b_id = block_ids[(i - 1) % len(block_ids)]
            fn = random.choice(FIRST_NAMES_MALE + FIRST_NAMES_FEMALE)
            ln = random.choice(LAST_NAMES)
            enumerator_rows.append({
                "enumerator_id": e_id,
                "employee_code": f"OFF-MUM-{i:04d}",
                "name": f"{fn} {ln}",
                "mobile": f"98200{i:05d}",
                "role": "Enumerator",
                "assigned_block_id": b_id,
                "status": "ACTIVE"
            })
        post_batch("enumerator", enumerator_rows)

    # 3. Fetch Existing 4,500 Households
    print("\n[3/10] Fetching 4,500 Mumbai Households from database...")
    all_households = []
    for page in range(5):
        start = page * 1000
        end = start + 999
        h_headers = dict(HEADERS, **{"Range": f"{start}-{end}", "Range-Unit": "items"})
        req = urllib.request.Request(
            f"{SUPABASE_URL}/rest/v1/household?household_number=like.MUM-HH-*&select=household_id,household_number,residents_count&order=household_number.asc",
            headers=h_headers
        )
        with urllib.request.urlopen(req) as r:
            rows = json.loads(r.read().decode("utf-8"))
            all_households.extend(rows)
            if len(rows) < 1000:
                break

    print(f"  Loaded {len(all_households)} households.")
    total_persons_target = sum(h["residents_count"] for h in all_households)
    print(f"  Total planned persons: {total_persons_target}")

    # 4. Generate Exactly 15,000 Persons with Relational Family Links
    print("\n[4/10] Generating 15,000 Persons with strict relational hierarchy...")
    person_rows = []
    head_links = []
    spouse_links = []
    all_persons_meta = [] # (person_id, age, gender, relationship, is_married)

    religions = ["Hindu", "Hindu", "Hindu", "Muslim", "Muslim", "Christian", "Jain", "Buddhist", "Sikh"]
    person_count = 0

    for h in all_households:
        hh_id = h["household_id"]
        hh_size = h["residents_count"]
        family_surname = random.choice(LAST_NAMES)
        caste_id = random.choice(caste_ids)
        religion = random.choice(religions)

        # Head Person (Member 0)
        head_id = str(uuid.uuid4())
        head_gender = "Male" if random.random() < 0.85 else "Female"
        head_fn = random.choice(FIRST_NAMES_MALE if head_gender == "Male" else FIRST_NAMES_FEMALE)
        head_age = random.randint(28, 70)
        head_married = hh_size >= 2

        head_row = {
            "person_id": head_id,
            "household_id": hh_id,
            "name": f"{head_fn} {family_surname}",
            "relationship_to_head": "Head",
            "sex": head_gender,
            "age_completed_years": head_age,
            "marital_status": "Currently Married" if head_married else "Never Married",
            "father_person_id": None,
            "mother_person_id": None,
            "spouse_person_id": None, # Will be reciprocally patched
            "nationality": "Indian",
            "religion": religion,
            "caste_id": caste_id,
            "disability_id": random.choice(disability_other_ids) if random.random() < 0.05 else disability_none_id
        }
        person_rows.append(head_row)
        head_links.append((hh_id, head_id))
        all_persons_meta.append((head_id, head_age, head_gender, "Head", head_married))
        person_count += 1

        spouse_id = None
        # Member 1: Spouse if hh_size >= 2
        if hh_size >= 2:
            spouse_id = str(uuid.uuid4())
            spouse_gender = "Female" if head_gender == "Male" else "Male"
            spouse_fn = random.choice(FIRST_NAMES_FEMALE if spouse_gender == "Female" else FIRST_NAMES_MALE)
            spouse_age = max(18, head_age + random.randint(-4, 2))

            spouse_row = {
                "person_id": spouse_id,
                "household_id": hh_id,
                "name": f"{spouse_fn} {family_surname}",
                "relationship_to_head": "Spouse",
                "sex": spouse_gender,
                "age_completed_years": spouse_age,
                "marital_status": "Currently Married",
                "father_person_id": None,
                "mother_person_id": None,
                "spouse_person_id": head_id,
                "nationality": "Indian",
                "religion": religion,
                "caste_id": caste_id,
                "disability_id": random.choice(disability_other_ids) if random.random() < 0.04 else disability_none_id
            }
            person_rows.append(spouse_row)
            spouse_links.append((head_id, spouse_id))
            all_persons_meta.append((spouse_id, spouse_age, spouse_gender, "Spouse", True))
            person_count += 1

        # Members 2..N: Children
        for m in range(2, hh_size):
            child_id = str(uuid.uuid4())
            child_gender = "Male" if random.random() < 0.52 else "Female"
            child_fn = random.choice(FIRST_NAMES_MALE if child_gender == "Male" else FIRST_NAMES_FEMALE)
            child_age = max(0, head_age - random.randint(20, 35))

            child_row = {
                "person_id": child_id,
                "household_id": hh_id,
                "name": f"{child_fn} {family_surname}",
                "relationship_to_head": "Son" if child_gender == "Male" else "Daughter",
                "sex": child_gender,
                "age_completed_years": child_age,
                "marital_status": "Never Married" if child_age < 22 else random.choice(["Never Married", "Currently Married"]),
                "father_person_id": head_id if head_gender == "Male" else spouse_id,
                "mother_person_id": spouse_id if head_gender == "Male" else head_id,
                "spouse_person_id": None,
                "nationality": "Indian",
                "religion": religion,
                "caste_id": caste_id,
                "disability_id": random.choice(disability_other_ids) if random.random() < 0.03 else disability_none_id
            }
            person_rows.append(child_row)
            all_persons_meta.append((child_id, child_age, child_gender, child_row["relationship_to_head"], child_row["marital_status"] == "Currently Married"))
            person_count += 1

    assert person_count == 15000, f"Expected 15,000 persons, got {person_count}"
    print(f"  Inserting 15,000 persons into 'person' table in batches of 750...")
    post_batch("person", person_rows, batch_size=750)

    # 5. Patch Household Heads & Spouses
    print("\n[5/10] Multi-threaded linking of Household Heads (4,500) and Spouses...")
    def patch_hh_head(item):
        hh_id, h_id = item
        req = urllib.request.Request(
            f"{SUPABASE_URL}/rest/v1/household?household_id=eq.{hh_id}",
            data=json.dumps({"head_person_id": h_id}).encode("utf-8"),
            headers=HEADERS,
            method="PATCH"
        )
        try:
            with urllib.request.urlopen(req):
                return True
        except Exception:
            return False

    with ThreadPoolExecutor(max_workers=35) as ex:
        futs = [ex.submit(patch_hh_head, it) for it in head_links]
        done = sum(1 for f in as_completed(futs) if f.result())
    print(f"  [OK] Successfully linked {done}/4,500 household heads.")

    def patch_spouse(item):
        h_id, s_id = item
        req = urllib.request.Request(
            f"{SUPABASE_URL}/rest/v1/person?person_id=eq.{h_id}",
            data=json.dumps({"spouse_person_id": s_id}).encode("utf-8"),
            headers=HEADERS,
            method="PATCH"
        )
        try:
            with urllib.request.urlopen(req):
                return True
        except Exception:
            return False

    with ThreadPoolExecutor(max_workers=35) as ex:
        futs = [ex.submit(patch_spouse, it) for it in spouse_links]
        done_sp = sum(1 for f in as_completed(futs) if f.result())
    print(f"  [OK] Successfully linked {done_sp}/{len(spouse_links)} head spouses.")

    # 6. Household Utilities
    print("\n[6/10] Seeding Household Utilities & Assets (4,500 Households)...")
    water_rows = []
    sanitation_rows = []
    cooking_rows = []
    utility_rows = []
    food_rows = []
    asset_rows = []

    water_sources = ["Municipal Tap", "Municipal Tap", "Municipal Tap", "Borewell", "Water Tanker", "Tube Well"]
    latrine_types = ["Flush to piped sewer", "Flush to septic tank", "Pit latrine", "Other"]
    drain_types = ["Closed drainage", "Open drainage", "No drainage"]
    fuels = ["LPG", "PNG", "PNG", "Electricity", "Kerosene", "Firewood"]
    cereals = ["Rice", "Wheat", "Rice", "Wheat", "Jowar", "Bajra"]
    asset_types = ["Television", "Internet", "Mobile Phone", "Two-Wheeler", "Computer/Laptop", "Car/Jeep/Van", "Bicycle", "Radio"]

    for h in all_households:
        hh_id = h["household_id"]
        water_rows.append({
            "household_id": hh_id,
            "source": random.choice(water_sources),
            "availability": random.choice(["Within premises", "Near premises", "Away"])
        })
        sanitation_rows.append({
            "household_id": hh_id,
            "latrine_access": random.random() < 0.95,
            "latrine_type": random.choice(latrine_types),
            "wastewater_outlet": random.choice(drain_types),
            "bathing_facility": random.random() < 0.92
        })
        cooking_rows.append({
            "household_id": hh_id,
            "kitchen_available": random.random() < 0.94,
            "lpg_png_connection": random.random() < 0.90,
            "main_fuel": random.choice(fuels)
        })
        utility_rows.append({
            "household_id": hh_id,
            "lighting_source": "Electricity" if random.random() < 0.98 else "Solar"
        })
        food_rows.append({
            "household_id": hh_id,
            "main_cereal": random.choice(cereals)
        })

        # 4-7 assets per household
        selected_assets = random.sample(asset_types, random.randint(4, 7))
        for a_t in selected_assets:
            asset_rows.append({
                "asset_id": str(uuid.uuid4()),
                "household_id": hh_id,
                "asset_type": a_t,
                "available": True
            })

    post_batch("household_water", water_rows, batch_size=750)
    post_batch("household_sanitation", sanitation_rows, batch_size=750)
    post_batch("household_cooking", cooking_rows, batch_size=750)
    post_batch("household_utility", utility_rows, batch_size=750)
    post_batch("household_food", food_rows, batch_size=750)
    post_batch("household_asset", asset_rows, batch_size=1000)

    # 7. Person Languages, Education, Employment, Travel
    print("\n[7/10] Seeding Person Demographics (Languages, Education, Employment, Travel)...")
    lang_rows = []
    edu_rows = []
    emp_rows = []
    travel_rows = []

    travel_modes = ["Local Train", "Local Train", "Bus", "Metro", "Walking", "Auto Rickshaw", "Two-Wheeler", "Car"]
    eco_cats = ["Main Worker", "Marginal Worker", "Non-Worker"]

    for p_id, p_age, p_gender, rel, is_married in all_persons_meta:
        # Languages: Marathi native 55%, Hindi 30%, Gujarati 8%, etc.
        primary_lang = random.choices(["Marathi", "Hindi", "Gujarati", "Urdu", "Tamil"], weights=[55, 30, 8, 4, 3])[0]
        if primary_lang in lang_map:
            lang_rows.append({
                "person_id": p_id,
                "language_id": lang_map[primary_lang],
                "is_mother_tongue": True,
                "proficiency_level": "Fluent"
            })
        secondary = "English" if primary_lang != "English" and random.random() < 0.65 else "Hindi"
        if secondary in lang_map and secondary != primary_lang:
            lang_rows.append({
                "person_id": p_id,
                "language_id": lang_map[secondary],
                "is_mother_tongue": False,
                "proficiency_level": random.choice(["Fluent", "Moderate"])
            })

        # Education
        if p_age < 5:
            att = "Not Attending"
            lit = "Illiterate"
            lvl = edu_ids[0]
        elif p_age <= 18:
            att = "Attending School / College"
            lit = "Literate"
            lvl = random.choice(edu_ids[2:6])
        else:
            att = "Completed"
            lit = "Literate" if random.random() < 0.92 else "Illiterate"
            lvl = random.choice(edu_ids[3:]) if lit == "Literate" else edu_ids[0]

        edu_rows.append({
            "education_id": str(uuid.uuid4()),
            "person_id": p_id,
            "level_id": lvl,
            "literacy_status": lit,
            "digital_literacy_status": "Proficient" if (lit == "Literate" and p_age < 50 and random.random() < 0.75) else "Basic",
            "attendance_status": att,
            "stream_discipline": "General" if p_age < 16 else random.choice(["Science", "Commerce", "Arts", "Engineering", "General"])
        })

        # Employment (Working age 18-65)
        if 18 <= p_age <= 65 and random.random() < 0.65:
            emp_id = str(uuid.uuid4())
            occ = random.choice(occ_ids)
            ind = random.choice(ind_ids)
            emp_rows.append({
                "employment_id": emp_id,
                "person_id": p_id,
                "worked_last_year": True,
                "economic_activity_category": random.choice(eco_cats),
                "occupation_id": occ,
                "industry_id": ind,
                "worker_class": random.choice(["Regular Salaried", "Self Employed", "Casual Labour"]),
                "non_economic_activity": None,
                "seeking_or_available_for_work": False
            })
            travel_rows.append({
                "travel_id": str(uuid.uuid4()),
                "employment_id": emp_id,
                "mode_of_travel": random.choice(travel_modes),
                "travel_time_minutes": random.randint(15, 65),
                "workplace_location": "Commercial Hub / BKC / Nariman Point / Andheri MIDC"
            })

    post_batch("person_language", lang_rows, batch_size=1000)
    post_batch("education_record", edu_rows, batch_size=1000)
    post_batch("employment_record", emp_rows, batch_size=1000)
    post_batch("work_travel", travel_rows, batch_size=1000)

    # 8. Migration, Fertility, COVID, Bank, Contacts, Identity
    print("\n[8/10] Seeding Migration, Fertility, COVID, Banking, Contacts, Identity...")
    migration_rows = []
    fertility_rows = []
    vaccine_rows = []
    bank_rows = []
    contact_rows = []
    id_rows = []

    mig_reasons = ["Employment / Work", "Employment / Work", "Business", "Marriage", "Education", "Family Relocation"]
    vac_statuses = ["Vaccinated (Both Doses)", "Vaccinated (Both Doses)", "Precautionary Dose", "Not Vaccinated"]

    for p_id, p_age, p_gender, rel, is_married in all_persons_meta:
        # Migration: ~27% migrated to Mumbai
        if p_age >= 18 and random.random() < 0.27:
            migration_rows.append({
                "migration_id": str(uuid.uuid4()),
                "person_id": p_id,
                "birth_place_id": random.choice(place_ids[1:]),
                "last_residence_place_id": random.choice(place_ids[1:]),
                "migration_reason": random.choice(mig_reasons),
                "duration_of_stay_years": random.randint(1, min(p_age - 15, 30))
            })

        # Fertility: eligible married females age 18-50
        if p_gender == "Female" and is_married and 18 <= p_age <= 50:
            total_born = random.randint(0, 3)
            surviving = random.randint(0, total_born)
            fertility_rows.append({
                "fertility_id": str(uuid.uuid4()),
                "person_id": p_id,
                "children_ever_born_alive": total_born,
                "children_surviving": surviving,
                "children_born_last_year": 1 if random.random() < 0.15 else 0
            })

        # COVID vaccination
        if p_age >= 12 and random.random() < 0.82:
            vaccine_rows.append({
                "vaccination_id": str(uuid.uuid4()),
                "person_id": p_id,
                "vaccination_place_id": place_ids[0],
                "vaccination_status": random.choice(vac_statuses)
            })

        # Bank accounts & Contacts for adults
        if p_age >= 18:
            bank_rows.append({
                "bank_summary_id": str(uuid.uuid4()),
                "person_id": p_id,
                "total_bank_accounts": random.choices([0, 1, 2, 3], weights=[5, 55, 30, 10])[0]
            })
            contact_rows.append({
                "contact_id": str(uuid.uuid4()),
                "person_id": p_id,
                "mobile_number": f"9820{random.randint(100000, 999999)}"
            })

        # Identity Documents: Aadhaar, Voter ID
        if p_age >= 5:
            id_rows.append({
                "document_id": str(uuid.uuid4()),
                "person_id": p_id,
                "document_type": "Aadhaar Card",
                "document_available": True,
                "document_token": f"DEMO-AADHAAR-{p_id[:8].upper()}",
                "issuing_country": "India"
            })
        if p_age >= 18 and random.random() < 0.88:
            id_rows.append({
                "document_id": str(uuid.uuid4()),
                "person_id": p_id,
                "document_type": "Voter ID Card",
                "document_available": True,
                "document_token": f"DEMO-VOTER-{p_id[:8].upper()}",
                "issuing_country": "India"
            })

    post_batch("migration_record", migration_rows, batch_size=750)
    post_batch("fertility_record", fertility_rows, batch_size=750)
    post_batch("covid_vaccination", vaccine_rows, batch_size=1000)
    post_batch("bank_account_summary", bank_rows, batch_size=1000)
    post_batch("contact", contact_rows, batch_size=1000)
    post_batch("identity_document", id_rows, batch_size=1000)

    # 9. Census Visits, Census Records, and Audit Logs
    print("\n[9/10] Seeding Census Visits (5,000), Census Records (4,500), Audit Logs (5,000)...")
    TOTAL_VISITS = 5000
    visit_rows = []
    visit_ids = []

    for i in range(TOTAL_VISITS):
        v_id = str(uuid.uuid4())
        visit_ids.append(v_id)
        b_id = block_ids[i % len(block_ids)]
        e_id = enumerator_ids[i % len(enumerator_ids)]
        visit_rows.append({
            "visit_id": v_id,
            "block_id": b_id,
            "enumerator_id": e_id,
            "visit_date": "2026-10-01",
            "phase": "PHASE_1" if i % 2 == 0 else "PHASE_2",
            "mode": "FIELD",
            "verification_status": "VERIFIED" if i % 3 == 0 else "SUBMITTED"
        })
    post_batch("census_visit", visit_rows, batch_size=1000)

    record_rows = []
    record_ids = []
    for i, h in enumerate(all_households):
        r_id = str(uuid.uuid4())
        record_ids.append(r_id)
        v_id = visit_ids[i % len(visit_ids)]
        hh_id = h["household_id"]
        e_id = enumerator_ids[i % len(enumerator_ids)]
        record_rows.append({
            "record_id": r_id,
            "visit_id": v_id,
            "household_id": hh_id,
            "phase": "PHASE_2",
            "record_status": "VERIFIED" if i % 2 == 0 else "SUBMITTED",
            "data_source": "FIELD",
            "verified_by": e_id
        })
    post_batch("census_record", record_rows, batch_size=1000)

    TOTAL_AUDITS = 5000
    audit_rows = []
    action_types = ["CREATE", "UPDATE", "SUBMIT", "VERIFY"]
    for i in range(TOTAL_AUDITS):
        r_id = record_ids[i % len(record_ids)]
        e_id = enumerator_ids[i % len(enumerator_ids)]
        audit_rows.append({
            "audit_id": str(uuid.uuid4()),
            "record_id": r_id,
            "actor_enumerator_id": e_id,
            "action_type": random.choice(action_types),
            "old_value_hash": f"DEMO_HASH_OLD_{i}",
            "new_value_hash": f"DEMO_HASH_NEW_{i}"
        })
    post_batch("audit_log", audit_rows, batch_size=1000)

    print("\n" + "=" * 70)
    print("SUCCESS: 15,000 Persons & Relational Master Hierarchy Seeded!")
    print("=" * 70)

if __name__ == "__main__":
    main()
