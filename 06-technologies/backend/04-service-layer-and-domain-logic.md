# Service Layer and Domain Logic Standards

> **Level 2 Technology Standard — Backend & APIs**  
> **Applicability**: Mandatory for all backend services, API gateways, workers, and background processors. Adheres to [Universal Core Standards](../../01-principles/README.md) and [Architecture Standards](../../03-architecture/02-clean-architecture.md).

---

## 1. Definition & Core Concept

The **Service Layer** is an architectural boundary that encapsulates the business logic, workflow orchestration, and transaction management of an application, mediating between client-facing transport adapters (HTTP controllers, gRPC handlers, message queue consumers) and infrastructure persistence layers (database repositories, external API clients, message brokers).

In this architectural model:
*   **Controllers / Handlers** `MUST` be thin HTTP/protocol adapters that parse and validate input, call the service layer, and map outcomes to protocol-specific responses.
*   **Domain Entities & Value Objects** `MUST` encapsulate pure business rules, invariants, and calculations free from transport, framework, or persistence concerns.
*   **Application Services** `MUST` orchestrate workflows, manage transaction boundaries, invoke domain logic, and interact with infrastructure through repository interfaces.
*   **Repositories** `MUST` abstract data persistence and retrieval, returning domain entities or clean projection types rather than exposing raw database connection primitives.

$$\text{HTTP Request} \longrightarrow \underbrace{\text{Controller}}_{\text{Transport/Auth}} \longrightarrow \underbrace{\text{Application Service}}_{\text{Workflow/Tx Boundary}} \longleftrightarrow \underbrace{\text{Domain Logic}}_{\text{Pure Invariants}} \longleftrightarrow \underbrace{\text{Repository}}_{\text{Persistence Adapter}} \longrightarrow \text{Database}$$

---

## 2. Purpose

The purpose of these standards is to:
1.  **Isolate Business Invariants**: Guarantee that business rules remain identical regardless of whether an operation is initiated via a REST endpoint, a GraphQL query, a CLI command, or an asynchronous worker.
2.  **Ensure Transactional Integrity**: Establish explicit, deterministically managed transaction boundaries that prevent partial writes, orphaned child records, and data corruption.
3.  **Standardize Error Classification**: Decouple domain error semantics (e.g., `InsufficientBalanceError`, `UserSuspendedError`) from infrastructure exceptions (e.g., `TimeoutException`, `UniqueConstraintViolation`) and protocol representations (RFC 9457 Problem Details).
4.  **Maximize Testability**: Allow all business logic to be tested via fast, deterministic unit tests without booting database engines, web servers, or third-party networks.

---

## 3. Why It Matters

When domain logic bleeds into HTTP controllers or database triggers:
*   **Duplication and Inconsistency**: Business checks (e.g., verifying loan eligibility) duplicated across multiple controllers drift over time, leading to security loopholes and data anomalies.
*   **Partial Updates & Inconsistent States**: Without clear transaction boundaries at the service layer, failures halfway through multi-table writes leave databases in inconsistent, unrecoverable states.
*   **Testing Paralysis**: Tightly coupled controllers require spinning up entire HTTP servers and mocked servlet contexts just to test a single mathematical business calculation, dramatically slowing down CI pipelines.
*   **Cryptic Client Errors**: Exposing unhandled database or ORM exceptions to HTTP clients leaks internal schemas (violating Tier 1 Security Rule 7) and confuses frontend consumers.

---

## 4. When to Use It

Engineers `MUST` enforce this service layer structure when:
*   The application implements stateful business workflows involving validation, calculations, mutations, or third-party notifications.
*   A mutation touches multiple database tables or aggregates requiring atomic consistency.
*   The codebase supports multiple entry points (e.g., REST API, cron job, gRPC service, background queue consumer) sharing the same domain logic.
*   Systems require auditable business state transitions and event publishing.

---

## 5. When NOT to Use It

Engineers `MAY` relax full domain layering only when:
*   **Pure Read Projections / CQRS Read Paths**: High-throughput read queries that directly map SQL or Redis results to client DTOs without domain invariants. Directly invoking a query repository or read model avoids unnecessary object allocation overhead.
*   **Stateless Pass-Through Proxies / Gateways**: API gateways whose sole responsibility is path routing, rate limiting, and header manipulation without business decisions.
*   **Ephemeral Prototypes**: Throwaway CLI tools or temporary exploratory scripts with a confirmed lifespan of less than 2 weeks.

---

## 6. Advantages & Disadvantages

