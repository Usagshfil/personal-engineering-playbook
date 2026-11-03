# Connection Pooling and Database Resilience Standards

> **Level 2 Technology Standard — Database & Persistence**  
> **Applicability**: Mandatory for all backend service database drivers, connection poolers, and database infrastructure configurations. Adheres to [Universal Core Standards](../../01-principles/README.md) and [System Architecture Standards](../../03-architecture/07-modular-architecture.md).

---

## 1. Definition & Core Concept

**Database Connection Pooling and Resilience** is the architectural practice of maintaining a bounded cache of pre-established, reusable database connection handles (via client-side poolers like HikariCP or server-side proxies like PgBouncer) to eliminate connection handshake latency, protect database CPU and memory from thread saturation, and prevent cascading platform failure during traffic spikes.

Core pooling principles include:
*   **The Physics of Pool Sizing**: A database server with $N$ CPU cores can execute at most $N$ operations simultaneously. Opening hundreds of concurrent database connections forces the operating system to thrash in context switching and cache eviction, *reducing* overall query throughput. The standard PostgreSQL sizing formula is:
    $$\text{Optimal Connections} = (\text{CPU Cores} \times 2) + \text{Effective Spindles}$$
*   **Two-Tier Pooling Architecture**:
    *   **Client-Side Pools** (HikariCP in Java, `pg-pool` in Node.js, `database/sql` in Go): Maintain small, warm pools inside each application instance ($\le 10$ connections per pod).
    *   **Server-Side Proxy Pooler** (PgBouncer in Transaction Pooling Mode): Mediates between thousands of client microservice pods and the PostgreSQL database engine, multiplexing thousands of incoming connections onto tens of active backend server processes.
*   **Bounded Timeouts & Load Shedding**: When the connection pool is saturated, services `MUST` fail fast with bounded acquisition timeouts ($\le 3\text{ seconds}$) and return HTTP `503 Service Unavailable` rather than queueing requests indefinitely until workers run out of memory.

$$\text{100 Application Pods} \xrightarrow[\text{10 conns/pod}]{\text{1,000 Client Conns}} \underbrace{\text{PgBouncer Proxy}}_{\text{pool\_mode = transaction}} \xrightarrow[\text{Sized: Cores } \times 2 + 1]{\text{30–50 Dedicated Conns}} \underbrace{\text{PostgreSQL Engine}}_{\text{Zero Context Thrashing}}$$

---

## 2. Purpose

The purpose of these standards is to:
1.  **Prevent Database Server Exhaustion**: Stop traffic surges from spawning thousands of PostgreSQL backend processes that consume all server RAM (each connection reserves 5–10MB) and crash the database with Out-Of-Memory (OOM) errors.
2.  **Eliminate TCP/TLS Handshake Overhead**: Avoid spending 15–30ms per HTTP request creating and destroying TLS and authentication sockets.
3.  **Detect Stale & Zombie Sockets**: Automatically detect and purge connections dropped silently by cloud firewalls or AWS NAT gateways using TCP Keepalives and connection validation.
4.  **Protect APIs from Cascading Freezes**: Fail fast when database capacity is saturated, shedding excess load to preserve availability for in-flight transactions.

---

## 3. Why It Matters

Misconfigured connection pools are among the leading causes of catastrophic cloud outages:
*   **The "More is Better" Sizing Fallacy**: Developers frequently configure `max_connections = 100` on 20 application pods, sending up to 2,000 connections to a 4-core PostgreSQL instance. Instead of handling more traffic, query latency skyrockets from 5ms to 2,000ms as the database CPU spends 90% of its cycles context switching between 2,000 competing processes.
*   **The Zombie Connection Black Hole**: Cloud load balancers and stateful firewalls silently drop idle TCP sockets after 300–350 seconds without sending TCP RST packets. If poolers lack `TCP Keepalive` or connection lifetime limits, application threads attempt to execute queries on dead sockets, hanging until socket timeout (often 15 minutes).
*   **Unbounded Connection Wait Queues**: When database load surges, an application pool configured with an infinite `connectionTimeout` causes thousands of incoming HTTP requests to wait in memory. The Node.js or JVM process runs out of heap memory and crashes, triggering a cascading restart loop across all application replicas.

