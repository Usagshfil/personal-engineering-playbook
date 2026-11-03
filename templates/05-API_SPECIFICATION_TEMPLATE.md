# API Specification: [Service / Resource Name]

> **API Version**: v1  
> **Base URL**: `https://api.example.com/api/v1`  
> **Protocol**: HTTPS (TLS 1.3 mandatory)  
> **Data Format**: `application/json` (Requests) / `application/json` or `application/problem+json` (Responses)  

---

## 1. Global Conventions & Standards

1. **Authentication**: All private endpoints require `Authorization: Bearer <access_token>`.
2. **Idempotency**: All mutating `POST` and `PATCH` requests require an `Idempotency-Key: <UUIDv7>` header.
3. **Deadline Propagation**: Clients send `X-Request-Timeout-Ms: <milliseconds>` or `X-Request-Deadline: <UTC ISO-8601>`.
4. **Error Format**: All errors adhere to **RFC 9457 Problem Details** (`application/problem+json`).
5. **Pagination**: List endpoints use cursor-based pagination via query parameters `limit` (max 100) and `cursor`.

---

## 2. Endpoints Catalog

### 2.1 Create Resource: `POST /[resources]`

#### Request Headers
| Header | Required | Format / Example | Description |
| :--- | :---: | :--- | :--- |
| `Authorization` | Yes | `Bearer eyJhbGci...` | Valid user access token |
| `Idempotency-Key`| Yes | `018d4e9f-7c1a-7b3c-8a2e-123456789abc` | UUIDv7 for effectively-once execution |
| `X-Request-Timeout-Ms` | Optional | `4000` | Remaining deadline budget |

#### Request Body
```json
{
  "name": "Production Resource",
  "category": "HARDWARE",
  "amountCents": 2500,
  "currency": "USD"
}
```

#### Response: `201 Created`
```json
{
  "id": "018d4e9f-8a2e-7b3c-9f1a-abcdef012345",
  "name": "Production Resource",
  "category": "HARDWARE",
  "amountCents": 2500,
  "currency": "USD",
  "status": "ACTIVE",
  "createdAt": "2026-11-03T14:30:00.000Z"
}
```

#### Error Responses
* **`400 Bad Request`** (Missing Idempotency-Key):
  ```json
  {
    "type": "https://api.example.com/errors/missing-idempotency-key",
    "title": "Bad Request",
    "status": 400,
    "detail": "Mutating POST requests require an Idempotency-Key header.",
    "instance": "/api/v1/resources"
  }
  ```
* **`422 Unprocessable Content`** (Schema validation failure):
  ```json
  {
    "type": "https://api.example.com/errors/validation-failed",
    "title": "Unprocessable Content",
    "status": 422,
    "detail": "The payload contains validation errors.",
    "instance": "/api/v1/resources",
    "invalidParams": [
      { "name": "amountCents", "reason": "amountCents must be a positive integer" }
    ]
  }
  ```
* **`409 Conflict`** (Concurrent in-flight request with same idempotency key):
  ```json
  {
    "type": "https://api.example.com/errors/concurrent-mutation",
    "title": "Conflict",
    "status": 409,
    "detail": "A mutation with this Idempotency-Key is currently being processed.",
    "instance": "/api/v1/resources"
  }
  ```

---

### 2.2 List Resources: `GET /[resources]`

#### Query Parameters
| Parameter | Type | Required | Default | Description |
| :--- | :---: | :---: | :---: | :--- |
| `limit` | integer | No | 20 | Number of items to return (max 100) |
| `cursor` | string | No | null | Opaque base64 cursor from previous page |
| `status` | string | No | null | Filter by status (`ACTIVE`, `ARCHIVED`) |

#### Response: `200 OK`
```json
{
  "items": [
    {
      "id": "018d4e9f-8a2e-7b3c-9f1a-abcdef012345",
      "name": "Production Resource",
      "status": "ACTIVE"
    }
  ],
  "pageInfo": {
    "hasMore": true,
    "nextCursor": "ZXlKaGJHY2lPaUpTVXpVeE5pSXNJbl..."
  }
}
```
