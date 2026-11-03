# 01. RESTful API Design: Resource Modeling, HTTP Semantics & OpenAPI 3.1

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Backend & API Engineering  
> **Target Version**: RFC 9110 (HTTP Semantics), OpenAPI 3.1, JSON Schema 2020-12

---

## 1. Definition & Core Concept

**RESTful API Design** models system capabilities as addressable **resources** identified by Uniform Resource Identifiers (URIs), manipulated through standard **HTTP methods** (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`) defined by **RFC 9110**.

Rather than designing Remote Procedure Call (RPC) endpoints with arbitrary verbs embedded in URLs (`/api/createUser`, `/api/updateOrder`), RESTful architectures treat URIs as nouns representing business entities, utilizing HTTP verbs to declare the intended operation and standard HTTP status codes to communicate execution outcomes.

```
+-------------------------------------------------------------------------+
| RESTful HTTP Method Semantics (RFC 9110)                                |
|                                                                         |
| Method  | Target URI             | Idempotent? | Safe? | Expected Code  |
|---------+------------------------+-------------+-------+----------------|
| GET     | /v1/orders/{id}        | YES         | YES   | 200 OK         |
| POST    | /v1/orders             | NO          | NO    | 201 Created    |
| PUT     | /v1/orders/{id}        | YES         | NO    | 200 / 204      |
| PATCH   | /v1/orders/{id}        | NO          | NO    | 200 OK         |
| DELETE  | /v1/orders/{id}        | YES         | NO    | 204 No Content |
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to guarantee predictable, interoperable, backward-compatible, and self-describing HTTP APIs across all frontend, mobile, and third-party consumers while eliminating ad-hoc RPC verb proliferation and ambiguous status code usage.

---

## 3. Why It Matters

*   **Idempotency & Network Retries**: Mobile and web clients operate over unreliable cellular connections. When a request drops, a client can safely retry an idempotent method (`PUT`, `DELETE`, `GET`) without risking duplicate transactions. Understanding method idempotency prevents double-charging and duplicate records.
*   **Predictable Client Integration**: Clients can rely on standardized HTTP status codes (e.g. `401 Unauthorized` for missing credentials vs. `403 Forbidden` for insufficient permissions) to drive UI authorization states automatically.
*   **Interoperable Tooling & SDK Generation**: Adhering to OpenAPI 3.1 contracts enables automated generation of type-safe TypeScript/Kotlin client SDKs, mock servers, and interactive documentation (Scalar / Swagger UI).
*   **Cacheability**: Strict adherence to `GET` semantics allows CDNs and reverse proxies (Cloudflare, Fastly, Nginx) to cache public read responses effortlessly, drastically reducing database load.

---

## 4. When to Use It

### Normative Engineering Rules (RFC 2119)

*   **Resource Naming Conventions (MUST)**:
    *   URIs **MUST** use plural nouns representing resources, never verbs: `/v1/users`, `/v1/invoices`, `/v1/subscriptions`.
    *   URIs **MUST** use kebab-case for multi-word paths: `/v1/user-profiles`, `/v1/payment-methods`.
    *   Nesting depth **MUST NOT** exceed 2 levels: `/v1/authors/{authorId}/books` is acceptable; `/v1/authors/{authorId}/books/{bookId}/chapters/{chapterId}/paragraphs` is strictly prohibited. For deeply nested entities, use top-level collections with query filters: `/v1/chapters?bookId={bookId}`.
*   **HTTP Method Discipline (MUST)**:
    *   `GET`: Safe and idempotent. **MUST NOT** alter persistent server state.
    *   `POST`: Non-idempotent creation or processing. **MUST** return `201 Created` with a `Location: /v1/orders/{id}` header upon successful creation.
    *   `PUT`: Idempotent full replacement. Overwrites the target resource entirely.
    *   `PATCH`: Non-idempotent partial modification. Modifies only specified attributes.
    *   `DELETE`: Idempotent removal. **MUST** return `204 No Content` upon successful deletion.
*   **Status Code Semantics (MUST)**:
    *   `200 OK`: Successful read or update with response body.
    *   `201 Created`: Resource successfully created (with `Location` header).
    *   `204 No Content`: Successful request returning no response body (e.g. `DELETE`).
    *   `400 Bad Request`: Generic malformed syntax or unparseable JSON.
    *   `401 Unauthorized`: Authentication missing or invalid.
    *   `403 Forbidden`: Authenticated caller lacks permissions for this resource.
    *   `404 Not Found`: Target resource does not exist.
    *   `409 Conflict`: Request violates business rule (e.g. unique email collision, state conflict).
    *   `422 Unprocessable Content`: Syntactically valid JSON that fails domain validation.
    *   `429 Too Many Requests`: Rate limit threshold exceeded.
    *   `500 Internal Server Error`: Unhandled server-side exception.
*   **Pagination Standards (SHOULD)**:
    *   Use **Cursor-Based Pagination** for large or rapidly shifting datasets (e.g. feeds, audit logs): `?limit=25&starting_after=order_xyz`.
    *   Use **Offset Pagination** (`?page=1&per_page=20`) only for small, static datasets with total page count requirements.
*   **Contract-First OpenAPI 3.1 (SHOULD)**: Define the API contract in OpenAPI 3.1 before implementing service logic, ensuring frontend and backend teams can develop in parallel against mock servers.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **Verbs in URIs (AVOID)**: **NEVER** create RPC-style verb URIs such as `/api/v1/deleteUser`, `/api/v1/getOrders`, or `/api/v1/saveProduct`. Use standard HTTP verbs (`DELETE /v1/users/{id}`).
*   **Tunneling Everything via POST (AVOID)**: Do NOT use `POST` for safe queries that should be `GET`, or for deletions that should be `DELETE`.
*   **200 OK with Error Payloads (AVOID)**: **NEVER** return `HTTP 200 OK` with a response body containing `{ "success": false, "error": "Unauthorized" }`. Returning 200 for failures breaks proxies, API gateways, monitoring alerts, and client HTTP libraries.
*   **Leaking Database Auto-Increment IDs (AVOID)**: Do NOT expose internal serial integers (`/v1/users/1`) in public URLs. Expose random, unguessable identifiers (UUIDv4, UUIDv7, or Nanoid) to prevent enumeration attacks (BOLA / IDOR).

---

## 6. Advantages & Disadvantages

| Pattern | RESTful Design (RFC 9110) | Ad-Hoc RPC / Verb-Based API |
| :--- | :--- | :--- |
| **Tooling & Standards** | Supported natively by all browsers, CDNs, proxies, and API gateways. | Requires custom client wrappers and manual error parsing. |
| **Cacheability** | Native HTTP caching via `Cache-Control` and `ETag`. | Uncacheable without bespoke application-level caching. |
| **Idempotency** | Explicit idempotency semantics built into HTTP protocol. | Unknown retry safety; prone to duplicate charges on disconnect. |
| **Operation Fit** | Ideal for CRUD and entity lifecycle operations. | More natural for pure non-resource actions (e.g. `/calculateTax`). |

---

## 7. Practical Examples

### Bad Example: RPC Verbs in URLs, 200 OK for Errors & Deep Nesting

```typescript
// BAD: Verbs in URI, returning 200 OK for failures, deep nesting, integer ID leak
import express from 'express';
const router = express.Router();

// HAZARD: Verb in URI, exposing internal database primary key (IDOR risk)
router.post('/api/deleteCustomerAccount', async (req, res) => {
  const { customerId } = req.body; // e.g. customerId: 42
  
  const user = await db.findUser(customerId);
  if (!user) {
    // HAZARD: Returns HTTP 200 OK for an error! Breaks client error handling and APM monitors.
    return res.status(200).json({
      success: false,
      message: 'Customer not found',
    });
  }

  await db.deleteUser(customerId);
  res.status(200).json({ success: true });
});

// HAZARD: Deeply nested URI sprawl (4 levels deep)
router.get('/api/companies/:cid/departments/:did/teams/:tid/members/:mid', (req, res) => {
  // Complex routing, fragile parameters
});
```

### Good Example: Clean RESTful Nouns, Correct HTTP Semantics & RFC Status Codes

```typescript
// GOOD: Clean resource URIs, correct HTTP verbs, accurate status codes, UUIDs
import express, { Request, Response } from 'express';
const router = express.Router();

// GET /v1/customers/:customerId - Safe, idempotent read
router.get('/v1/customers/:customerId', async (req: Request, res: Response) => {
  const { customerId } = req.params; // UUID string
  const customer = await customerService.findById(customerId);

  if (!customer) {
    return res.status(404).json({
      type: 'https://api.example.com/errors/not-found',
      title: 'Resource Not Found',
      status: 404,
      detail: `Customer with ID '${customerId}' was not found.`,
      instance: req.originalUrl,
    });
  }

  res.status(200).json(customer);
});

// POST /v1/customers - Non-idempotent resource creation
router.post('/v1/customers', async (req: Request, res: Response) => {
  const newCustomer = await customerService.create(req.body);

  // Return 201 Created with standard Location header pointing to the new resource
  res
    .status(201)
    .location(`/v1/customers/${newCustomer.id}`)
    .json(newCustomer);
});

// DELETE /v1/customers/:customerId - Idempotent deletion
router.delete('/v1/customers/:customerId', async (req: Request, res: Response) => {
  const { customerId } = req.params;
  await customerService.delete(customerId);

  // Return 204 No Content: Operation succeeded, zero payload body
  res.status(204).send();
});

// Flat query filtering instead of deep URI nesting:
// GET /v1/team-members?companyId={cid}&departmentId={did}
router.get('/v1/team-members', async (req: Request, res: Response) => {
  const { companyId, departmentId, limit = '20', startingAfter } = req.query;
  const members = await memberService.list({
    companyId: String(companyId),
    departmentId: String(departmentId),
    limit: parseInt(String(limit), 10),
    startingAfter: startingAfter ? String(startingAfter) : undefined,
  });

  res.status(200).json(members);
});
```

---

## 8. Common Mistakes & Pitfalls

1.  **Returning HTTP 200 with `{ "error": ... }`**:
    *   *Problem*: API gateways, reverse proxies, and client monitoring tools (Datadog, New Relic) count all 200 responses as successful transactions, blinding operations teams to massive authentication or database outages.
    *   *Remedy*: Always use the appropriate 4xx or 5xx HTTP status code defined in RFC 9110.
2.  **Exposing Mutable Non-Resource Verbs**:
    *   *Problem*: When an action does not map cleanly to standard CRUD (e.g. canceling an order, calculating sales tax), developers often resort to unstructured endpoints like `/v1/cancelOrder`.
    *   *Remedy*: Model the action as a sub-resource or state transition: `POST /v1/orders/{id}/cancellation` or `PATCH /v1/orders/{id}` with `{ "status": "canceled" }`.
3.  **Unbounded Database Queries (Missing Pagination)**:
    *   *Problem*: Endpoints like `GET /v1/orders` without pagination will crash the backend process with an Out of Memory (OOM) error as soon as customer records reach tens of thousands.
    *   *Remedy*: Enforce default pagination limits (`limit=25`, max `100`) on every collection endpoint.

---

## 9. Verification Checklist

- [ ] Are all URIs structured using lowercase plural nouns and kebab-case without embedded action verbs?
- [ ] Are URI nesting depths limited to a maximum of 2 levels, using query filters for deeper relationships?
- [ ] Does `GET` remain strictly safe and idempotent without modifying persistent server state?
- [ ] Does `POST` return `HTTP 201 Created` with a valid `Location` header upon successful resource creation?
- [ ] Does `DELETE` return `HTTP 204 No Content` upon successful resource deletion?
- [ ] Are error responses returned with appropriate 4xx/5xx status codes (never 200 OK with error body)?
- [ ] Are public resource identifiers non-sequential and unguessable (UUIDs or Nanoids)?
- [ ] Do all collection endpoints enforce mandatory pagination with sensible default and maximum limits?
