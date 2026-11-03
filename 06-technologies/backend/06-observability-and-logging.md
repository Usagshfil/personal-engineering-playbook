# Observability and Logging Standards

> **Level 2 Technology Standard — Backend & APIs**  
> **Applicability**: Mandatory for all backend microservices, monoliths, background workers, and API gateways. Adheres to [Universal Core Standards](../../01-principles/README.md), [Clean Architecture](../../03-architecture/02-clean-architecture.md), and [Security & Privacy Standards](../../10-security-and-privacy/06-secure-logging-and-telemetry.md).

---

## 1. Definition & Core Concept

**Observability** is the degree to which the internal execution state of a distributed backend system can be inferred solely by examining its external telemetry outputs. It is comprised of three core pillars:
*   **Structured JSON Logging**: Emitting human-readable and machine-indexable log events in canonical JSON format, annotated with correlation identifiers (`trace_id`, `span_id`), service identity, and contextual metadata.
*   **Distributed Tracing**: Tracking a single user request across multiple microservices, message queues, and databases using the **W3C Trace Context** standard (`traceparent` header).
*   **Metrics (RED Method)**: Aggregating numerical telemetry quantifying **R**ate (requests per second), **E**rrors (fraction of failing requests), and **D**uration (latency distribution across p50, p95, and p99 percentiles).
*   **Health Checks**: Distinct HTTP probes for **Liveness** (`/healthz` - is the runtime process alive?) and **Readiness** (`/readyz` - are database connections and caches warmed up to accept traffic?).

$$\text{Request Ingress} \xrightarrow[\text{W3C traceparent}]{\text{trace\_id}} \left[ \begin{array}{l} \text{Structured JSON Logs (with trace\_id)} \\ \text{RED Metrics (Rate, Errors, Duration)} \\ \text{Span Context Propagation} \end{array} \right] \longrightarrow \text{OpenTelemetry Collector}$$

---

## 2. Purpose

The purpose of these standards is to:
1.  **Reduce Mean Time to Resolution (MTTR)**: Allow on-call engineers to correlate an alert on a 99th percentile latency spike to the exact distributed trace, culprit database query, or error log within seconds.
2.  **Enforce Privacy & Security by Default**: Ensure strict adherence to [Tier 1 Universal Rule 7](../../AGENTS.md) by automatically masking passwords, authorization tokens, credit cards, and personally identifiable information (PII) before logs are written to disk or shipped off-host.
3.  **Standardize Telemetry Across Languages**: Establish consistent JSON schemas and metric names whether a service is written in TypeScript, Go, Kotlin, or Python.
4.  **Facilitate Zero-Downtime Orchestration**: Provide accurate liveness and readiness signals to container orchestrators (Kubernetes, AWS ECS) during rollouts and pod restarts.

---

## 3. Why It Matters

Unstructured text logging and absent telemetry cause catastrophic operational paralysis:
*   **Unstructured Log Blobs**: Unformatted `console.log("Error occurred: " + err)` statements cannot be filtered, parsed, or alerted upon in log aggregation platforms (Datadog, Elasticsearch, CloudWatch).
*   **Context Loss in Asynchronous Code**: When hundreds of requests execute concurrently, interleaved unstructured logs make it impossible to reconstruct the chronological sequence of a single user request.
*   **Security Breaches via Log Leaks**: Unfiltered logging of request payloads or auth headers routinely exposes raw passwords, JWTs, and session cookies in cleartext to log indices, violating GDPR, HIPAA, and PCI-DSS.
*   **Orchestration Blind Spots**: Missing or misconfigured readiness probes cause Kubernetes to route production traffic to booting pods before database connection pools are established, causing burst error spikes during deployments.

---

## 4. When to Use It

Engineers `MUST` enforce these observability standards across:
*   All production HTTP APIs, RPC endpoints, and background worker jobs.
*   Every inter-service communication boundary (propagating `traceparent` headers).
*   All error handling pipelines and unhandled exception filters.
*   Container deployment manifests and ingress gateways.

---

## 5. When NOT to Use It

Engineers `SHOULD NOT`:
*   **Log High-Frequency In-Memory Loops**: Emitting logs inside inner tight loops processing millions of records in memory exhausts CPU, inflates log storage costs, and degrades throughput.
*   **Duplicate Spans for Trivial Method Calls**: Creating OpenTelemetry spans for every getter, setter, or one-line helper clutters trace waterfalls with low-value noise. Reserve spans for I/O operations, network boundaries, and significant domain workflows.
*   **Expose Internal Health Diagnostics to Public Clients**: Readiness details containing internal database connection strings, cluster topologies, or dependency versions `MUST NEVER` be publicly exposed.