| Aspect | Advantages | Disadvantages & Trade-offs |
| :--- | :--- | :--- |
| **Maintainability** | Centralized business logic; changing a rule requires touching exactly one service or entity. | Introduces layer indirection and interface files compared to simple ActiveRecord scripts. |
| **Testability** | Pure unit testing of domain rules with mock repositories executes in milliseconds. | Requires dependency injection boilerplate and mock setups in test files. |
| **Reliability** | Atomic transactions prevent partial failures; explicit error domains prevent accidental 500s. | Transaction isolation levels and lock durations must be carefully monitored under high concurrency. |
| **Decoupling** | Transport layers (HTTP, Kafka, CLI) can change without impacting domain workflows. | Requires explicit mapping between DTOs, domain models, and persistence entities. |

---

## 7. Practical Examples

### Bad Practice: Fat Controller with Leaked Business Logic and Raw SQL Transactions

```typescript
// BAD: Fat controller mixing transport, validation, business rules, raw transactions, and direct DB access
import { Request, Response } from 'express';
import { dbPool } from '../db';

export async function transferFundsController(req: Request, res: Response) {
  const { senderId, receiverId, amount } = req.body;

  // Validation mixed into controller
  if (!senderId || !receiverId || amount <= 0) {
    return res.status(400).json({ error: 'Invalid input parameters' });
  }

  const client = await dbPool.connect();
  try {
    await client.query('BEGIN');

    // Business rule: Verify sender balance
    const senderRes = await client.query('SELECT balance, is_frozen FROM accounts WHERE id = $1', [senderId]);
    if (senderRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Sender not found' });
    }

    const sender = senderRes.rows[0];
    if (sender.is_frozen) {
      await client.query('ROLLBACK');
      return res.status(403).json({ error: 'Sender account is frozen' });
    }

    if (sender.balance < amount) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Insufficient funds' });
    }

    // Direct mutation
    await client.query('UPDATE accounts SET balance = balance - $1 WHERE id = $2', [amount, senderId]);
    await client.query('UPDATE accounts SET balance = balance + $1 WHERE id = $2', [amount, receiverId]);
    await client.query('INSERT INTO transfers (sender_id, receiver_id, amount) VALUES ($1, $2, $3)', [senderId, receiverId, amount]);

    await client.query('COMMIT');
    return res.status(200).json({ status: 'SUCCESS' });
  } catch (err: any) {
    await client.query('ROLLBACK');
    // Leaks internal DB error message to client
    return res.status(500).json({ error: err.message, stack: err.stack });
  } finally {
    client.release();
  }
}
```

### Good Practice: Layered Architecture with Domain Entity, Service Transaction, and RFC 9457 Error Mapping

```typescript
// GOOD: Clean separation of concerns with domain invariants, transactional service, and RFC 9457 handler

// 1. Domain Layer: Invariant enforcement
export class Account {
  constructor(
    public readonly id: string,
    private _balance: number,
    public readonly isFrozen: boolean
  ) {}

  get balance(): number {
    return this._balance;
  }

  debit(amount: number): void {
    if (this.isFrozen) {
      throw new AccountFrozenException(`Account ${this.id} is frozen and cannot be debited.`);
    }
    if (amount <= 0) {
      throw new InvalidAmountException('Debit amount must be strictly positive.');
    }
    if (this._balance < amount) {
      throw new InsufficientBalanceException(`Insufficient balance: requested ${amount}, available ${this._balance}.`);
    }
    this._balance -= amount;
  }

  credit(amount: number): void {
    if (this.isFrozen) {
      throw new AccountFrozenException(`Account ${this.id} is frozen and cannot be credited.`);
    }
    if (amount <= 0) {
      throw new InvalidAmountException('Credit amount must be strictly positive.');
    }
    this._balance += amount;
  }
}

// 2. Domain Exceptions
export class DomainException extends Error {
  constructor(message: string) {
    super(message);
    this.name = this.constructor.name;
  }
}
export class AccountFrozenException extends DomainException {}
export class InsufficientBalanceException extends DomainException {}
export class InvalidAmountException extends DomainException {}
export class AccountNotFoundException extends DomainException {}

// 3. Port / Repository Interface
export interface AccountRepository {
  findById(id: string): Promise<Account | null>;
  save(account: Account): Promise<void>;
}

export interface UnitOfWork {
  executeInTransaction<T>(work: () => Promise<T>): Promise<T>;
}

// 4. Application Service Layer
export interface TransferFundsCommand {
  senderId: string;
  receiverId: string;
  amount: number;
}

export class TransferService {
  constructor(
    private readonly accountRepo: AccountRepository,
    private readonly unitOfWork: UnitOfWork
  ) {}

  async transfer(command: TransferFundsCommand): Promise<{ transactionId: string; remainingBalance: number }> {
    return await this.unitOfWork.executeInTransaction(async () => {
      const sender = await this.accountRepo.findById(command.senderId);
      if (!sender) {
        throw new AccountNotFoundException(`Sender account ${command.senderId} not found.`);
      }

      const receiver = await this.accountRepo.findById(command.receiverId);
      if (!receiver) {
        throw new AccountNotFoundException(`Receiver account ${command.receiverId} not found.`);
      }

      // Execute domain rules inside entities
      sender.debit(command.amount);
      receiver.credit(command.amount);

      // Persist changes
      await this.accountRepo.save(sender);
      await this.accountRepo.save(receiver);

      return {
        transactionId: crypto.randomUUID(),
        remainingBalance: sender.balance,
      };
    });
  }
}

// 5. Thin Controller with RFC 9457 Problem Details Error Mapping
import { Request, Response, NextFunction } from 'express';

export class AccountController {
  constructor(private readonly transferService: TransferService) {}

  async handleTransfer(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.transferService.transfer({
        senderId: req.body.senderId,
        receiverId: req.body.receiverId,
        amount: req.body.amount,
      });

      res.status(200).json(result);
    } catch (error) {
      if (error instanceof InsufficientBalanceException) {
        res.status(422).contentType('application/problem+json').json({
          type: 'https://api.example.com/errors/insufficient-balance',
          title: 'Unprocessable Content',
          status: 422,
          detail: error.message,
          instance: req.originalUrl,
        });
        return;
      }
      if (error instanceof AccountFrozenException) {
        res.status(403).contentType('application/problem+json').json({
          type: 'https://api.example.com/errors/account-frozen',
          title: 'Forbidden',
          status: 403,
          detail: error.message,
          instance: req.originalUrl,
        });
        return;
      }
      if (error instanceof AccountNotFoundException) {
        res.status(404).contentType('application/problem+json').json({
          type: 'https://api.example.com/errors/account-not-found',
          title: 'Not Found',
          status: 404,
          detail: error.message,
          instance: req.originalUrl,
        });
        return;
      }
      // Delegate unexpected infrastructure errors to central handler
      next(error);
    }
  }
}
```

