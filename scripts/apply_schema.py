"""
Apply Jangana Census Database Schema to Supabase
=================================================
Usage:
  python scripts/apply_schema.py [--token <SUPABASE_ACCESS_TOKEN>] [--password <DB_PASSWORD>]

If SUPABASE_ACCESS_TOKEN is supplied (or set in env), it executes the schema
via the Supabase Management API database query endpoint.
"""

import sys
import os
import argparse
import urllib.request
import urllib.error
import json

PROJECT_REF = "azmpvvbivdkqjdrqcmba"
SCHEMA_FILE = os.path.join(os.path.dirname(__file__), "..", "schema.sql")

def run_via_management_api(token, sql):
    print(f"Connecting to Supabase Management API for project: {PROJECT_REF}...")
    url = f"https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query"
    req = urllib.request.Request(
        url,
        data=json.dumps({"query": sql}).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST"
    )
    try:
        with urllib.request.urlopen(req) as resp:
            status = resp.status
            result = resp.read().decode("utf-8")
            print(f"Success! Status: {status}")
            print("Schema applied successfully to Supabase.")
            return True
    except urllib.error.HTTPError as e:
        print(f"HTTP Error {e.code}: {e.read().decode('utf-8')}")
        return False
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Apply schema to Supabase")
    parser.add_argument("--token", help="Supabase personal access token (sbp_...)")
    parser.add_argument("--password", help="Supabase PostgreSQL database password")
    args = parser.parse_args()

    token = args.token or os.environ.get("SUPABASE_ACCESS_TOKEN")
    password = args.password or os.environ.get("SUPABASE_DB_PASSWORD")

    if not os.path.exists(SCHEMA_FILE):
        print(f"Schema file not found at: {SCHEMA_FILE}")
        sys.exit(1)

    with open(SCHEMA_FILE, "r", encoding="utf-8") as f:
        sql = f.read()

    print(f"Loaded schema.sql ({len(sql.splitlines())} lines).")

    if token:
        success = run_via_management_api(token, sql)
        if success:
            sys.exit(0)
        else:
            sys.exit(1)

    print("\n" + "=" * 70)
    print("HOW TO RUN THIS SCHEMA ON SUPABASE:")
    print("=" * 70)
    print("1. Open Supabase SQL Editor:")
    print(f"   https://supabase.com/dashboard/project/{PROJECT_REF}/sql/new")
    print("2. Copy the content of 'schema.sql' and paste it into the query box.")
    print("3. Click 'Run' to create all 34 tables, RLS policies, triggers, and seed data.")
    print("\nAlternatively, set your SUPABASE_ACCESS_TOKEN environment variable:")
    print("   python scripts/apply_schema.py --token <your_sbp_token>")
    print("=" * 70)

if __name__ == "__main__":
    main()