---

## 6. Advantages & Disadvantages

| Pillar | Advantages | Disadvantages & Trade-offs |
| :--- | :--- | :--- |
| **Structured JSON Logging** | High queryability; easy aggregation and indexing; enables automated alerting on structured fields. | Consumes more disk/bandwidth bytes than raw strings; requires disciplined logger schemas. |
| **Distributed Tracing** | Pinpoints exact latency bottlenecks across microservices; eliminates finger-pointing between teams. | Requires context propagation boilerplate; minor header transmission overhead. |
| **RED Metrics** | High-level operational dashboarding; cheap long-term retention; lightweight alert triggers. | High-cardinality labels (e.g. user IDs in metric tags) can explode metrics database memory. |
| **PII Scrubbing** | Guarantees compliance; prevents credential leakage into shared monitoring tools. | Minor CPU sanitization overhead during log formatting; requires ongoing maintenance of regex patterns. |

---

## 7. Practical Examples

### Bad Practice: Unstructured Logging, Missing Correlation, and PII/Token Leakage

```typescript
// BAD: Unstructured logs, missing trace ID, and blatant credential leakage
import express from 'express';

const app = express();
app.use(express.json());

app.post('/api/v1/auth/login', async (req, res) => {
  // Trap 1: console.log without JSON structure or correlation ID
  console.log('Login attempt received');

  // Trap 2: Logging complete request body including cleartext password and email!
  console.log('Request body:', req.body); 

  try {
    const user = await authenticate(req.body.email, req.body.password);
    const token = generateToken(user);

    // Trap 3: Logging sensitive bearer token
    console.log('User logged in successfully, token:', token);
    res.json({ token });
  } catch (err: any) {
    // Trap 4: String concatenation loses error stack and structured properties
    console.log('Login failed: ' + err.message);
    res.status(401).json({ error: 'Auth failed' });
  }
});
```

### Good Practice: Structured JSON Logging, W3C Trace Correlation, PII Sanitization, and RED Health Checks

```typescript
// GOOD: Production-ready structured logging, automated PII scrubbing,
// W3C trace propagation, and robust health endpoints

import express, { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';

// 1. PII and Credential Redaction Masker
const SENSITIVE_KEYS = new Set([
  'password',
  'token',
  'authorization',
  'secret',
  'creditcard',
  'cvv',
  'ssn',
  'api_key',
  'apikey',
]);

export function sanitizeMetadata(data: any): any {
  if (data === null || data === undefined) return data;
  if (typeof data !== 'object') return data;
  if (Array.isArray(data)) return data.map(sanitizeMetadata);

  const sanitized: Record<string, any> = {};
  for (const [key, value] of Object.entries(data)) {
    if (SENSITIVE_KEYS.has(key.toLowerCase())) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof value === 'object') {
      sanitized[key] = sanitizeMetadata(value);
    } else {
      sanitized[key] = value;
    }
  }
  return sanitized;
}

// 2. Structured JSON Logger
export interface LogEntry {
  timestamp: string;
  level: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';
  service: string;
  message: string;
  trace_id?: string;
  span_id?: string;
  context?: Record<string, any>;
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
}

export class JsonLogger {
  constructor(private readonly serviceName: string) {}

  public log(
    level: LogEntry['level'],
    message: string,
    meta?: { trace_id?: string; span_id?: string; context?: Record<string, any>; error?: Error }
  ): void {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      service: this.serviceName,
      message,
      trace_id: meta?.trace_id,
      span_id: meta?.span_id,
      context: meta?.context ? sanitizeMetadata(meta.context) : undefined,
      error: meta?.error
        ? {
            name: meta.error.name,
            message: meta.error.message,
            stack: process.env.NODE_ENV === 'production' ? undefined : meta.error.stack,
          }
        : undefined,
    };

    const serialized = JSON.stringify(entry);
    if (level === 'ERROR') {
      process.stderr.write(serialized + '\n');
    } else {
      process.stdout.write(serialized + '\n');
    }
  }

  info(msg: string, meta?: any) { this.log('INFO', msg, meta); }
  warn(msg: string, meta?: any) { this.log('WARN', msg, meta); }
  error(msg: string, meta?: any) { this.log('ERROR', msg, meta); }
}

const logger = new JsonLogger('payment-service');

// 3. W3C Trace Context and Request Logging Middleware
export function traceAndLogMiddleware(req: Request, res: Response, next: NextFunction): void {
  // Parse W3C traceparent (format: 00-traceid-spanid-flags) or generate new trace ID
  const traceparent = req.header('traceparent');
  let traceId: string;
  let spanId: string;

  if (traceparent && traceparent.startsWith('00-')) {
    const parts = traceparent.split('-');
    traceId = parts[1] || crypto.randomBytes(16).toString('hex');
    spanId = parts[2] || crypto.randomBytes(8).toString('hex');
  } else {
    traceId = crypto.randomBytes(16).toString('hex');
    spanId = crypto.randomBytes(8).toString('hex');
  }

  // Attach context to response locals and return standard correlation header
  res.locals.traceId = traceId;
  res.locals.spanId = spanId;
  res.setHeader('X-Trace-ID', traceId);

  const startTime = Date.now();

  res.on('finish', () => {
    const durationMs = Date.now() - startTime;
    logger.info('HTTP Request Handled', {
      trace_id: traceId,
      span_id: spanId,
      context: {
        method: req.method,
        path: req.originalUrl,
        statusCode: res.statusCode,
        durationMs,
        userAgent: req.header('user-agent'),
      },
    });
  });

  next();
}

// 4. Liveness and Readiness Health Endpoints
export function registerHealthProbes(app: express.Application, dbHealthCheck: () => Promise<boolean>): void {
  // Liveness Probe: Checks only if the process is responsive
  app.get('/healthz', (_req: Request, res: Response) => {
    res.status(200).json({ status: 'UP', timestamp: new Date().toISOString() });
  });

  // Readiness Probe: Verifies dependencies (DB, cache) before traffic routing
  app.get('/readyz', async (_req: Request, res: Response) => {
    try {
      const isDbHealthy = await dbHealthCheck();
      if (isDbHealthy) {
        res.status(200).json({ status: 'READY', components: { database: 'UP' } });
      } else {
        res.status(503).json({ status: 'UNAVAILABLE', components: { database: 'DOWN' } });
      }
    } catch (err: any) {
      logger.error('Readiness probe check failed', { error: err });
      res.status(503).json({ status: 'UNAVAILABLE', components: { database: 'DOWN' } });
    }
  });
}
```

