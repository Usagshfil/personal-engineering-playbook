# 07. Threat Modeling: Practical STRIDE for Feature Design

---

## 1. Definition
**Threat Modeling** is a structured engineering process used to identify potential security threats, attack vectors, and vulnerabilities during the design phase of a feature, before a single line of code is written. The industry standard framework is **STRIDE** (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege).

---

## 2. Purpose
Waiting until penetration testing or production release to discover security flaws is exponentially expensive and dangerous. The purpose of threat modeling is to adopt an **attacker's mindset** during SDLC Phase 06 (System Architecture), designing defenses into components before implementation.

---

## 3. Why It Matters
*   **The 5-Minute STRIDE Mental Model**: You do not need a 40-page corporate audit. Asking six simple STRIDE questions during feature planning uncovers 90% of architectural vulnerabilities.
*   **Proactive Defense**: It turns security from an ambiguous anxiety into a concrete checklist of mitigations.

---

## 4. The STRIDE Framework Breakdown

| Threat Category | Attacker Goal | Concrete Mobile/API Example | Standard Mitigation |
| :--- | :--- | :--- | :--- |
| **S - Spoofing** | Pretending to be someone else. | Fake user calls API using a forged user ID. | Cryptographically signed tokens (JWT), biometric passkeys. |
| **T - Tampering** | Modifying data in transit or storage. | Attacker intercepts network call and changes payment amount from $100 to $1. | TLS encryption, HTTPS, digital signatures, integrity checksums. |
| **R - Repudiation** | Denying an action occurred. | User transfers money and claims "I never made that transaction." | Immutable audit logs with timestamps and cryptographically signed receipts. |
| **I - Information Disclosure** | Viewing data without authorization. | SQLite database on rooted phone reveals notes of other users. | EncryptedSharedPreferences, SQLCipher, TLS, zero sensitive logging. |
| **D - Denial of Service** | Crashing or exhausting system resources. | Attacker bombards API with 10,000 rapid requests, freezing server. | Rate limiting, connection timeouts, resource quotas. |
| **E - Elevation of Privilege** | Gaining unauthorized admin permissions. | Regular customer calls `DELETE /api/admin/users/1` and it succeeds. | Role-Based Access Control (RBAC) enforced on the server. |

---

## 5. When to Use It
*   **New Feature Planning**: Whenever designing an authentication flow, payment screen, offline sync engine, or external API integration.
*   **Integrating Third-Party SDKs**: Threat model what access the SDK has to device hardware or user data.

---

## 6. When NOT to Use It (Anti-Complexity Limits)
*   **Purely Cosmetic UI Layout Tweaks**: You do not need to run a STRIDE threat model to change a button color from blue to green or adjust list padding. Focus threat modeling where **data moves, changes, or persists**.

---

## 7. Practical Examples

### Pragmatic 5-Minute STRIDE Template for a Feature
**Feature**: *User Profile Photo Upload*

```markdown
### STRIDE Threat Model: Profile Photo Upload
1. Spoofing: Can User A upload a photo to User B's profile?
   - Mitigation: Server validates JWT userId against target profile ID.
2. Tampering: Can an attacker upload a malicious `.exe` or shell script disguised as a photo?
   - Mitigation: Validate image magic bytes on the server; re-encode image using standard library before saving.
3. Repudiation: Can a user deny uploading an illegal image?
   - Mitigation: Log upload timestamp, userId, and image hash in secure audit log.
4. Information Disclosure: Are private profile photos exposed to public web scrapers?
   - Mitigation: Generate short-lived pre-signed URLs (S3/Cloud Storage) expiring in 15 minutes.
5. Denial of Service: Can an attacker upload a 10GB file to exhaust server memory?
   - Mitigation: Enforce strict 5MB upload limit at reverse proxy (Nginx / Cloudflare).
6. Elevation of Privilege: Can an attacker exploit a buffer overflow in image parsing library?
   - Mitigation: Use modern memory-safe image decoders; run processing in isolated worker container.
```

---

## 8. Common Mistakes
1.  **Treating Threat Modeling as Once-a-Year Compliance**: Doing it once for an audit and never applying it to weekly feature planning.
2.  **Assuming HTTPS Solves Everything**: HTTPS protects data *in transit*, but does nothing to prevent Spoofing, Elevation of Privilege, or Tampering inside the database.
3.  **Ignoring Mobile Client Risks**: Assuming mobile apps are safe environments. Assume mobile devices can be rooted, decompiled, and run under hostile debuggers.

---

## 9. Verification Checklist

- [ ] Has a STRIDE assessment been conducted for new features handling user data or money?
- [ ] Are all six STRIDE categories evaluated with explicit mitigations?
- [ ] Is server-side authorization verified to prevent Elevation of Privilege (IDOR)?
- [ ] Are rate limits and file size caps defined to prevent Denial of Service?
- [ ] Is data protected at rest against Information Disclosure on rooted mobile devices?