---

## 4. When to Use It

Engineers `MUST` enforce these connection pooling standards:
*   In every production backend service connecting to PostgreSQL, MySQL, or SQL Server.
*   When deploying microservices running in Kubernetes or auto-scaling container groups.
*   When configuring database proxies (PgBouncer, AWS RDS Proxy) in front of primary or replica database clusters.
*   When configuring connection timeouts, idle timeouts, and statement timeouts.

---

## 5. When NOT to Use It

Engineers `SHOULD NOT` implement heavy server-side connection proxies when:
*   **Embedded Local Databases (SQLite)**: SQLite operates directly within the application process memory or local file system. Multi-connection pooling proxies do not apply. Use standard single-writer WAL configurations.
*   **Ephemeral CLI Tools & Short Scripts**: A one-off batch migration tool that connects, runs one script, and exits does not require server-side proxy pooling.
*   **Prepared Statements with Naive Transaction Pooling**: When using PgBouncer in `transaction` mode, session-level constructs (e.g. `SET SESSION`, server-side `PREPARE` without named statement handling) are lost between transactions. Use PgBouncer 1.21+ with named prepared statement support or manage statements client-side.

---

## 6. Advantages & Disadvantages

| Architecture | Advantages | Disadvantages & Trade-offs |
| :--- | :--- | :--- |
| **Small Client Pool (HikariCP / pg-pool)** | Minimal memory usage per pod; fast local connection reuse; sub-millisecond acquisition. | Must be sized conservative to avoid multiplying connections across autoscaled pods. |
| **PgBouncer (Transaction Mode)** | Allows 10,000 application pods to share 50 database connections; shields database from OOM. | Session-level SQL state (`SET TIME ZONE`, advisory locks across transactions) cannot be shared. |
| **Fail-Fast Acquisition Timeout** | Sheds excess load in sub-seconds; prevents container memory exhaustion. | Drops requests with 503 under extreme overload; requires client retry with backoff. |
| **TCP Keepalives & Lifetime Limits** | Completely eliminates dead socket hangs caused by cloud NAT timeouts. | Drops long-idle connections, requiring periodic re-connection handshakes. |

---

## 7. Practical Examples

### Bad Practice: Monolithic Pool Sizing, Infinite Timeouts, and Missing Keepalives

```typescript
// BAD: Catastrophic connection pool configuration
import { Pool } from 'pg';

export const badDbPool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Trap 1: Huge pool per pod (with 50 pods = 5,000 connections!)
  max: 100, 
  // Trap 2: Infinite acquisition timeout; hangs threads indefinitely under load
  connectionTimeoutMillis: 0, 
  // Trap 3: No max lifetime; dead sockets dropped by AWS NAT will hang queries
  idleTimeoutMillis: 0,
  // Trap 4: No statement timeout; a single unindexed query can run for hours
});
```

### Good Practice: Right-Sized Client Pool with Strict Timeouts & PgBouncer Configuration

#### Pattern A: Production Client Pool Configuration (Node.js / TypeScript Example)

```typescript
// GOOD: Production-grade pg-pool configuration sized for high concurrency
import { Pool, PoolConfig } from 'pg';

const poolConfig: PoolConfig = {
  connectionString: process.env.DATABASE_URL,
  
  // 1. Right-sized pool: 10 connections per container pod is standard
  max: 10,
  min: 2,
  
  // 2. Fail fast: If pool cannot grant a connection in 3s, throw timeout error
  connectionTimeoutMillis: 3000,
  
  // 3. Prevent zombie sockets: Close idle connections after 30 seconds
  idleTimeoutMillis: 30000,
  
  // 4. Maximum connection lifetime: Retire connections after 30 minutes to recycle resources
  maxLifetimeSeconds: 1800,
  
  // 5. Statement timeout: Abort any individual query running longer than 10 seconds
  statement_timeout: 10000,
  
  // 6. TCP Keepalive: Send probes every 15s to prevent silent cloud firewall drops
  keepAlive: true,
  keepAliveInitialDelayMillis: 15000,
};

export const resilientDbPool = new Pool(poolConfig);

// Handle unexpected pool client errors gracefully without crashing the process
resilientDbPool.on('error', (err) => {
  console.error('Unexpected idle client error in database pool', {
    error: err.message,
    timestamp: new Date().toISOString(),
  });
});

// Lightweight health check query for Kubernetes readiness probe
export async function checkDatabaseHealth(): Promise<boolean> {
  try {
    const client = await resilientDbPool.connect();
    try {
      await client.query('SELECT 1;');
      return true;
    } finally {
      client.release();
    }
  } catch (err) {
    return false;
  }
}
```

