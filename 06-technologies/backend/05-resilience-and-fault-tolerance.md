# Resilience and Fault Tolerance Standards

> **Level 2 Technology Standard — Backend & APIs**  
> **Applicability**: Mandatory for all backend services, API gateways, microservices, and external client integrations. Adheres to [Universal Core Standards](../../01-principles/README.md) and [System Architecture Standards](../../03-architecture/07-modular-architecture.md).

---

## 1. Definition & Core Concept

**Resilience and Fault Tolerance** is the architectural capability of a backend distributed system to anticipate, absorb, isolate, and gracefully recover from transient network blips, downstream outages, upstream traffic surges, and unexpected resource contention without cascading failure across the platform.

Key resilience building blocks include:
*   **Context-Aware Rate Limiting**: Throttling incoming traffic using token/leaky bucket algorithms. Implemented at the API gateway or via distributed stores (Redis) across multiple dimensions (per-user, per-IP, per-tenant, per-API-key).
*   **Circuit Breakers**: Isolating unstable remote dependencies by transitioning through Closed, Open, and Half-Open states to fail fast instead of consuming threads waiting for unresponsive downstreams.
*   **Retries with Exponential Backoff & Jitter**: Automatically retrying transient failures on safe/idempotent operations with exponential backoff augmented with randomized Full Jitter to eliminate the "thundering herd" problem.
*   **Deterministic Timeouts**: Enforcing strict, bounded deadlines on every downstream HTTP, gRPC, and database connection.
*   **Effectively-Once Idempotency Keys**: Guaranteeing that repeated mutating requests carrying identical `Idempotency-Key` headers produce identical side effects without duplicate processing, supported by payload fingerprinting.

$$\text{Client} \xrightarrow[\text{Idempotency-Key}]{\text{Request}} \underbrace{\text{Rate Limiter}}_{\text{Gateway or Redis}} \longrightarrow \underbrace{\text{Service}}_{\text{Timeout Budget}} \xrightarrow[\text{Closed / Open / Half-Open}]{\text{Circuit Breaker}} \underbrace{\text{Downstream API}}_{\text{Backoff + Jitter}}$$

---

## 2. Purpose

The purpose of these standards is to:
1.  **Prevent Cascading Failures**: Ensure that a latency spike or outage in a non-critical downstream dependency does not consume all worker threads, pool connections, and crash the primary service.
2.  **Safeguard Resource Availability**: Protect backend memory, CPU, and database connection pools from intentional or unintentional denial-of-service traffic spikes.
3.  **Guarantee Effectively-Once Replayability**: Enable clients and network intermediaries to safely retry failed requests without creating duplicate charges, phantom records, or inconsistent mutations.
4.  **Standardize Upstream Feedback**: Provide unambiguous HTTP signaling (`429 Too Many Requests`, `503 Service Unavailable`, `Retry-After`) with standardized headers so consuming clients can pace requests gracefully.

---

## 3. Why It Matters

In distributed systems, network calls over TCP/IP will eventually fail or experience latency degradation:
*   **Thread Starvation**: Without strict network timeouts, a single unresponsive downstream third-party service can tie up all available worker threads within seconds, rendering the entire application unresponsive.
*   **The Thundering Herd (Retry Storm)**: Naive retries with fixed delays cause thousands of clients to retry simultaneously, hitting a recovering service with identical traffic spikes and knocking it back offline.
*   **Financial & Data Corruption**: Without idempotency protections, network timeouts during a payment capture or inventory reservation lead to users double-clicking and getting charged twice.
*   **Noisy Neighbors**: Without distributed rate limiting, a single runaway client or misconfigured script can consume 100% of API capacity, degrading performance for all legitimate users.

---

## 4. When to Use It

### Normative Engineering Rules (RFC 2119)

*   **Rate Limiting Dimensions & Failure Policy (SHOULD)**:
    *   Protect endpoints across multiple dimensions: per-IP for unauthenticated endpoints, per-user/per-tenant for authenticated APIs, and per-client-key for partner APIs.
    *   **Redis Failure Policy**: Services `SHOULD` define an explicit failure posture when the rate-limiting store is unreachable:
        *   *Fail Open* for public read endpoints to maintain availability.
        *   *Fail Closed* for high-risk write endpoints (e.g. login, payment checkout) to prevent abuse during infrastructure degradation.
    *   Small or monolithic services `MAY` rely on API gateway rate limiting without embedding distributed Redis logic inside application services.