---

## 8. Common Mistakes & Pitfalls

### Trap 1: Emitting Unstructured Text Logs in Production
*   **The Trap**: Using basic `console.log()` or `fmt.Println()` with human-targeted string formatting (`"User 123 did action X at Y"`).
*   **The Consequence**: Modern log aggregators cannot extract fields without brittle regular expressions; log search queries fail or degrade, and metric dashboards cannot aggregate structured keys.
*   **Mitigation**: Systems `MUST` write one JSON object per line (`ndjson`) containing standard fields (`timestamp`, `level`, `service`, `trace_id`, `message`, `context`).

### Trap 2: Leaking PII or Secrets via Request/Response Logging
*   **The Trap**: Middleware that unconditionally logs `req.body` or `req.headers` for debugging purposes without a redaction filter.
*   **The Consequence**: Passwords, authorization tokens, credit cards, and customer PII are permanently indexed in log storage, resulting in severe compliance violations and security hazards.
*   **Mitigation**: All logging pipelines `MUST` pass context metadata through an automated recursive redaction filter that masks known sensitive keys (`password`, `token`, `secret`, `authorization`, `cookie`).

### Trap 3: Confusing Liveness and Readiness Probes
*   **The Trap**: Implementing a single `/health` endpoint that queries the database, and assigning it as the Kubernetes Liveness probe.
*   **The Consequence**: If the database suffers a temporary network blip or high load, the liveness probe fails, causing Kubernetes to immediately kill and restart healthy API containers, triggering a catastrophic cascading reboot loop.
*   **Mitigation**: Systems `MUST` decouple `/healthz` (liveness: only verifies process loop execution) from `/readyz` (readiness: verifies external database and cache connectivity for traffic routing).

---

## 9. Verification Checklist

- [ ] **Structured JSON Logs**: All production log outputs are serialized as single-line JSON with standard fields (`timestamp`, `level`, `service`, `message`, `trace_id`).
- [ ] **Automated PII Redaction**: Passwords, tokens, authorization headers, and sensitive personal data are automatically scrubbed before serialization.
- [ ] **Distributed Trace Propagation**: Ingress requests parse or generate W3C `traceparent` headers, propagating `trace_id` through all downstream calls and log contexts.
- [ ] **Decoupled Health Checks**: Liveness (`/healthz`) and readiness (`/readyz`) endpoints are independently implemented with proper status codes (200 OK vs 503 Service Unavailable).
- [ ] **RED Telemetry Instrumentation**: HTTP handlers track request counts, error counts, and duration distributions across standard percentile thresholds (p50, p95, p99).
- [ ] **Zero Sensitive Error Leaks**: Error stack traces and internal system details are omitted from production HTTP responses and non-debug logs.
