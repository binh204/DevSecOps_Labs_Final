#!/usr/bin/env python3
import sys
import os
import urllib.request
import urllib.parse
import urllib.error
import json

def main():
    defectdojo_url = os.environ.get("DEFECTDOJO_URL", "http://192.168.11.130:8080")
    api_token = os.environ.get("API_TOKEN")
    run_number = os.environ.get("RUN_NUMBER")

    if not api_token or not run_number:
        print("ERROR: API_TOKEN or RUN_NUMBER environment variable is missing!", file=sys.stderr)
        sys.exit(1)

    print("========== DEFECTDOJO SECURITY QUALITY GATE ==========")
    print(f"Checking findings for Engagement: 'CI/CD Build #{run_number}'...")

    # Step 1: Find Engagement ID by name
    engagement_name = f"CI/CD Build #{run_number}"
    req_url = f"{defectdojo_url}/api/v2/engagements/?name={urllib.parse.quote(engagement_name)}"
    
    req = urllib.request.Request(req_url)
    req.add_header("Authorization", f"Token {api_token}")
    req.add_header("Accept", "application/json")

    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            results = data.get("results", [])
            if not results:
                print(f"Warning: Engagement '{engagement_name}' not found on DefectDojo. Passing by default.")
                sys.exit(0)
            engagement_id = results[0]["id"]
    except Exception as e:
        print(f"Error querying DefectDojo Engagement: {e}", file=sys.stderr)
        sys.exit(1)

    # Step 2: Query ALL findings for this Engagement (with pagination support)
    critical_count = 0
    high_count = 0
    medium_count = 0
    low_count = 0
    info_count = 0

    current_url = f"{defectdojo_url}/api/v2/findings/?test__engagement={engagement_id}&active=true&limit=100"

    try:
        while current_url:
            req_f = urllib.request.Request(current_url)
            req_f.add_header("Authorization", f"Token {api_token}")
            req_f.add_header("Accept", "application/json")

            with urllib.request.urlopen(req_f) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                findings = data.get("results", [])
                for f in findings:
                    sev = (f.get("severity") or "").capitalize()
                    if sev == "Critical":
                        critical_count += 1
                    elif sev == "High":
                        high_count += 1
                    elif sev == "Medium":
                        medium_count += 1
                    elif sev == "Low":
                        low_count += 1
                    else:
                        info_count += 1
                
                # Update current_url to the next page URL if available
                current_url = data.get("next")
    except Exception as e:
        print(f"Error querying DefectDojo Findings: {e}", file=sys.stderr)
        sys.exit(1)

    print("\n--- SECURITY FINDINGS SUMMARY ---")
    print(f" Critical: {critical_count}")
    print(f" High    : {high_count}")
    print(f" Medium  : {medium_count}")
    print(f" Low     : {low_count}")
    print(f" Info    : {info_count}")
    print("---------------------------------\n")

    # SECURITY QUALITY GATE POLICY:
    # Fail pipeline IF Critical > 0
    if critical_count > 0:
        print(f"❌ QUALITY GATE FAILED: Found {critical_count} CRITICAL vulnerability(ies)!")
        print("Production Deployment BLOCKED by Security Policy.")
        sys.exit(1)
    else:
        print("✅ QUALITY GATE PASSED: 0 Critical vulnerabilities found.")
        if high_count > 0 or medium_count > 0:
            print(f"⚠️ Warning: Found {high_count} High and {medium_count} Medium findings. Allowed for Demo / Non-Critical deployment.")
        print("Production Deployment APPROVED.")
        sys.exit(0)

if __name__ == "__main__":
    main()
