# Complete DevSecOps Pipeline & Security Operation Center (SOC) Integration

This project demonstrates a comprehensive, production-ready **DevSecOps Pipeline** combined with a **Security Operation Center (SOC)** monitoring system. It implements a secure software development lifecycle (SSDLC) by shifting security both **Left** (CI/CD static & dynamic scanning) and **Right** (Runtime intrusion detection and centralized SIEM monitoring).

---

## ─── System Architecture ───

<img width="1717" height="667" alt="image" src="https://github.com/user-attachments/assets/35f58188-6379-4ead-b242-bea075a0c18c" />

## ─── Key Security Components ───

### 1. DevSecOps (Shift-Left Security)
* **Static Application Security Testing (SAST):** Utilizes **Semgrep** to scan custom source code for common security bugs, code smells, and owasp top 10 vulnerabilities.
* **Infrastructure as Code (IaC) Scanning:** Utilizes **Checkov** to analyze Dockerfiles, Docker Compose configurations, and system configurations for misconfigurations.
* **Software Composition Analysis (SCA) & SBOM:** Utilizes **Trivy** to generate Software Bill of Materials (SBOM) and scan open-source dependencies for known vulnerabilities (CVEs).
* **Dynamic Application Security Testing (DAST):** Utilizes **OWASP ZAP** to scan the running web application (OWASP Juice Shop) for runtime vulnerabilities like XSS, SQLi, and broken authentication.
* **Centralized Vulnerability Management:** Automatically parses and uploads all scan results from the tools above into **DefectDojo** using a custom integration script.

### 2. Security Operations Center (Shift-Right & Runtime Protection)
* **Network Intrusion Detection System (NIDS):** Uses **Suricata** running on the Target Server to monitor network packets on interface `ens33`. It detects network scans, brute-force attempts, and web attacks.
* **Host Intrusion Detection System (HIDS) & SIEM:** Configures **Wazuh Agent** on the Target Server to monitor host logs, Nginx access logs, file integrity (FIM), and Suricata's `eve.json` alerts, sending them to **Wazuh Manager**.
* **Active Response (Automated Defense):** When Wazuh detects a high-severity alert (such as XSS or SQLi), it triggers an automated response script on the Target Server to drop the attacker's IP using `iptables` for 10 minutes.
---

## ─── Project Structure ───

```text
DevSecOps/
├── .github/workflows/
│   └── devseceops.yml          # GitHub Actions CI/CD Pipeline
├── docker-compose.yml          # Application deployment configurations
├── juice-shop/                 # Target application source code
├── scripts/                    # Automation scripts
│   ├── run-semgrep.ps1         # Run Semgrep scan
│   ├── run-checkov.ps1         # Run Checkov scan
│   ├── run-trivy.ps1           # Run Trivy SCA & SBOM generator
│   ├── run-zap.ps1             # Run OWASP ZAP DAST scan
│   ├── import-defectdojo.ps1   # Import findings to DefectDojo API
│   ├── deploy.ps1              # Deployment script to Target Server
│   ├── deploy-suricata.ps1     # Automated Suricata installer & configurer
│   └── health-check.ps1        # Application deployment health check
└── README.md                   # Project documentation
```

---

## ─── Setup & Deployment Guide ───

### 1. Prerequisites
* **Target Server (VM1):** Ubuntu Linux with Docker and Docker Compose installed. SSH access enabled.
* **SOC & Management Server (VM2):** Ubuntu Linux with Wazuh Manager and DefectDojo installed. GitHub Actions Self-Hosted Runner configured and running.

### 2. CI/CD Deployment
On every code commit push, GitHub Actions will trigger the self-hosted runner on VM2 to execute:
1. **Static Analysis:** Runs SAST (Semgrep) and SCA (Trivy) to validate code.
2. **Infrastructure Validation:** Runs IaC Scan (Checkov) on Docker configurations.
3. **Build & Release:** Builds the Docker image and pushes it to GitHub Container Registry (GHCR).
4. **Automated SSH Deploy:** Remotely instructs VM1 to pull the image and run the container.
5. **Dynamic Analysis:** Launches OWASP ZAP (DAST) to attack the running application on VM1 and scan for dynamic loopholes.
6. **Centralization:** Uploads all JSON reports to DefectDojo.

