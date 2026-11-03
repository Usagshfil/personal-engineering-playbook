# Security & Privacy Review: [Feature / Release Name]

> **Document Status**: Draft / Approved  
> **Reviewer**: [Security Lead / AI Security Reviewer]  
> **Date**: [YYYY-MM-DD]  
> **Security Baseline**: Universal Core (Tier 1 Rule 7 & Section 10)  

---

## 1. Scope & Sensitive Assets

* **Assets Handled**: [User passwords, auth tokens, financial transactions, PII (email, address), payment data]
* **External Boundaries Touched**: [Public API endpoints, third-party webhooks, database connections, mobile storage]

---

## 2. Threat Modeling & Vulnerability Verification (OWASP Top 10)

| Vulnerability Category | Risk Level | Evaluation Findings | Status |
| :--- | :---: | :--- | :---: |
| **Broken Object-Level Auth (BOLA/IDOR)** | Critical | Verified `userId` from verified JWT claims matched against target resource ownership. | PASS |
| **Broken Authentication & Session State** | Critical | Single-use rotating refresh tokens; SHA-256 hashed storage; whole-family revocation on reuse. | PASS |
| **Injection (SQL, NoSQL, Command)** | Critical | 100% of queries use parameterized prepared statements; zero dynamic SQL concatenation. | PASS |
| **Security Misconfiguration** | High | CORS restricted to explicit origin; security headers configured (`Content-Security-Policy`, etc.). | PASS |
| **Vulnerable & Outdated Dependencies** | High | `npm audit` / `dependencyCheck` reports 0 high/critical vulnerabilities. | PASS |
| **Identification & Auth Failures** | High | Rate limiting enforced on login/mutation endpoints (full jitter exponential backoff). | PASS |
| **Server-Side Request Forgery (SSRF)** | Medium | Outbound HTTP client validates and restricts target URLs to pre-approved domain allowlists. | PASS |
| **Security Logging & Monitoring Failures** | Medium | Tamper-evident `audit_ledger` records critical mutations; APM logs correlated via W3C trace ID. | PASS |

---

## 3. Data Privacy & PII Handling (GDPR / Regulatory)

- [ ] **Data Minimization**: Only strictly required user fields are collected and stored.
- [ ] **Encryption in Transit**: TLS 1.3 enforced on all public and internal service communications.
- [ ] **Encryption at Rest**: Sensitive columns encrypted; mobile tokens stored in hardware KeyStore.
- [ ] **Log Sanitization**: PII scrubbers intercept passwords, credit cards, and tokens before writing to disk.
- [ ] **Right to Erasure / RTBF**: Design supports anonymizing or deleting user data without breaking foreign keys.

---

## 4. Secret Hygiene Audit

- [ ] Automated git secret scanning step executed against commit history (`git log -p`).
- [ ] Zero `.env` files, private keys (`.pem`, `.key`), or cloud tokens committed to version control.
- [ ] All environment secrets provisioned through secure runtime vaults or CI secrets.

---

## 5. Security Verdict & Recommendations

* **Verdict**: **APPROVED FOR PRODUCTION** / **REJECTED (CRITICAL ISSUES FOUND)**  
* **Remediation Items (if any)**:
  * [Item 1]