*   **Circuit Breakers on Remote Outbound Calls (SHOULD)**:
    *   Wrap remote HTTP/gRPC dependencies in circuit breakers with configured failure thresholds (e.g. 5 consecutive failures or 50% failure rate over 10s) and reset timeouts (e.g. 30s).
    *   In the **Half-Open** state, the circuit allows a single canary probe through; if successful, it closes the circuit; if failed, it re-opens the circuit immediately.
*   **Method Retry Safety & Retry Budgets (MUST)**:
    *   **Safe / Idempotent Methods (GET, HEAD, OPTIONS, PUT, DELETE)**: Safe to retry on transient network errors (`ECONNRESET`, `ETIMEDOUT`) and 503/429 responses.
    *   **Non-Idempotent Methods (POST, PATCH)**: **MUST NOT** be automatically retried unless accompanied by an verified `Idempotency-Key` or database de-duplication constraint.
    *   **Retry Budget**: Enforce a maximum retry budget (e.g. max 3 attempts, max total retry duration $\le 5000\text{ms}$) to prevent unbounded latency accumulation.
*   **Effectively-Once Idempotency Guarantees (MUST)**:
    *   Mutating endpoints (e.g. `POST /v1/orders`, `POST /v1/payments`) **MUST** accept an `Idempotency-Key` header.
    *   **Atomic Acquisition**: The server **MUST** atomically acquire the key (e.g. Redis `SET key in_flight NX EX 60` or SQL `INSERT ... ON CONFLICT DO NOTHING`) before processing.
    *   **Concurrent Request Handling**: If a concurrent request arrives while processing is in flight, the server **MUST** return `409 Conflict` (Problem Details: Request In Progress).
    *   **Payload Fingerprinting (SHA-256)**: The server **MUST** hash the request payload. If an incoming request uses an existing key with a *different* body fingerprint, the server **MUST** reject it with `422 Unprocessable Content` (Problem Details: Idempotency Key Payload Mismatch).
    *   **Durable Persistence & TTL**: After successful execution, the server **MUST** atomically persist the final status code, headers, and response body with an explicit expiration TTL (e.g. 24–72 hours). Subsequent identical requests return the cached response with `X-Cache-Replay: true`.
    *   **Crash Recovery**: The initial lock `MUST` have a short TTL (e.g. 30–60 seconds) so that if a worker crashes before persisting the response, the lock expires rather than remaining permanently jammed.

---

## 5. When NOT to Use It

