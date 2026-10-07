import urllib.request
import urllib.error
import json

SUPABASE_URL = "https://azmpvvbivdkqjdrqcmba.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6bXB2dmJpdmRrcWpkcnFjbWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3OTEzODUsImV4cCI6MjEwNjM2NzM4NX0.mJmbQQaLHdM53qfnGf3kza_mWTgHtdbYLk6viAgknqc"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6bXB2dmJpdmRrcWpkcnFjbWJhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDc5MTM4NSwiZXhwIjoyMTA2MzY3Mzg1fQ.0voIvmTEVhuaeOo8svsPjnbB2sbYfkCGXdZ03Kx0I2w"

def inspect_auth_and_tables():
    # 1. Auth users
    req = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/admin/users",
        headers={"apikey": SERVICE_KEY, "Authorization": f"Bearer {SERVICE_KEY}"}
    )
    with urllib.request.urlopen(req) as resp:
        users = json.loads(resp.read().decode("utf-8")).get("users", [])
        print(f"Total Auth Users: {len(users)}")
        for u in users:
            print(f"  - Email: {u.get('email')} | ID: {u.get('id')} | Metadata: {u.get('user_metadata')}")

    # 2. Enumerator table
    req2 = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/enumerator?select=*",
        headers={"apikey": SERVICE_KEY, "Authorization": f"Bearer {SERVICE_KEY}"}
    )
    with urllib.request.urlopen(req2) as resp:
        enums = json.loads(resp.read().decode("utf-8"))
        print(f"\nTotal Enumerator records: {len(enums)}")
        for e in enums:
            print(f"  - Name: {e.get('name')} | Code: {e.get('employee_code')} | Role: {e.get('role')} | AuthUID: {e.get('auth_user_id')}")

    # 3. Check existing data in household, building, address, city, ward, block
    for tbl in ["city", "ward", "enumeration_block", "address", "building", "household", "person", "census_record"]:
        req3 = urllib.request.Request(
            f"{SUPABASE_URL}/rest/v1/{tbl}?select=count",
            headers={"apikey": SERVICE_KEY, "Authorization": f"Bearer {SERVICE_KEY}", "Prefer": "count=exact"}
        )
        try:
            with urllib.request.urlopen(req3) as resp:
                cr = resp.headers.get("content-range")
                print(f"Table '{tbl}' row count: {cr}")
        except Exception as ex:
            print(f"Table '{tbl}' query error: {ex}")

if __name__ == "__main__":
    inspect_auth_and_tables()
