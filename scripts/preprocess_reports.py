import json
import sys
import os
import re

CWE_CVSS_MAP = {
    79:  {"score": 6.1, "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:C/C:L/I:L/A:N"},  # XSS
    89:  {"score": 9.8, "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H"},  # SQLi
    22:  {"score": 7.5, "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N"},  # Path Traversal
    502: {"score": 9.8, "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H"},  # Deserialization
    352: {"score": 8.1, "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N"},  # CSRF
    94:  {"score": 10.0,"vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H"},  # Code Injection
    611: {"score": 9.8, "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N"},  # XXE
    200: {"score": 7.5, "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N"},  # Info Disclosure
    287: {"score": 9.8, "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H"}   # Authentication
}

def get_cvss(cwe_id):
    return CWE_CVSS_MAP.get(cwe_id)

def convert_semgrep(input_path, output_path):
    if not os.path.exists(input_path):
        print(f"Error: Input file {input_path} not found.")
        return
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    generic_findings = []
    for result in data.get('results', []):
        raw_sev = result.get('extra', {}).get('severity', 'WARNING')
        severity = "Medium"
        if raw_sev == "ERROR":
            severity = "High"
        elif raw_sev == "INFO":
            severity = "Low"
            
        cwe_list = result.get('extra', {}).get('metadata', {}).get('cwe', [])
        cwe_val = None
        if cwe_list:
            if isinstance(cwe_list, list):
                cwe_str = cwe_list[0]
            else:
                cwe_str = cwe_list
            match = re.search(r'CWE-(\d+)', cwe_str, re.IGNORECASE)
            if match:
                cwe_val = int(match.group(1))
                
        finding = {
            "title": result.get('extra', {}).get('message', 'Semgrep Finding').split('\n')[0][:120],
            "description": result.get('extra', {}).get('message', ''),
            "severity": severity,
            "file_path": result.get('path'),
            "line": result.get('start', {}).get('line', 1)
        }
        
        if cwe_val:
            finding["cwe"] = cwe_val
            cvss = get_cvss(cwe_val)
            if cvss:
                finding["cvssv3"] = cvss["vector"]
                finding["cvssv3_score"] = cvss["score"]
                
        generic_findings.append(finding)
        
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(generic_findings, f, indent=2, ensure_ascii=False)
    print(f"Semgrep report converted successfully to {output_path}")

def convert_zap(input_path, output_path):
    if not os.path.exists(input_path):
        print(f"Error: Input file {input_path} not found.")
        return
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    generic_findings = []
    for site in data.get('site', []):
        for alert in site.get('alerts', []):
            risk_code = alert.get('riskcode', '0')
            if risk_code == '3':
                severity = 'High'
            elif risk_code == '2':
                severity = 'Medium'
            elif risk_code == '1':
                severity = 'Low'
            else:
                severity = 'Info'
                
            cwe_val = None
            cwe_id = alert.get('cweid')
            if cwe_id:
                try:
                    val = int(cwe_id)
                    if val > 0:
                        cwe_val = val
                except ValueError:
                    pass
            
            instances_desc = ""
            for inst in alert.get('instances', []):
                instances_desc += f"- **URI:** {inst.get('uri')}\n  **Method:** {inst.get('method')}\n  **Param:** {inst.get('param')}\n  **Evidence:** {inst.get('evidence')}\n"
                
            description = f"{alert.get('desc', '')}\n\n**Solution:**\n{alert.get('solution', '')}\n\n**Instances:**\n{instances_desc}"
            
            finding = {
                "title": alert.get('alert', 'ZAP Finding')[:120],
                "description": description,
                "severity": severity
            }
            
            if cwe_val:
                finding["cwe"] = cwe_val
                cvss = get_cvss(cwe_val)
                if cvss:
                    finding["cvssv3"] = cvss["vector"]
                    finding["cvssv3_score"] = cvss["score"]
                    
            generic_findings.append(finding)
            
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(generic_findings, f, indent=2, ensure_ascii=False)
    print(f"ZAP report converted successfully to {output_path}")

def main():
    if len(sys.argv) < 4:
        print("Usage: python3 preprocess_reports.py <semgrep|zap> <input_path> <output_path>")
        sys.exit(1)
        
    tool = sys.argv[1].lower()
    input_path = sys.argv[2]
    output_path = sys.argv[3]
    
    if tool == 'semgrep':
        convert_semgrep(input_path, output_path)
    elif tool == 'zap':
        convert_zap(input_path, output_path)
    else:
        print(f"Error: Unknown tool {tool}")
        sys.exit(1)

if __name__ == '__main__':
    main()