#### Pattern B: Production PgBouncer Configuration (`pgbouncer.ini`)

```ini
[databases]
* = host=127.0.0.1 port=5432 auth_user=pgbouncer

[pgbouncer]
logfile = /var/log/pgbouncer/pgbouncer.log
pidfile = /var/run/pgbouncer/pgbouncer.pid
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

; 1. Transaction Pooling: multiplexes client connections at transaction boundaries
pool_mode = transaction

; 2. Sized strictly to database hardware (e.g. 8 cores * 2 + 4 spindles = ~20-30 conns)
default_pool_size = 25
max_client_conn = 5000
min_pool_size = 5
reserve_pool_size = 5

; 3. Bounded wait times to shed load gracefully
query_timeout = 15.0
query_wait_timeout = 5.0
client_idle_timeout = 60.0

; 4. Enable TCP Keepalives
tcp_keepalive = 1
tcp_keepidle = 30
tcp_keepinterval = 10
tcp_keepcount = 3
```

---

## 8. Common Mistakes & Pitfalls

### Trap 1: The "Max Connections = 100 Per Pod" Sizing Disaster
*   **The Trap**: Setting maximum connection pool size to 50 or 100 on every microservice container.
*   **The Consequence**: As Kubernetes auto-scales from 5 pods to 40 pods during a traffic spike, the number of database connections jumps from 250 to 4,000. The database engine runs out of memory or spends all its time context switching, causing an instant platform-wide outage.
*   **Mitigation**: Size client-side pools small ($\le 10$ per pod). When total pod connections exceed 100, deploy **PgBouncer** in transaction pooling mode between application services and the database.

### Trap 2: Infinite Acquisition Timeout (Connection Hangs)
*   **The Trap**: Configuring `connectionTimeoutMillis: 0` (wait indefinitely for a connection).
*   **The Consequence**: During high load, incoming requests queue up waiting for connections. Web server worker threads are blocked indefinitely; reverse proxies timeout after 60s; users refresh repeatedly, creating a devastating compounding traffic surge that permanently jams the server.
*   **Mitigation**: Always configure an explicit acquisition timeout ($\le 2\text{–}3\text{ seconds}$). When timed out, fail fast, emit an alert, and return an HTTP `503 Service Unavailable` with a `Retry-After: 5` header.

### Trap 3: Missing TCP Keepalive on Cloud Networks
*   **The Trap**: Running on AWS, GCP, or Azure without explicit TCP keepalive configurations in client drivers.
*   **The Consequence**: Cloud NAT gateways silently drop idle connection state after 350 seconds. The next time the pool allocates that idle connection, the query hangs until TCP retransmission times out (typically 15 minutes).
*   **Mitigation**: Enable `keepAlive: true` with an initial delay $\le 15\text{–}30\text{ seconds}$ on all connection pools.

---

## 9. Verification Checklist

- [ ] **Empirically Sized Pools**: Client-side connection pools are configured conservatively ($\le 10$ connections per instance).
- [ ] **PgBouncer Transaction Pooling**: Deployments exceeding 100 total potential container connections utilize PgBouncer in transaction pooling mode.
- [ ] **Bounded Acquisition Timeout**: Connection acquisition timeouts are strictly bounded ($\le 3000\text{ms}$); zero infinite wait times exist.
- [ ] **TCP Keepalives Enabled**: Driver pools configure TCP keepalives with intervals $\le 30\text{s}$ to prevent silent cloud NAT disconnections.
- [ ] **Statement Timeouts Configured**: Database connections set a `statement_timeout` ($\le 10\text{s}$) to kill rogue unindexed queries automatically.
- [ ] **Lightweight Health Checks**: Kubernetes readiness probes use simple `SELECT 1` queries to verify database connectivity without query overhead.
