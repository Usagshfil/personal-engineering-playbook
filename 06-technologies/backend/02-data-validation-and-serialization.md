# 02. Data Validation & Serialization: Schema Enforcement, DTOs & Mass Assignment Defense

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Backend & API Engineering  
> **Target Version**: OpenAPI 3.1, Zod 3.23+ / Pydantic 2+ / Go Validator v10+

---

## 1. Definition & Core Concept

**Backend Data Validation & Serialization** establishes a cryptographic and structural boundary at the perimeter of the service. All incoming payloads (JSON bodies, query parameters, route parameters, headers) are validated against strict **runtime schemas** before reaching internal domain services.

Outgoing responses are explicitly filtered and mapped through dedicated **Response Data Transfer Objects (DTOs)**, ensuring internal database schemas, password hashes, foreign keys, and private metadata are never leaked into API payloads.

```
+-------------------------------------------------------------------------+
| Boundary Validation & Serialization Architecture                        |
|                                                                         |
| Untrusted Client Input (JSON)                                           |
|    |                                                                    |
|    v                                                                    |
| [ Schema Validator ] (Zod / Pydantic / Bean Validation)                 |
|    |---> Valid: Cast into Strongly-Typed Request DTO                    |
|    `---> Invalid: Return 422 Unprocessable Content (RFC 9457)          |
|                                                                         |
| Domain Service & Business Logic (Consumes Pure DTO)                     |
|                                                                         |
| Database Entity (Contains internal IDs, password hashes, audit logs)    |
|    |                                                                    |
|    v                                                                    |
| [ Response Serializer / DTO Mapper ] (Explicit field allow-list)        |
|    |                                                                    |
|    v                                                                    |
| Sanitized JSON Response Payload (Zero sensitive leak)                   |
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to prevent **Mass Assignment (OWASP API6)** vulnerabilities, eliminate SQL/NoSQL injection attacks at system boundaries, ensure strict type safety across business logic, and prevent the accidental disclosure of sensitive credentials and PII.

---

## 3. Why It Matters

*   **Mass Assignment Protection (Tier 1 Rule 7)**: If an API blindly passes `req.body` to an ORM model (`User.create(req.body)`), an attacker can inject `{ "isAdmin": true, "verified": true }` to elevate privileges. Explicit Request DTOs strictly allow-list permitted attributes.
*   **Fail-Fast Defensive Perimeter**: Rejecting malformed input at the controller layer guarantees that domain services, database drivers, and external microservices receive only sanitized, well-formed data models.
*   **Internal Decoupling**: Database schema changes (renaming columns, normalizing tables) should not inadvertently alter public API contracts. DTO mappers act as an architectural buffer between database entities and public contracts.
*   **PII & Credential Scrubbing**: Using explicit response DTOs guarantees that sensitive fields (e.g. `password_hash`, `two_factor_secret`, `stripe_customer_id`) cannot be leaked by accidentally serializing an entire database row.

---

## 4. When to Use It

### Normative Engineering Rules (RFC 2119)

*   **Boundary Validation at Entry Points (MUST)**: Every controller or route handler **MUST** validate all external inputs (body, query params, headers) against a formal schema before executing any business logic.
*   **Separation of DTOs and Database Entities (MUST)**: Developers **MUST NOT** pass raw request bodies directly to database models or ORM save methods. Developers **MUST** define separate Request DTOs and Response DTOs.
*   **Explicit Response Filtering (MUST)**: Outgoing response serialization **MUST** use an explicit allow-list of properties. Banning fields via deny-lists (`delete user.password`) is strictly prohibited, as future schema additions will leak by default.
*   **Standardized Validation Error Format (MUST)**: When validation fails, the service **MUST** return `HTTP 422 Unprocessable Content` (or `400 Bad Request`) with an RFC 9457 Problem Details payload detailing the exact field-level errors:
    ```json
    {
      "type": "https://api.example.com/errors/validation-failed",
      "title": "Validation Failed",
      "status": 422,
      "detail": "The request payload failed structural validation.",
      "invalidParams": [
        { "name": "email", "reason": "Must be a valid email address" },
        { "name": "age", "reason": "Must be at least 18" }
      ]
    }
    ```
*   **Strict Unknown Property Rejection (SHOULD)**: Schemas **SHOULD** strip or reject unrecognized properties (`strip()` or `strict()` in Zod) to catch client typos and reject unexpected injection attempts.
*   **Content-Type Enforcement (SHOULD)**: Endpoints consuming payloads **SHOULD** verify that `Content-Type: application/json` is supplied, returning `415 Unsupported Media Type` if missing or invalid.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **Blind `req.body` Forwarding (AVOID)**: **NEVER** write `await db.user.create({ data: req.body })` or `repository.save(entity)`. This is a critical security vulnerability.
*   **Deny-List Sanitization (AVOID)**: Do NOT sanitize responses using field deletion (`delete user.password_hash`). If another developer adds `creditCardCvv` to the database model tomorrow, it will automatically leak to users.
*   **Over-Validating Internal Layer Boundaries**: Do not re-validate schemas across every internal private method. Validate rigorously at the public system boundary (controllers, message queue consumers); internal services should rely on static types.
*   **Regex Super-Complexity**: Avoid giant, unreadable regular expressions for complex validation (e.g. 500-character RFC 5322 email regexes). Use standard, maintained validation libraries.

