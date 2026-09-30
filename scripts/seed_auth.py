"""
Seed and verify Supabase Auth Users for Centrack
================================================
Usage:
  python scripts/seed_auth.py
"""

import urllib.request
import urllib.error
import json

SUPABASE_URL = "https://azmpvvbivdkqjdrqcmba.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6bXB2dmJpdmRrcWpkcnFjbWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3OTEzODUsImV4cCI6MjEwNjM2NzM4NX0.mJmbQQaLHdM53qfnGf3kza_mWTgHtdbYLk6viAgknqc"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6bXB2dmJpdmRrcWpkcnFjbWJhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDc5MTM4NSwiZXhwIjoyMTA2MzY3Mzg1fQ.0voIvmTEVhuaeOo8svsPjnbB2sbYfkCGXdZ03Kx0I2w"

USERS_TO_SEED = [
    {
        "email": "rajesh.singh@census.gov.in",
        "password": "admin123",
        "email_confirm": True,
        "user_metadata": {
            "name": "Rajesh Kumar Singh",
            "role": "District Administrator",
            "employee_code": "OFF-2024-0142"
        }
    },
    {
        "email": "priya.nair@census.gov.in",
        "password": "enum123",
        "email_confirm": True,
        "user_metadata": {
            "name": "Priya Nair",
            "role": "Enumerator",
            "employee_code": "OFF-2024-0089"
        }
    }
]

def list_auth_users():
    req = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/admin/users",
        headers={
            "apikey": SERVICE_KEY,
            "Authorization": f"Bearer {SERVICE_KEY}"
        }
    )
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        return data.get("users", [])

def create_user(user_data):
    req = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/admin/users",
        data=json.dumps(user_data).encode("utf-8"),
        headers={
            "apikey": SERVICE_KEY,
            "Authorization": f"Bearer {SERVICE_KEY}",
            "Content-Type": "application/json"
        },
        method="POST"
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8")
        if "already registered" in err or "User already exists" in err:
            return {"email": user_data["email"], "status": "already_exists"}
        print(f"Error creating {user_data['email']}: {err}")
        return None

def test_login(email, password):
    req = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        data=json.dumps({"email": email, "password": password}).encode("utf-8"),
        headers={
            "apikey": ANON_KEY,
            "Content-Type": "application/json"
        },
        method="POST"
    )
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return True, data.get("access_token")
    except Exception as e:
        return False, str(e)

def main():
    print("--- 1. Checking / Seeding Supabase Auth Users ---")
    existing = {u["email"]: u for u in list_auth_users()}
    for u in USERS_TO_SEED:
        if u["email"] in existing:
            print(f"[OK] User {u['email']} already exists (id: {existing[u['email']]['id']})")
        else:
            res = create_user(u)
            print(f"[+] Created user {u['email']}: {res}")

    print("\n--- 2. Testing Authentication with Anon Key ---")
    for u in USERS_TO_SEED:
        ok, res = test_login(u["email"], u["password"])
        if ok:
            print(f"[OK] Login successful for {u['email']} (token: {res[:25]}...)")
        else:
            print(f"[FAIL] Login failed for {u['email']}: {res}")

if __name__ == "__main__":
    main()
