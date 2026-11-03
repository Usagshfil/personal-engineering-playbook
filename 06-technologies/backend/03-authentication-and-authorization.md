# 03. Backend Authentication & Authorization: OAuth 2.0, JWT Architecture & Access Control

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Backend & API Engineering  
> **Target Version**: OAuth 2.1, RFC 7519 (JWT), RFC 8725 (JWT Best Practices), NIST SP 800-63B

---

## 1. Definition & Core Concept

**Backend Security Architecture** distinguishes between **Authentication (AuthN)**—verifying *who* an entity is—and **Authorization (AuthZ)**—verifying *what* an authenticated entity is permitted to do.

Modern services standardize on **OAuth 2.0 / OpenID Connect (OIDC)** for identity federation, **stateless JSON Web Tokens (JWTs)** with short lifespans ($\le 15\text{m}$) for API access, and **Policy-Based Access Control (RBAC / ABAC)** enforcing least privilege at every service boundary.

```
+-------------------------------------------------------------------------+
| Authentication & Authorization Architecture                             |
|                                                                         |
| Client Request: [ Authorization: Bearer <JWT> ]                         |
|    |                                                                    |
|    v                                                                    |
| [ Auth Middleware ] (Authentication - AuthN)                            |
|    |---> Validate Signature against Asymmetric Public Key (RS256)       |
|    |---> Verify Claims: iss (Issuer), aud (Audience), exp (Expiry <=15m) |
|    `---> Reject expired / invalid token with 401 Unauthorized           |
|                                                                         |
| [ Policy Enforcement Guard ] (Authorization - AuthZ)                    |
|    |---> Check Role: Does user possess 'admin' role? (RBAC)             |
|    |---> Check Ownership: Does user own target resource? (BOLA Defense)  |
|    `---> Reject unauthorized access with 403 Forbidden                 |
|                                                                         |
| Controller / Domain Service (Executes authorized business logic)        |
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to prevent **Broken Authentication (OWASP API2)** and **Broken Object Level Authorization (OWASP API1 / BOLA)**, eliminate credential theft risks through short token lifespans, and enforce the Principle of Least Privilege across all API endpoints.

---

## 3. Why It Matters

*   **Mitigating Stolen Token Blast Radius**: Long-lived access tokens (e.g. 30 days) remain valid even if an attacker intercepts them or a user changes their password. Short-lived access tokens ($\le 15\text{m}$) combined with refresh token rotation drastically limit the vulnerability window.
*   **BOLA / IDOR Prevention (OWASP API #1 Vulnerability)**: Verifying that a user is logged in is insufficient; an attacker can simply change `/v1/invoices/100` to `/v1/invoices/101`. Authorization guards must verify that the authenticated caller owns or has explicit permission to access the target entity.
*   **Zero Trust Architecture**: Internal microservices cannot assume requests are trustworthy simply because they originated within the internal network. Requests across service boundaries must carry verified cryptographic identity tokens.
*   **Auditability & Compliance**: Standardized identity claims (`sub`, `tenant_id`, `scope`) ensure all database mutations and security logs can be conclusively traced back to an authorized actor.

---

## 4. When to Use It

### Normative Engineering Rules (RFC 2119)

*   **Token Lifespans & Storage (MUST)**:
    *   Stateless JWT access tokens **MUST** have an expiration (`exp`) $\le 15\text{ minutes}$.
    *   Refresh tokens **MUST** be stored in secure, `HttpOnly`, `SameSite=Strict`, `Secure` cookies (for web clients) or secure OS keystores (for mobile clients).
    *   Refresh token requests **MUST** implement **Refresh Token Rotation (RTR)**: Every time a refresh token is exchanged, the old token is invalidated and a new pair is issued. Re-use of an invalidated refresh token must immediately revoke all tokens in that family.
*   **Cryptographic Signature & Algorithm Pinning (MUST)**:
    *   Services **MUST** enforce explicit algorithm pinning (e.g. `RS256`, `ES256`, or `EdDSA`).
    *   Services **MUST** explicitly reject tokens signed with the `none` algorithm or mismatched symmetric/asymmetric algorithms (preventing algorithm confusion attacks).
    *   Services **MUST** validate `iss` (Issuer), `aud` (Audience), and `nbf` (Not Before) claims.
*   **Object-Level Authorization / BOLA Defense (MUST)**:
    *   Endpoints accessing resources by ID **MUST** verify that the authenticated caller owns the resource or has an authorized organizational tenancy role.
    *   Never query records by client ID alone (`findById(id)`); always include ownership constraints in the database query:
        ```typescript
        // MUST: Query includes tenant/owner boundary
        const invoice = await db.invoice.findFirst({
          where: { id: invoiceId, organizationId: authUser.orgId },
        });
        ```
*   **Role-Based Access Control (RBAC) (SHOULD)**:
    *   Assign permissions hierarchically to roles (`viewer`, `editor`, `admin`).
    *   Protect endpoints using declarative middleware guards (`@Roles('admin')`).
*   **Machine-to-Machine Authentication (SHOULD)**: Use OAuth 2.0 Client Credentials flow with mutual TLS (mTLS) or signed internal service tokens for service-to-service communication.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **Storing Sensitive PII in JWT Claims (AVOID)**: **NEVER** store passwords, credit card numbers, Social Security numbers, or sensitive PII in JWT payloads. JWTs are base64-encoded, not encrypted; anyone with the token can decode its claims.
*   **Storing JWTs in Browser LocalStorage (AVOID)**: Do NOT store access or refresh tokens in `window.localStorage` or `sessionStorage`. Any Cross-Site Scripting (XSS) vulnerability will immediately compromise the token. Use `HttpOnly` cookies.
*   **Bypassing Object Ownership Verification (AVOID)**: Do NOT assume that an authenticated user can access any resource simply because they are logged in.
*   **Hand-Rolled Cryptography (AVOID)**: **NEVER** write custom cryptographic signing, hashing, or token verification logic. Use established, battle-tested libraries (such as `jose`, `jsonwebtoken`, or framework security starters).

---

## 6. Advantages & Disadvantages

| Pattern | Stateless Short-Lived JWT + RTR | Stateful Server Sessions (Redis) |
| :--- | :--- | :--- |
| **Scalability** | Zero database lookups to verify access tokens. | Every API call queries Redis or database session store. |
| **Revocation Speed** | Access token valid until expiry ($\le 15\text{m}$); refresh token revocable instantly. | Instant global revocation for all active sessions. |
| **Architecture Fit** | Excellent for distributed microservices & mobile apps. | Simpler for monolithic web apps with centralized state. |
| **Payload Size** | Larger HTTP headers (500B–1KB per request). | Tiny cookie session identifier (32 bytes). |

---

## 7. Practical Examples

### Bad Example: Weak JWT, Missing Audience, Vulnerable to BOLA & LocalStorage

```typescript
// BAD: 30-day token, no audience/issuer check, vulnerable to BOLA
import jwt from 'jsonwebtoken';

