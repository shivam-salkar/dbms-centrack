"""
Large-Scale Synthetic Mumbai Census Dataset Generator (Jangana)
Target: ~15,000 Person records with consistent relational hierarchy.
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

from concurrent.futures import ThreadPoolExecutor, as_completed

def patch_batch_heads(updates, max_workers=35):
    total = len(updates)
    print(f"  Updating {total} household heads using {max_workers} threads...")

    def patch_single(item):
        hh_id, head_id = item
        req = urllib.request.Request(
            f"{SUPABASE_URL}/rest/v1/household?household_id=eq.{hh_id}",
            data=json.dumps({"head_person_id": head_id}).encode("utf-8"),
            headers=HEADERS,
            method="PATCH"
        )
        try:
            with urllib.request.urlopen(req) as resp:
                return True
        except Exception as e:
            print(f"Error updating head for {hh_id}: {e}")
            return False

    completed = 0
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = [executor.submit(patch_single, u) for u in updates]
        for f in as_completed(futures):
            completed += 1
            if completed % 1000 == 0 or completed == total:
                print(f"    Linked {completed}/{total} heads...")

def patch_batch_spouses(updates, max_workers=35):
    total = len(updates)
    print(f"  Reciprocally linking {total} head spouses using {max_workers} threads...")

    def patch_single(item):
        head_id, spouse_id = item
        req = urllib.request.Request(
            f"{SUPABASE_URL}/rest/v1/person?person_id=eq.{head_id}",
            data=json.dumps({"spouse_person_id": spouse_id}).encode("utf-8"),
            headers=HEADERS,
            method="PATCH"
        )
        try:
            with urllib.request.urlopen(req) as resp:
                return True
        except Exception:
            return False

    completed = 0
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = [executor.submit(patch_single, u) for u in updates]
        for f in as_completed(futures):
            completed += 1
            if completed % 1000 == 0 or completed == total:
                print(f"    Linked {completed}/{total} spouses...")

# Synthetic Name Pools
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

MUMBAI_WARDS = [
    ("Andheri West Demo Ward", 1),
    ("Andheri East Demo Ward", 2),
    ("Bandra West Demo Ward", 3),
    ("Bandra East Demo Ward", 4),
    ("Borivali Demo Ward", 5),
    ("Chembur Demo Ward", 6),
    ("Dadar Demo Ward", 7),
    ("Ghatkopar Demo Ward", 8),
    ("Kurla Demo Ward", 9),
    ("Malad Demo Ward", 10),
    ("Powai Demo Ward", 11),
    ("Worli Demo Ward", 12),
    ("Colaba Demo Ward", 13),
    ("Byculla Demo Ward", 14),
]

SYNTHETIC_PLACES = [
    ("Demo Maharashtra", "State", "Mumbai", "Maharashtra"),
    ("Demo Gujarat", "State", "Ahmedabad", "Gujarat"),
    ("Demo Uttar Pradesh", "State", "Lucknow", "Uttar Pradesh"),
    ("Demo Bihar", "State", "Patna", "Bihar"),
    ("Demo Karnataka", "State", "Bengaluru", "Karnataka"),
    ("Demo Tamil Nadu", "State", "Chennai", "Tamil Nadu"),
    ("Demo West Bengal", "State", "Kolkata", "West Bengal"),
    ("Demo Rajasthan", "State", "Jaipur", "Rajasthan"),
    ("Demo Madhya Pradesh", "State", "Bhopal", "Madhya Pradesh"),
    ("Demo Delhi", "UT", "New Delhi", "Delhi"),
    ("Demo Kerala", "State", "Kochi", "Kerala"),
    ("Demo Andhra Pradesh", "State", "Vijayawada", "Andhra Pradesh"),
    ("Demo Punjab", "State", "Amritsar", "Punjab"),
    ("Demo Goa", "State", "Panaji", "Goa"),
    ("Demo Odisha", "State", "Bhubaneswar", "Odisha"),
]

def clean_previous_demo_data():
    print("\n[0/16] Cleaning up any previous Mumbai demo data...")
    cleanup_calls = [
        ("audit_log", "action_type=in.(CREATE,UPDATE,SUBMIT,VERIFY)"),
        ("census_record", "record_status=in.(VERIFIED,SUBMITTED)"),
        ("census_visit", "verification_status=in.(VERIFIED,SUBMITTED)"),
        ("person", "nationality=eq.Indian"), # Demo persons
        ("household", "household_number=like.MUM-HH-*"),
        ("building", "building_number=like.MUM-BLD-*"),
        ("address", "locality=like.*Demo%20Area*"),
        ("enumerator", "employee_code=like.OFF-MUM-*"),
        ("enumeration_block", "block_code=like.MUM-*"),
        ("ward", "ward_name=like.*Demo%20Ward*"),
    ]
    # First clear head_person_id to break cyclic reference
    try:
        req = urllib.request.Request(
            f"{SUPABASE_URL}/rest/v1/household?household_number=like.MUM-HH-*",
            data=json.dumps({"head_person_id": None}).encode("utf-8"),
            headers=HEADERS,
            method="PATCH"
        )
        urllib.request.urlopen(req)
    except Exception:
        pass

    for tbl, q in cleanup_calls:
        try:
            req = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/{tbl}?{q}", headers=HEADERS, method="DELETE")
            urllib.request.urlopen(req)
        except Exception:
            pass
    print("  [OK] Previous demo records cleaned.")

def main():
    print("=" * 70)
    print("JANGANA MUMBAI LARGE-SCALE MOCK DATASET GENERATOR")
    print("Target: ~15,000 PERSON records with full relational consistency")
    print("=" * 70)

    clean_previous_demo_data()

    # 1. Fetch Reference IDs
    print("\n[1/16] Fetching reference table IDs...")
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

    # 2. City
    print("\n[2/16] Ensuring Mumbai (2027) City record...")
    city_id = "22222222-2222-2222-2222-222222222027"
    city_row = {
        "city_id": city_id,
        "city_name": "Mumbai",
        "state_name": "Maharashtra",
        "census_year": 2027
    }
    # Insert or ignore
    try:
        post_batch("city", [city_row])
    except Exception:
        pass

    # 3. Places
    print("\n[3/16] Seeding synthetic reference places...")
    # Check if demo places already exist
    req_p = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/place?place_name=like.Demo%2A", headers=HEADERS)
    with urllib.request.urlopen(req_p) as r:
        existing_places = json.loads(r.read().decode("utf-8"))

    if existing_places:
        place_ids = [p["place_id"] for p in existing_places]
        print(f"  Reusing {len(place_ids)} existing synthetic places.")
    else:
        place_rows = []
        place_ids = []
        for p_name, p_type, dist, st in SYNTHETIC_PLACES:
            p_id = str(uuid.uuid4())
            place_ids.append(p_id)
            place_rows.append({
                "place_id": p_id,
                "place_name": p_name,
                "place_type": p_type,
                "district": dist,
                "state": st,
                "country": "India"
            })
        post_batch("place", place_rows)

    # 4. Wards & Enumeration Blocks
    print("\n[4/16] Seeding 14 Wards and 56 Enumeration Blocks...")
    ward_rows = []
    block_rows = []
    ward_ids = []
    block_ids = []

    for w_name, w_num in MUMBAI_WARDS:
        w_id = str(uuid.uuid4())
        ward_ids.append(w_id)
        ward_rows.append({
            "ward_id": w_id,
            "city_id": city_id,
            "ward_number": w_num,
            "ward_name": w_name
        })

        # 4 Blocks per ward
        for b_num in range(1, 5):
            b_id = str(uuid.uuid4())
            block_ids.append(b_id)
            b_code = f"MUM-W{w_num:02d}-B{b_num:02d}"
            block_rows.append({
                "block_id": b_id,
                "ward_id": w_id,
                "block_code": b_code
            })

    post_batch("ward", ward_rows)
    post_batch("enumeration_block", block_rows)

    # 5. Enumerators
    print("\n[5/16] Seeding 60 Enumerators...")
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

    # 6. Addresses (3,500)
    print("\n[6/16] Generating 3,500 Addresses...")
    TOTAL_ADDRESSES = 3500
    address_rows = []
    address_ids = []
    streets = [
        "Demo Link Road", "Demo SV Road", "Demo Hill Road", "Demo Western Express Way",
        "Demo LBS Marg", "Demo Station Road", "Demo Marine Drive", "Demo JVLR",
        "Demo Tilak Road", "Demo Ambedkar Marg", "Demo Veer Savarkar Marg", "Demo Coastal Road"
    ]

    for i in range(TOTAL_ADDRESSES):
        a_id = str(uuid.uuid4())
        address_ids.append(a_id)
        b_id = block_ids[i % len(block_ids)]
        w_idx = (i % len(block_ids)) // 4
        locality_base = MUMBAI_WARDS[w_idx][0].replace(" Demo Ward", "")

        address_rows.append({
            "address_id": a_id,
            "block_id": b_id,
            "house_number": f"{random.choice(['A','B','C','D'])}-{random.randint(101, 908)}",
            "street_name": f"{random.choice(streets)} {random.randint(1, 40)}",
            "locality": f"{locality_base} Demo Area",
            "pin_code": f"4000{random.randint(10, 99)}"
        })
    post_batch("address", address_rows, batch_size=700)

    # 7. Buildings (4,200)
    print("\n[7/16] Generating 4,200 Buildings...")
    TOTAL_BUILDINGS = 4200
    building_rows = []
    building_ids = []

    floor_mats = ["Cement", "Mosaic / Floor Tiles", "Marble / Granite", "Ceramic Tiles", "Stone"]
    wall_mats = ["Burnt Brick", "Concrete", "Stone", "G.I. / Metal Sheets"]
    roof_mats = ["R.C.C.", "Tiles", "Metal Sheets", "Asbestos"]
    uses = ["Residential", "Residential", "Residential", "Residential-cum-commercial", "Commercial"]
    conditions = ["Good", "Good", "Livable", "Livable", "Dilapidated"]
    ownerships = ["Owned", "Owned", "Rented", "Rented", "Leased"]

    for i in range(TOTAL_BUILDINGS):
        b_id = str(uuid.uuid4())
        building_ids.append(b_id)
        addr_id = address_ids[i % len(address_ids)]
        b_num = f"BLD-MUM-{i+1:05d}"
        ch_num = f"CH-{i+1:05d}"

        building_rows.append({
            "building_id": b_id,
            "address_id": addr_id,
            "building_number": b_num,
            "census_house_number": ch_num,
            "floor_material": random.choice(floor_mats),
            "wall_material": random.choice(wall_mats),
            "roof_material": random.choice(roof_mats),
            "house_use": random.choice(uses),
            "condition": random.choice(conditions),
            "ownership_status": random.choice(ownerships),
            "dwelling_rooms": random.randint(1, 6)
        })
    post_batch("building", building_rows, batch_size=700)

    # 8. Households (4,500) and Target Persons (15,000)
    print("\n[8/16] Planning 4,500 Households with EXACTLY 15,000 Persons...")
    TOTAL_HOUSEHOLDS = 4500
    TARGET_PERSONS = 15000

    # Determine exact distribution of household sizes summing to 15,000:
    # 4500 households, avg size = 15000/4500 = 3.3333...
    # Distribution:
    # size 1: 450 hh -> 450
    # size 2: 850 hh -> 1,700
    # size 3: 1200 hh -> 3,600
    # size 4: 1250 hh -> 5,000
    # size 5: 500 hh -> 2,500
    # size 6: 250 hh -> 1,500
    # 450 + 850 + 1200 + 1250 + 500 + 250 = 4,500 households!
    # Sum: 450 + 1700 + 3600 + 5000 + 2500 + 1500 = 14,750.
    # Difference to 15,000 is +250.
    # Convert 250 size-4 to size-5 -> +250 persons!
    # New counts:
    # size 1: 450 (450)
    # size 2: 850 (1700)
    # size 3: 1200 (3600)
    # size 4: 1000 (4000)
    # size 5: 750 (3750)
    # size 6: 250 (1500)
    # Total HH = 450 + 850 + 1200 + 1000 + 750 + 250 = 4,500
    # Total Persons = 450 + 1700 + 3600 + 4000 + 3750 + 1500 = 15,000 EXACTLY!
    
    hh_sizes = (
        [1] * 450 +
        [2] * 850 +
        [3] * 1200 +
        [4] * 1000 +
        [5] * 750 +
        [6] * 250
    )
    random.shuffle(hh_sizes)
    assert len(hh_sizes) == TOTAL_HOUSEHOLDS
    assert sum(hh_sizes) == TARGET_PERSONS

    household_rows = []
    household_ids = []
    hh_head_category = ["GEN", "OBC", "SC", "ST", "EWS"]

    for i in range(TOTAL_HOUSEHOLDS):
        hh_id = str(uuid.uuid4())
        household_ids.append(hh_id)
        bld_id = building_ids[i % len(building_ids)]
        hh_num = f"MUM-HH-{i+1:05d}"
        size = hh_sizes[i]

        household_rows.append({
            "household_id": hh_id,
            "building_id": bld_id,
            "household_number": hh_num,
            "residents_count": size,
            "head_category": random.choice(hh_head_category),
            "married_couples_count": 1 if size >= 2 else 0,
            "mobile_contact": f"98200{random.randint(10000, 99999)}"
        })

    post_batch("household", household_rows, batch_size=750)

    # 9. Persons (15,000)
    print("\n[9/16] Generating exactly 15,000 Person records with relational family links...")
    person_rows = []
    head_links = []
    spouse_links = []
    all_persons_meta = [] # for sub-table generations

    religions = ["Hindu", "Hindu", "Hindu", "Muslim", "Muslim", "Christian", "Jain", "Buddhist", "Sikh"]
    marital_adult = ["Currently Married", "Currently Married", "Never Married", "Widowed", "Divorced"]

    person_counter = 0

    for i, hh_id in enumerate(household_ids):
        hh_size = hh_sizes[i]
        family_surname = random.choice(LAST_NAMES)
        caste_id = random.choice(caste_ids)
        religion = random.choice(religions)

        # Head person (Member 0)
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
            "spouse_person_id": None,
            "nationality": "Indian",
            "religion": religion,
            "caste_id": caste_id,
            "disability_id": random.choice(disability_other_ids) if random.random() < 0.05 else disability_none_id
        }
        person_rows.append(head_row)
        head_links.append((hh_id, head_id))
        all_persons_meta.append((head_id, head_age, head_gender, "Head", head_married))
        person_counter += 1

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
            # Record reciprocal link for post-insert patching to avoid forward-ref FK error
            spouse_links.append((head_id, spouse_id))
            person_rows.append(spouse_row)
            all_persons_meta.append((spouse_id, spouse_age, spouse_gender, "Spouse", True))
            person_counter += 1

        # Members 2..N: Children / other relatives
        for m_idx in range(2, hh_size):
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
            person_counter += 1

    assert person_counter == TARGET_PERSONS, f"Expected {TARGET_PERSONS}, got {person_counter}"
    print(f"  Inserting {len(person_rows)} persons into 'person'...")
    post_batch("person", person_rows, batch_size=750)

    # 10. Update Household Head & Reciprocal Spouse Links
    print("\n[10/16] Updating head_person_id on households & reciprocal spouse links...")
    patch_batch_heads(head_links)
    patch_batch_spouses(spouse_links)

    # 11. Household Utilities
    print("\n[11/16] Seeding Household Utilities (Water, Sanitation, Cooking, Utility, Food, Assets)...")
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

    for hh_id in household_ids:
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

        # Assets: 4-7 assets per household
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

    # 12. Demographics Sub-tables (Person Languages, Education, Employment, Travel)
    print("\n[12/16] Seeding Person Languages, Education, Employment, Work Travel...")
    lang_rows = []
    edu_rows = []
    emp_rows = []
    travel_rows = []

    travel_modes = ["Local Train", "Local Train", "Bus", "Metro", "Walking", "Auto Rickshaw", "Two-Wheeler", "Car"]
    eco_cats = ["Main Worker", "Marginal Worker", "Non-Worker"]

    for p_id, p_age, p_gender, rel, is_married in all_persons_meta:
        # Languages: Marathi (60% native), Hindi (30% native), Gujarati (10% native)
        primary_lang = random.choices(["Marathi", "Hindi", "Gujarati", "Urdu", "Tamil"], weights=[55, 30, 8, 4, 3])[0]
        if primary_lang in lang_map:
            lang_rows.append({
                "person_id": p_id,
                "language_id": lang_map[primary_lang],
                "is_mother_tongue": True,
                "proficiency_level": "Fluent"
            })
        # English or Hindi as secondary
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
            lvl = edu_ids[0] # Illiterate
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

            # Travel
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

    # 13. Migration, Fertility, Covid Vaccination, Bank Accounts, Identity Docs
    print("\n[13/16] Seeding Migration, Fertility, Vaccination, Bank Accounts, Identity Docs...")
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
                "birth_place_id": random.choice(place_ids[1:]), # from other states
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

        # COVID vaccination (substantially vaccinated)
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

    # 14. Census Visits (5,000)
    print("\n[14/16] Seeding 5,000 Census Visits...")
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

    # 15. Census Records (4,500)
    print("\n[15/16] Seeding 4,500 Census Records (one per household)...")
    record_rows = []
    record_ids = []

    for i in range(TOTAL_HOUSEHOLDS):
        r_id = str(uuid.uuid4())
        record_ids.append(r_id)
        v_id = visit_ids[i % len(visit_ids)]
        hh_id = household_ids[i]
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

    # 16. Audit Logs (~5,000)
    print("\n[16/16] Seeding 5,000 Audit Log records...")
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
    print("SUCCESS: Large-Scale Mumbai Census Dataset Generation Complete!")
    print("=" * 70)

if __name__ == "__main__":
    main()