## ─── Runtime Attack Simulation & Verification ───

To verify the effectiveness of the NIDS (Suricata) + SIEM (Wazuh) runtime defense architecture, simulate attacks from the developer machine and observe the system's reaction:

### Test Case 1: Cross-Site Scripting (XSS) Detection & Blocking
* **Attack Payload (via Web Browser or Curl):**
  ```bash
  http://192.168.11.129/?q=%3Cscript%3Ealert(%22hacked%22)%3C/script%3E#/
  ```
  <img width="491" height="83" alt="image" src="https://github.com/user-attachments/assets/36df4937-1210-48a4-9afb-f3598a6659d4" />
  <img width="547" height="236" alt="image" src="https://github.com/user-attachments/assets/118bc4af-def6-4887-8af9-19db9499a3a9" />

* **Detection & Response Flow (Multi-layered Protection):**
  1. **Dual Alert Generation on VM1:**
     * **Suricata NIDS** intercepts the network packets, decodes the HTTP URI, matches it against rule `1000003` (`CUSTOM XSS Attempt Detected`), and writes an alert to `/var/log/suricata/eve.json`.
     * **Nginx Web Server** logs the HTTP request details and payload to `/var/log/nginx/access.log`.
  2. **Wazuh Agent Collection:** The Wazuh Agent running on VM1 monitors both `eve.json` and `access.log` simultaneously, reads the new lines, and securely transmits them to **Wazuh Manager** on VM2.
  3. **Wazuh Manager Correlation & Action:** Wazuh Manager parses and correlates the incoming logs, matching them against **Rule ID `100004`** (Suricata Alert) and **Rule ID `31105`** (Nginx XSS Alert). Since both alerts match critical security thresholds, Wazuh Manager triggers the **Active Response** mechanism to instruct VM1 to drop the attacker's IP via `iptables` for 10 minutes.

### Test Case 2: SQL Injection (SQLi) Detection
* **Attack Payload (via Web Browser or Curl):**
  ```bash
  http://192.168.11.129/?id=1%27%20UNION%20SELECT%20NULL,username,password%20FROM%20users--#/
  ```
  <img width="518" height="82" alt="image" src="https://github.com/user-attachments/assets/59cdf256-10ef-4dc3-b785-6f9d2d110a98" />
  <img width="541" height="197" alt="image" src="https://github.com/user-attachments/assets/c2ee488d-537f-49fa-9721-2fce5a9ee059" />

* **Detection & Response Flow (Multi-layered Protection):**
  1. **Dual Alert Generation on VM1:**
     * **Suricata NIDS** intercepts the network packets, decodes the HTTP URI, matches it against rule `1000004` (`CUSTOM SQLi Attempt Detected`), and writes an alert to `/var/log/suricata/eve.json`.
     * **Nginx Web Server** logs the SQLi attack payload in the HTTP query parameters to `/var/log/nginx/access.log`.
  2. **Wazuh Agent Collection:** The Wazuh Agent on VM1 monitors both `eve.json` and `access.log` simultaneously, forwarding the new events to **Wazuh Manager** on VM2.
  3. **Wazuh Manager Correlation:** Wazuh Manager correlates the logs, matching **Rule ID `100004`** (Suricata custom alert) and **Rule ID `31164`** (Nginx SQLi alert), logging them to the SIEM dashboard, and triggering Active Response to blacklist the source IP.

| Trigger Rule ID | Event Type | Mitigation Action | Block Timeout |
| :--- | :--- | :--- | :--- |
| **`5760`** | SSH Brute Force Attempt | `firewall-drop` (Block via `iptables`) | **180 seconds** (3 mins) |
| **`31105`** | Web XSS Attempt (via Nginx log) | `firewall-drop` (Block via `iptables`) | **300 seconds** (5 mins) |
| **`31106`** | Web SQLi Attempt (via Nginx log) | `firewall-drop` (Block via `iptables`) | **300 seconds** (5 mins) |
| **`100003`, `100004`** | Custom Suricata XSS/SQLi Alerts | `firewall-drop` (Block via `iptables`) | **300 seconds** (5 mins) |
---