---

## 6. Advantages & Disadvantages

| Pattern | Explicit Schema Validation & DTOs | Ad-Hoc / Raw Input Passing |
| :--- | :--- | :--- |
| **Security Posture** | Immune to Mass Assignment and field leakage. | Vulnerable to privilege escalation (OWASP API6). |
| **Type Safety** | Types statically inferred from schemas. | Untyped `any` or loose interfaces prone to drift. |
| **Error Clarity** | Automated, precise field-level error messages. | Vague 500 crashes or cryptic database constraints. |
| **Initial Code Overhead**| Requires defining DTO interfaces and schemas. | Faster initial scaffolding; catastrophic security debt. |

---

## 7. Practical Examples

### Bad Example: Mass Assignment, Leaked Secrets & Missing Validation

```typescript
// BAD: Blindly trusting req.body, mass assignment vulnerability, leaking password hash
import express, { Request, Response } from 'express';
const router = express.Router();

router.post('/v1/users', async (req: Request, res: Response) => {
  // HAZARD 1: No schema validation; crashes if required fields are missing
  // HAZARD 2: Mass Assignment! Attacker sends { "role": "admin", "isVerified": true }
  const newUser = await prisma.user.create({
    data: req.body, 
  });

  // HAZARD 3: Leaking entire database row! Returns password_hash and internal tokens to client!
  res.status(201).json(newUser);
});
```

### Good Example: Strict Zod Schema Validation, Mass Assignment Defense & DTO Mapping

```typescript
// GOOD: Schema validation, explicit Request DTO, explicit Response DTO
import express, { Request, Response } from 'express';
import { z } from 'zod';

const router = express.Router();

// 1. Strict Request Schema (Allow-list only permitted input attributes)
export const CreateUserRequestSchema = z.object({
  email: z.string().email('Valid email address required'),
  fullName: z.string().min(2, 'Name must be at least 2 characters').max(100),
  password: z
    .string()
    .min(12, 'Password must be at least 12 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),
}).strict(); // Rejects any extra injected fields (e.g. role, isAdmin)

export type CreateUserRequest = z.infer<typeof CreateUserRequestSchema>;

// 2. Explicit Response DTO (Allow-list only safe public attributes)
export interface UserResponseDto {
  readonly id: string;
  readonly email: string;
  readonly fullName: string;
  readonly createdAt: string;
}

export function toUserResponseDto(user: any): UserResponseDto {
  return {
    id: user.id,
    email: user.email,
    fullName: user.fullName,
    createdAt: user.createdAt.toISOString(),
  };
}

// 3. Controller with Boundary Validation & Sanitization
router.post('/v1/users', async (req: Request, res: Response) => {
  // Boundary Validation: Safe parse fails fast without crashing
  const validationResult = CreateUserRequestSchema.safeParse(req.body);

  if (!validationResult.success) {
    return res.status(422).json({
      type: 'https://api.example.com/errors/validation-failed',
      title: 'Validation Failed',
      status: 422,
      detail: 'The payload contains invalid or missing fields.',
      instance: req.originalUrl,
      invalidParams: validationResult.error.issues.map((issue) => ({
        name: issue.path.join('.'),
        reason: issue.message,
      })),
    });
  }

  const validatedData: CreateUserRequest = validationResult.data;

  // Pass only validated, sanitized fields to domain service
  const user = await userService.registerUser({
    email: validatedData.email,
    fullName: validatedData.fullName,
    plainPassword: validatedData.password,
  });

  // Explicitly map to safe public DTO before responding
  res.status(201).json(toUserResponseDto(user));
});
```

---

## 8. Common Mistakes & Pitfalls

1.  **Deny-List Serialization (`delete user.password`)**:
    *   *Problem*: Removing fields manually (`delete user.passwordHash`) fails whenever new private columns (e.g., `totpSecret`, `billingId`) are added to the database model, exposing them immediately.
    *   *Remedy*: Always use an allow-list DTO mapper (`return { id: user.id, email: user.email }`).
2.  **Validating Input After Performing Expensive Queries**:
    *   *Problem*: Checking database records or allocating resources before validating input types allows attackers to trigger denial-of-service (DoS) via malformed inputs.
    *   *Remedy*: Parse and validate inputs synchronously at the very top of the controller handler before executing any asynchronous I/O.
3.  **Returning Raw Framework/Database Errors in 400 Responses**:
    *   *Problem*: Directly returning `error.message` from PostgreSQL or MongoDB leaks table names, column constraints, database versions, and SQL syntax to callers.
    *   *Remedy*: Catch database errors in the service/repository layer and map them to clean, generic domain error messages.

---

## 9. Verification Checklist

- [ ] Does every controller handler validate request bodies, query params, and route parameters against a formal schema?
- [ ] Is `req.body` forbidden from being passed directly to ORM `.create()` or `.save()` methods?
- [ ] Are Request DTOs and Database Entities strictly decoupled into distinct classes or interfaces?
- [ ] Does response serialization use an explicit allow-list mapper (never delete/deny-lists)?
- [ ] Are password hashes, refresh tokens, and internal audit fields completely absent from public JSON responses?
- [ ] Does validation failure return `HTTP 422` with RFC 9457 structured field-level error messages?
- [ ] Does the schema validator strip or reject unknown parameters (`.strict()`) to block parameter injection?
