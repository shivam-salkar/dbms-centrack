import urllib.request
import urllib.error
import json

SUPABASE_URL = "https://azmpvvbivdkqjdrqcmba.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6bXB2dmJpdmRrcWpkcnFjbWJhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDc5MTM4NSwiZXhwIjoyMTA2MzY3Mzg1fQ.0voIvmTEVhuaeOo8svsPjnbB2sbYfkCGXdZ03Kx0I2w"

headers = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation,resolution=merge-duplicates"
}

def post(endpoint, data):
    req = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/{endpoint}",
        data=json.dumps(data).encode("utf-8"),
        headers=headers,
        method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))

def seed_census():
    # Check if households already exist
    req = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/household?select=household_id", headers=headers)
    with urllib.request.urlopen(req) as resp:
        existing = json.loads(resp.read().decode("utf-8"))
        if len(existing) > 0:
            print("Households already seeded:", len(existing))
            return

    print("Seeding initial census households and buildings...")
    # Fetch blocks
    req_b = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/enumeration_block?select=*", headers=headers)
    with urllib.request.urlopen(req_b) as resp:
        blocks = json.loads(resp.read().decode("utf-8"))

    block_lko = blocks[0]["block_id"] # Lucknow
    block_mum = blocks[2]["block_id"] if len(blocks) > 2 else blocks[0]["block_id"] # Mumbai
    block_cok = blocks[3]["block_id"] if len(blocks) > 3 else blocks[0]["block_id"] # Kochi

    # 1. Address 1 (Lucknow)
    a1 = post("address", [{
        "block_id": block_lko,
        "house_number": "12",
        "street_name": "Rajpur Road",
        "locality": "Hazratganj",
        "pin_code": "226001"
    }])[0]

    # 2. Address 2 (Mumbai)
    a2 = post("address", [{
        "block_id": block_mum,
        "house_number": "7",
        "street_name": "Marine Drive",
        "locality": "Colaba",
        "pin_code": "400020"
    }])[0]

    # 3. Address 3 (Kochi / Ernakulam)
    a3 = post("address", [{
        "block_id": block_cok,
        "house_number": "3",
        "street_name": "MG Road",
        "locality": "Kochi Central",
        "pin_code": "682016"
    }])[0]

    # Buildings
    b1 = post("building", [{
        "address_id": a1["address_id"],
        "building_number": "BLD-001",
        "census_house_number": "C-101",
        "floor_material": "Cement",
        "wall_material": "Burnt Brick",
        "roof_material": "R.C.C.",
        "house_use": "Residential",
        "condition": "Good",
        "ownership_status": "Owned",
        "dwelling_rooms": 4
    }])[0]

    b2 = post("building", [{
        "address_id": a2["address_id"],
        "building_number": "BLD-002",
        "census_house_number": "C-202",
        "floor_material": "Mosaic / Floor Tiles",
        "wall_material": "Concrete",
        "roof_material": "R.C.C.",
        "house_use": "Residential",
        "condition": "Good",
        "ownership_status": "Rented",
        "dwelling_rooms": 3
    }])[0]

    b3 = post("building", [{
        "address_id": a3["address_id"],
        "building_number": "BLD-003",
        "census_house_number": "C-303",
        "floor_material": "Cement",
        "wall_material": "Stone",
        "roof_material": "Tiles",
        "house_use": "Residential",
        "condition": "Good",
        "ownership_status": "Owned",
        "dwelling_rooms": 2
    }])[0]

    # Households
    hh1 = post("household", [{
        "building_id": b1["building_id"],
        "household_number": "HH-001",
        "residents_count": 4,
        "head_category": "GEN",
        "married_couples_count": 1,
        "mobile_contact": "9876543210"
    }])[0]

    hh2 = post("household", [{
        "building_id": b2["building_id"],
        "household_number": "HH-002",
        "residents_count": 3,
        "head_category": "OBC",
        "married_couples_count": 1,
        "mobile_contact": "9876543211"
    }])[0]

    hh3 = post("household", [{
        "building_id": b3["building_id"],
        "household_number": "HH-004",
        "residents_count": 2,
        "head_category": "GEN",
        "married_couples_count": 1,
        "mobile_contact": "9876543212"
    }])[0]

    # Persons for HH-001
    p1 = post("person", [{
        "household_id": hh1["household_id"],
        "name": "Ramesh Gupta",
        "relationship_to_head": "Head",
        "sex": "Male",
        "age_completed_years": 45,
        "marital_status": "Currently Married"
    }])[0]

    p2 = post("person", [{
        "household_id": hh1["household_id"],
        "name": "Sunita Gupta",
        "relationship_to_head": "Spouse",
        "sex": "Female",
        "age_completed_years": 40,
        "marital_status": "Currently Married"
    }])[0]

    # Link head_person_id to household
    req_head = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/household?household_id=eq.{hh1['household_id']}",
        data=json.dumps({"head_person_id": p1["person_id"]}).encode("utf-8"),
        headers=headers,
        method="PATCH"
    )
    urllib.request.urlopen(req_head)

    # Person for HH-002
    p3 = post("person", [{
        "household_id": hh2["household_id"],
        "name": "Meena Krishnan",
        "relationship_to_head": "Head",
        "sex": "Female",
        "age_completed_years": 38,
        "marital_status": "Currently Married"
    }])[0]

    req_head2 = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/household?household_id=eq.{hh2['household_id']}",
        data=json.dumps({"head_person_id": p3["person_id"]}).encode("utf-8"),
        headers=headers,
        method="PATCH"
    )
    urllib.request.urlopen(req_head2)

    print("Successfully seeded initial households and persons into Supabase!")

if __name__ == "__main__":
    seed_census()