// HAZARD: Hardcoded secret (Tier 1 Violation) & 30-day lifespan!
const JWT_SECRET = 'my_secret_key_123';

export function badLogin(user: any) {
  return jwt.sign(
    { id: user.id, role: user.role, ssn: user.ssn }, // HAZARD: Sensitive SSN in readable JWT!
    JWT_SECRET,
    { expiresIn: '30d' } // HAZARD: 30-day blast radius!
  );
}

// BOLA VULNERABILITY: Broken Object Level Authorization
router.get('/v1/documents/:docId', async (req: Request, res: Response) => {
  const { docId } = req.params;
  // HAZARD: Checks if user is authenticated, but NOT if they own the document!
  // Any logged-in user can read anyone else's sensitive documents!
  const doc = await db.document.findUnique({ where: { id: docId } });
  
  if (!doc) return res.status(404).send();
  res.json(doc);
});
```

### Good Example: Short-Lived JWT, Secure Cookie, Claims Validation & BOLA Defense

```typescript
// GOOD: Asymmetric RS256, 15m expiration, BOLA defense, strict claims validation
import { Request, Response, NextFunction } from 'express';
import * as jose from 'jose';

// 1. Asymmetric Public Key for verification (retrieved from JWKS or environment)
const JWKS = jose.createRemoteJWKSet(
  new URL('https://auth.example.com/.well-known/jwks.json')
);

