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