---

## 8. Common Mistakes & Pitfalls

### Trap 1: Leaking Infrastructure and Transport Concerns into Domain Entities
*   **The Trap**: Importing HTTP packages (`express.Request`, `Response`), ORM active-record annotations that bind directly to database columns, or AWS SDK clients directly inside domain entities or business services.
*   **The Consequence**: Domain logic cannot be tested without external services; changing database schemas or switching transport layers breaks core business calculations.
*   **Mitigation**: Domain entities `MUST` be plain objects/classes with zero framework dependencies. Services `MUST` interact with external systems exclusively through interfaces (Dependency Inversion Principle).

### Trap 2: Implicit or Non-Atomic Transaction Boundaries
*   **The Trap**: Starting database transactions inside HTTP controllers or making multiple separate repository calls without an atomic Unit of Work wrapper.
*   **The Consequence**: If the second repository call fails due to a network blip or constraint violation, the first mutation has already committed, corrupting the database state.
*   **Mitigation**: Transaction boundaries `MUST` be managed at the application service layer via declarative wrappers (e.g., `@Transactional` or `unitOfWork.executeInTransaction()`). Controllers `MUST NEVER` initiate or commit transactions.

### Trap 3: Generic Catch-All 500 Responses Masking Domain Violations
*   **The Trap**: Catching generic `Error` instances and returning standard `{ error: "Internal Server Error" }` for domain invariant violations such as insufficient funds or invalid business status transitions.
*   **The Consequence**: API clients cannot programmatically react to business rejection reasons, and telemetry treats expected business rules as infrastructure defects.
*   **Mitigation**: Services `MUST` throw typed domain exceptions or return `Result<T, DomainError>` objects. Controllers `MUST` map domain errors to standard HTTP status codes (400, 403, 404, 409, 422) and format them using RFC 9457 Problem Details.

---

## 9. Verification Checklist

- [ ] **Thin Controllers**: Controllers contain only request parsing, schema validation, service invocation, and response/error mapping. Zero business calculations or SQL statements exist in controllers.
- [ ] **Pure Domain Invariants**: Core business rules and invariants are encapsulated within domain entities, value objects, or pure domain services.
- [ ] **Explicit Transaction Boundaries**: Every multi-step mutation is executed within an atomic transaction managed at the service/Unit of Work boundary.
- [ ] **Dependency Inversion**: Services depend on repository and client abstractions (interfaces), enabling pure in-memory unit testing.
- [ ] **RFC 9457 Problem Details**: Domain exceptions are mapped to standard HTTP error codes with `application/problem+json` structure.
- [ ] **Zero Database Leaks**: Database connection handles, ORM internal errors, and raw query traces are never serialized to client responses.