Engineers `SHOULD NOT` implement resilience patterns when:
*   **In-Process Function Calls**: Applying circuit breakers or retry backoffs to internal, memory-local method invocations introduces massive latency and CPU overhead for zero gain.
*   **Deterministic Client Errors (4xx)**: Never retry client errors (such as `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, or `422 Unprocessable Content`). Retrying bad inputs will never succeed.
*   **Critical Writes without Idempotency Verification**: Never automatically retry non-idempotent mutations without an verified `Idempotency-Key` or database unique constraint.

---

## 6. Advantages & Disadvantages

| Pattern | Advantages | Disadvantages & Trade-offs |
| :--- | :--- | :--- |
| **Distributed Rate Limiting** | Protects services from exhaustion; enforces fair multi-tenant resource sharing. | Requires fast shared state store (Redis); adds network roundtrip to ingress requests. |
| **Circuit Breakers** | Fails fast in sub-milliseconds; relieves failing dependencies; prevents thread pool depletion. | Adds architectural complexity; requires fallback logic or graceful degradation handling. |
| **Exponential Backoff + Jitter** | Smooths out traffic spikes; maximizes recovery probability during transient glitches. | Increases total request latency for retried calls; requires client or proxy coordination. |
| **Idempotency Keys** | Eliminates duplicate transactions and race conditions across network retries. | Requires storing idempotency cache and locking concurrent requests with same key. |

---

## 7. Practical Examples

### Bad Practice: Unbounded Retries, Missing Timeouts, and Non-Idempotent Mutation

```typescript
// BAD: Missing timeouts, naive immediate retry storm, and duplicate charge vulnerability
import axios from 'axios';

export async function chargeCustomer(customerId: string, amount: number) {
  // Trap 1: No timeout specified; call will hang indefinitely if gateway drops packets
  // Trap 2: Naive while loop retries immediately, amplifying pressure on struggling gateway
  let attempts = 0;
  while (attempts < 5) {
    try {
      const response = await axios.post('https://payment-gateway.internal/v1/charges', {
        customerId,
        amount,
        // Trap 3: No Idempotency-Key; if gateway charged customer but connection timed out,
        // the next attempt will charge the customer a second time!
      });
      return response.data;
    } catch (err: any) {
      attempts++;
      // Retrying deterministic 4xx errors or retrying with zero delay!
      if (attempts >= 5) {
        throw new Error('Payment failed after 5 retries: ' + err.message);
      }
    }
  }
}
```

### Good Practice: Robust Client Integration with Circuit Breaker, Jittered Backoff, and Idempotency

```typescript
// GOOD: Production-grade resilience with timeout, exponential backoff + full jitter,
// circuit breaker protection, and Idempotency-Key support

export interface ResilienceConfig {
  timeoutMs: number;
  maxRetries: number;
  baseDelayMs: number;
  maxDelayMs: number;
}

export class CircuitBreakerOpenException extends Error {
  constructor(message = 'Circuit breaker is OPEN. Fast failing.') {
    super(message);
    this.name = 'CircuitBreakerOpenException';
  }
}

export enum CircuitState {
  CLOSED,
  OPEN,
  HALF_OPEN,
}

export class CircuitBreaker {
  private state: CircuitState = CircuitState.CLOSED;
  private failureCount = 0;
  private lastStateChangedAt: number = Date.now();

  constructor(
    private readonly failureThreshold: number = 5,
    private readonly resetTimeoutMs: number = 30000
  ) {}

  public async execute<T>(action: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      if (Date.now() - this.lastStateChangedAt > this.resetTimeoutMs) {
        this.state = CircuitState.HALF_OPEN;
        this.lastStateChangedAt = Date.now();
      } else {
        throw new CircuitBreakerOpenException();
      }
    }

    try {
      const result = await action();
      this.onSuccess();
      return result;
    } catch (error: any) {
      this.onFailure(error);
      throw error;
    }
  }

  private onSuccess(): void {
    this.failureCount = 0;
    this.state = CircuitState.CLOSED;
  }

  private onFailure(error: any): void {
    this.failureCount++;
    if (this.state === CircuitState.HALF_OPEN || this.failureCount >= this.failureThreshold) {
      this.state = CircuitState.OPEN;
      this.lastStateChangedAt = Date.now();
    }
  }
}

// Exponential backoff with Full Jitter: sleep = rand(0, min(maxDelay, baseDelay * 2^attempt))
export async function executeWithRetry<T>(
  operation: (attempt: number) => Promise<T>,
  isRetryable: (error: any) => boolean,
  config: ResilienceConfig
): Promise<T> {
  let attempt = 0;

  while (true) {
    try {
      return await operation(attempt);
    } catch (error: any) {
      attempt++;
      if (attempt > config.maxRetries || !isRetryable(error)) {
        throw error;
      }

      // Calculate exponential backoff
      const exponentialDelay = config.baseDelayMs * Math.pow(2, attempt - 1);
      const cappedDelay = Math.min(config.maxDelayMs, exponentialDelay);
      // Apply Full Jitter: randomize delay uniformly between 0 and cappedDelay
      const jitteredDelay = Math.floor(Math.random() * cappedDelay);

      await new Promise((resolve) => setTimeout(resolve, jitteredDelay));
    }
  }
}

// Payment Service consuming Resilience Engine
export class ResilientPaymentClient {
  private readonly breaker = new CircuitBreaker(5, 30000);

