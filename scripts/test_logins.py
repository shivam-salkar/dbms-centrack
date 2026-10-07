import urllib.request
import urllib.error
import json

SUPABASE_URL = "https://azmpvvbivdkqjdrqcmba.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6bXB2dmJpdmRrcWpkcnFjbWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3OTEzODUsImV4cCI6MjEwNjM2NzM4NX0.mJmbQQaLHdM53qfnGf3kza_mWTgHtdbYLk6viAgknqc"

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
            return True, data.get("access_token"), data.get("user")
    except urllib.error.HTTPError as e:
        return False, e.read().decode("utf-8"), None
    except Exception as e:
        return False, str(e), None

if __name__ == "__main__":
    tests = [
        ("admin.demo@janganatest.local", "JanganaDemo@2026", True),
        ("enumerator1.demo@janganatest.local", "JanganaEnum@2026", True),
        ("enumerator2.demo@janganatest.local", "JanganaEnum2@2026", True),
        ("admin.demo@janganatest.local", "WrongPassword123!", False),
    ]

    for email, pwd, expect_success in tests:
        ok, res, user = test_login(email, pwd)
        status = "PASS" if ok == expect_success else "FAIL"
        print(f"[{status}] Email: {email} | Expected: {expect_success} | Got: {ok}")
        if ok and user:
            print(f"       User ID: {user['id']} | Role: {user['user_metadata'].get('role')}")