export interface AuthenticatedUser {
  readonly id: string;
  readonly orgId: string;
  readonly roles: readonly string[];
}

// Extend Express Request
declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

// 2. Authentication Middleware with Strict Claims & Algorithm Pinning
export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({
      type: 'https://api.example.com/errors/unauthorized',
      title: 'Unauthorized',
      status: 401,
      detail: 'Missing or malformed Authorization bearer token.',
    });
  }

  const token = authHeader.substring(7);

  try {
    // Validate signature, issuer, audience, and algorithm
    const { payload } = await jose.jwtVerify(token, JWKS, {
      issuer: 'https://auth.example.com',
      audience: 'https://api.example.com',
      algorithms: ['RS256'], // Strictly pinned algorithm; rejects 'none' and HS256
    });

    req.user = {
      id: String(payload.sub),
      orgId: String(payload.org_id),
      roles: (payload.roles as string[]) ?? [],
    };

    next();
  } catch (error) {
    return res.status(401).json({
      type: 'https://api.example.com/errors/invalid-token',
      title: 'Invalid Token',
      status: 401,
      detail: 'Token is expired, forged, or claims verification failed.',
    });
  }
}

// 3. Protected Route with Strict BOLA Defense
router.get(
  '/v1/documents/:docId',
  requireAuth,
  async (req: Request, res: Response) => {
    const { docId } = req.params;
    const authUser = req.user!;

    // BOLA DEFENSE: Scoping query by tenant/organization ID
    const doc = await db.document.findFirst({
      where: {
        id: docId,
        organizationId: authUser.orgId, // Caller CANNOT read outside their organization
      },
    });

    if (!doc) {
      // Return 404 to avoid leaking existence of documents in other tenants
      return res.status(404).json({
        type: 'https://api.example.com/errors/not-found',
        title: 'Document Not Found',
        status: 404,
        detail: `Document '${docId}' not found.`,
      });
    }

    res.status(200).json(doc);
  }
);
```

---

## 8. Common Mistakes & Pitfalls

1.  **Failing to Verify `aud` (Audience) and `iss` (Issuer)**:
    *   *Problem*: If an authorization server issues tokens for multiple APIs (e.g. Mobile App and Admin Dashboard), omitting audience checks allows an attacker to use a low-privilege Mobile token to access the high-privilege Admin API.
    *   *Remedy*: Always configure `audience: 'https://api.example.com'` in `jwtVerify`.
2.  **Relying Solely on RBAC and Ignoring BOLA**:
    *   *Problem*: Verifying that a user has the role `customer` does not prevent Customer A from modifying Customer B's order.
    *   *Remedy*: Always enforce data tenancy or resource ownership checks on every mutating or detail endpoint.
3.  **Accepting the `none` Signing Algorithm**:
    *   *Problem*: Poorly configured JWT libraries allow attackers to alter the header to `{"alg": "none"}` and strip the signature, completely bypassing authentication.
    *   *Remedy*: Explicitly pin allowed algorithms: `algorithms: ['RS256']`.

---

## 9. Verification Checklist

- [ ] Are stateless access tokens configured with an expiration $\le 15\text{ minutes}$?
- [ ] Are refresh tokens stored in `HttpOnly`, `SameSite=Strict`, `Secure` cookies or secure mobile keystores?
- [ ] Is Refresh Token Rotation (RTR) enforced with automatic family revocation upon reuse?
- [ ] Are JWT algorithms strictly pinned to asymmetric algorithms (`RS256`, `ES256`, `EdDSA`), explicitly rejecting `none`?
- [ ] Are `iss` (Issuer) and `aud` (Audience) claims validated on every incoming request?
- [ ] Does every entity lookup query enforce ownership or tenant boundary constraints (BOLA defense)?
- [ ] Are all sensitive attributes (passwords, credit cards, PII) completely excluded from JWT payloads?