  async chargeCustomer(customerId: string, amount: number, idempotencyKey: string): Promise<any> {
    const config: ResilienceConfig = {
      timeoutMs: 3000,
      maxRetries: 3,
      baseDelayMs: 200,
      maxDelayMs: 2000,
    };

    const isRetryable = (error: any): boolean => {
      // Never retry 4xx errors except 429
      if (error.response?.status) {
        const status = error.response.status;
        if (status === 429) return true; // Rate limited: retry with backoff
        if (status >= 400 && status < 500) return false; // Client errors are non-retryable
        if (status >= 500) return true; // Downstream server errors are retryable
      }
      // Retry network blips, socket hangups, and timeouts
      return error.code === 'ECONNRESET' || error.code === 'ETIMEDOUT';
    };

    return await executeWithRetry(
      async (attempt) => {
        return await this.breaker.execute(async () => {
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), config.timeoutMs);

          try {
            const response = await fetch('https://payment-gateway.internal/v1/charges', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Idempotency-Key': idempotencyKey, // Mandatory for safe retries
              },
              body: JSON.stringify({ customerId, amount }),
              signal: controller.signal,
            });

            if (!response.ok) {
              const error: any = new Error(`Payment gateway returned HTTP ${response.status}`);
              error.response = { status: response.status };
              throw error;
            }

            return await response.json();
          } finally {
            clearTimeout(timeoutId);
          }
        });
      },
      isRetryable,
      config
    );
  }
}
```

---

## 8. Common Mistakes & Pitfalls

### Trap 1: Retrying Non-Idempotent Requests Without Idempotency Protection
*   **The Trap**: Automatically retrying POST or PATCH requests upon receiving a socket timeout or 504 Gateway Timeout without an `Idempotency-Key` or database de-duplication mechanism.
*   **The Consequence**: The original request may have succeeded at the database layer right before the network connection dropped. The retried request executes a second mutation, resulting in double-billing or duplicated resources.
*   **Mitigation**: Mutating endpoints `MUST` enforce unique `Idempotency-Key` headers. When retrying without an idempotency key is requested, clients `MUST` treat timeouts as unverified state and query the resource state before re-executing.

### Trap 2: Constant Delay or Un-Jittered Exponential Retries (Thundering Herd)
*   **The Trap**: Retrying failed calls every 1000ms, or using standard `delay = base * 2^attempt` without random jitter.
*   **The Consequence**: When an external outage resolves, thousands of waiting client processes fire their retries in synchronized pulses, immediately overloading the recovering service and crashing it again.
*   **Mitigation**: Engineers `MUST` employ **Full Jitter**: `delay = random_between(0, min(max_delay, base_delay * 2^attempt))`.

### Trap 3: Infinite or Missing Downstream Timeouts
*   **The Trap**: Relying on default HTTP client configurations (many standard libraries have infinite or 60-second default read timeouts).
*   **The Consequence**: A slow or hanging dependency consumes server connections and thread pools until the host server runs out of memory or sockets.
*   **Mitigation**: Every outbound network call `MUST` have an explicit, bounded timeout (recommended $\le 3000\text{ms}$ for internal microservices, $\le 10000\text{ms}$ for external third parties).

---

## 9. Verification Checklist

- [ ] **Explicit Timeouts**: Every outbound HTTP/gRPC/DB call specifies an explicit timeout budget ($\le 3\text{s}$ internal, $\le 10\text{s}$ external).
- [ ] **Full Jitter Retries**: Retries implement exponential backoff with full randomized jitter to prevent the thundering herd effect.
- [ ] **Selective Retry Filtering**: Client errors (4xx, except 429) are never retried; only transient network errors and 5xx/429 responses are eligible.
- [ ] **Circuit Breakers**: Unstable downstream dependencies are protected by circuit breakers that fail fast during prolonged outages.
- [ ] **Idempotency Protection**: Mutating operations (POST/PATCH) support `Idempotency-Key` headers with distributed cache locks to prevent duplicate executions.
- [ ] **Standard Rate Limit Headers**: Ingress rate limiters return RFC-compliant headers (`RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`, `Retry-After`) on HTTP 429 responses.
