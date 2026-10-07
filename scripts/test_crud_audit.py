import urllib.request
import urllib.error
import json
import time

SUPABASE_URL = "https://azmpvvbivdkqjdrqcmba.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6bXB2dmJpdmRrcWpkcnFjbWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3OTEzODUsImV4cCI6MjEwNjM2NzM4NX0.mJmbQQaLHdM53qfnGf3kza_mWTgHtdbYLk6viAgknqc"

def get_auth_token(email, password):
    req = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        data=json.dumps({"email": email, "password": password}).encode("utf-8"),
        headers={"apikey": ANON_KEY, "Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        return data["access_token"], data["user"]

def run_crud_test():
    print("--- 1. Authenticating as Enumerator 1 ---")
    token, user = get_auth_token("enumerator1.demo@janganatest.local", "JanganaEnum@2026")
    headers = {
        "apikey": ANON_KEY,
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Prefer": "return=representation"
    }
    print(f"Authenticated as: {user['id']}")

    # 1. READ reference blocks
    req = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/enumeration_block?select=*", headers=headers)
    with urllib.request.urlopen(req) as resp:
        blocks = json.loads(resp.read().decode("utf-8"))
        print(f"Retrieved {len(blocks)} enumeration blocks. Using block: {blocks[0]['block_id']}")
        block_id = blocks[0]["block_id"]

    ts = int(time.time())
    test_id_str = f"TEST_JANGANA_INTEGRATION_{ts}"

    # 2. INSERT address
    addr_payload = {
        "block_id": block_id,
        "house_number": "HN-99",
        "street_name": "Integration Test Road",
        "locality": "Hazratganj",
        "pin_code": "226001"
    }
    req = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/address",
        data=json.dumps(addr_payload).encode("utf-8"),
        headers=headers,
        method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        addr = json.loads(resp.read().decode("utf-8"))[0]
        addr_id = addr["address_id"]
        print(f"INSERT Address Success: {addr_id}")

    # 3. INSERT building
    building_payload = {
        "address_id": addr_id,
        "building_number": f"BLD_{ts}",
        "census_house_number": test_id_str,
        "floor_material": "Concrete",
        "wall_material": "Burnt Brick",
        "roof_material": "R.C.C.",
        "house_use": "Residential",
        "condition": "Good",
        "ownership_status": "Owned",
        "dwelling_rooms": 3
    }
    req = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/building",
        data=json.dumps(building_payload).encode("utf-8"),
        headers=headers,
        method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        bld = json.loads(resp.read().decode("utf-8"))[0]
        bld_id = bld["building_id"]
        print(f"INSERT Building Success: {bld_id}")

    # 4. INSERT household with residents_count = 5
    hh_payload = {
        "building_id": bld_id,
        "household_number": test_id_str,
        "residents_count": 5,
        "head_category": "GEN",
        "married_couples_count": 1,
        "mobile_contact": "9876543210"
    }
    req = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/household",
        data=json.dumps(hh_payload).encode("utf-8"),
        headers=headers,
        method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        hh = json.loads(resp.read().decode("utf-8"))[0]
        hh_id = hh["household_id"]
        print(f"INSERT Household Success: {hh_id} with residents_count = {hh['residents_count']}")

    # 5. READ back household
    req = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/household?household_id=eq.{hh_id}", headers=headers)
    with urllib.request.urlopen(req) as resp:
        fetched = json.loads(resp.read().decode("utf-8"))[0]
        print(f"READ Household verified: {fetched['household_number']}, residents_count = {fetched['residents_count']}")

    # 6. UPDATE residents_count: 5 -> 6
    update_payload = {"residents_count": 6}
    req = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/household?household_id=eq.{hh_id}",
        data=json.dumps(update_payload).encode("utf-8"),
        headers=headers,
        method="PATCH"
    )
    with urllib.request.urlopen(req) as resp:
        updated = json.loads(resp.read().decode("utf-8"))[0]
        print(f"UPDATE Household Success: residents_count is now {updated['residents_count']}")

    # 7. Reverse UPDATE in Supabase: 6 -> 7
    reverse_payload = {"residents_count": 7}
    req = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/household?household_id=eq.{hh_id}",
        data=json.dumps(reverse_payload).encode("utf-8"),
        headers=headers,
        method="PATCH"
    )
    with urllib.request.urlopen(req) as resp:
        rev_updated = json.loads(resp.read().decode("utf-8"))[0]
        print(f"REVERSE UPDATE in Supabase: residents_count is now {rev_updated['residents_count']}")

    # Verify READ reflects 7
    req = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/household?household_id=eq.{hh_id}", headers=headers)
    with urllib.request.urlopen(req) as resp:
        verified_rev = json.loads(resp.read().decode("utf-8"))[0]
        assert verified_rev["residents_count"] == 7, "Reverse update did not match!"
        print(f"READ Verification: residents_count is {verified_rev['residents_count']} (PASS)")

    # 8. DELETE test record
    req = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/household?household_id=eq.{hh_id}",
        headers=headers,
        method="DELETE"
    )
    with urllib.request.urlopen(req) as resp:
        print(f"DELETE Household Success (HTTP {resp.status})")

    # Clean up building and address
    req_bld = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/building?building_id=eq.{bld_id}", headers=headers, method="DELETE")
    urllib.request.urlopen(req_bld)
    req_addr = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/address?address_id=eq.{addr_id}", headers=headers, method="DELETE")
    urllib.request.urlopen(req_addr)
    print("Cleanup test records completed successfully.")

if __name__ == "__main__":
    run_crud_test()
