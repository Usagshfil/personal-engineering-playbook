/**
 * Representative Backend & API Architecture Implementation
 * 
 * Demonstrates:
 * 1. Controller -> Service -> Domain -> Repository clean layering.
 * 2. Zod boundary schema validation with RFC 9457 Problem Details error responses.
 * 3. Idempotency-Key handling with concurrent in-flight locking and response replay.
 * 4. Structured JSON logging with W3C Trace Context correlation and PII redaction.
 * 5. Deterministic Unit of Work / Transaction boundary.
 */

import { z } from 'zod';
import crypto from 'crypto';

// ============================================================================
// 1. OBSERVABILITY & TELEMETRY (PII Sanitization & Structured Logger)
// ============================================================================

const SENSITIVE_KEYS = new Set([
  'password', 'token', 'authorization', 'secret', 'creditcard', 'cvv', 'ssn', 'apikey'
]);

export function sanitize(data: any): any {
  if (!data || typeof data !== 'object') return data;
  if (Array.isArray(data)) return data.map(sanitize);
  const out: Record<string, any> = {};
  for (const [k, v] of Object.entries(data)) {
    if (SENSITIVE_KEYS.has(k.toLowerCase())) {
      out[k] = '[REDACTED]';
    } else if (typeof v === 'object') {
      out[k] = sanitize(v);
    } else {
      out[k] = v;
    }
  }
  return out;
}

export class JsonLogger {
  constructor(private readonly service: string) {}

  log(level: 'INFO' | 'WARN' | 'ERROR', message: string, meta?: Record<string, any>): void {
    const entry = {
      timestamp: new Date().toISOString(),
      level,
      service: this.service,
      message,
      ...(meta ? sanitize(meta) : {}),
    };
    if (level === 'ERROR') {
      console.error(JSON.stringify(entry));
    } else {
      console.log(JSON.stringify(entry));
    }
  }

  info(msg: string, meta?: Record<string, any>) { this.log('INFO', msg, meta); }
  warn(msg: string, meta?: Record<string, any>) { this.log('WARN', msg, meta); }
  error(msg: string, meta?: Record<string, any>) { this.log('ERROR', msg, meta); }
}

const logger = new JsonLogger('order-service');

// ============================================================================
// 2. DOMAIN LAYER (Entities, Invariants, and Domain Exceptions)
// ============================================================================

export class DomainError extends Error {
  constructor(message: string, public readonly code: string) {
    super(message);
    this.name = 'DomainError';
  }
}

export class OrderAlreadyProcessedError extends DomainError {
  constructor(orderId: string) {
    super(`Order ${orderId} has already been processed and cannot be modified.`, 'ORDER_ALREADY_PROCESSED');
  }
}

export class InsufficientInventoryError extends DomainError {
  constructor(itemId: string, requested: number, available: number) {
    super(
      `Insufficient inventory for item ${itemId}: requested ${requested}, available ${available}.`,
      'INSUFFICIENT_INVENTORY'
    );
  }
}

export enum OrderStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  CANCELLED = 'CANCELLED',
}

export interface OrderItem {
  itemId: string;
  quantity: number;
  unitPriceCents: number;
}

export class Order {
  constructor(
    public readonly id: string,
    public readonly customerId: string,
    public readonly items: OrderItem[],
    private _status: OrderStatus = OrderStatus.PENDING,
    public readonly createdAt: Date = new Date()
  ) {}

  get status(): OrderStatus {
    return this._status;
  }

  calculateTotalCents(): number {
    return this.items.reduce((acc, item) => acc + item.quantity * item.unitPriceCents, 0);
  }

  confirm(): void {
    if (this._status !== OrderStatus.PENDING) {
      throw new OrderAlreadyProcessedError(this.id);
    }
    this._status = OrderStatus.CONFIRMED;
  }
}

// ============================================================================
// 3. PERSISTENCE ABSTRACTIONS (Repositories & Unit of Work)
// ============================================================================

export interface OrderRepository {
  findById(id: string): Promise<Order | null>;
  save(order: Order): Promise<void>;
}

export interface InventoryRepository {
  reserve(itemId: string, quantity: number): Promise<boolean>;
}

export interface UnitOfWork {
  execute<T>(work: () => Promise<T>): Promise<T>;
}

export interface IdempotencyStore {
  get(key: string): Promise<{ statusCode: number; body: any } | null>;
  set(key: string, statusCode: number, body: any, ttlSeconds: number): Promise<void>;
  acquireLock(key: string, ttlSeconds: number): Promise<boolean>;
  releaseLock(key: string): Promise<void>;
}

// ============================================================================
// 4. APPLICATION SERVICE LAYER
// ============================================================================

export interface CreateOrderCommand {
  customerId: string;
  items: Array<{ itemId: string; quantity: number; unitPriceCents: number }>;
}

export class OrderApplicationService {
  constructor(
    private readonly orderRepo: OrderRepository,
    private readonly inventoryRepo: InventoryRepository,
    private readonly unitOfWork: UnitOfWork
  ) {}

  async createOrder(command: CreateOrderCommand): Promise<Order> {
    return await this.unitOfWork.execute(async () => {
      // 1. Verify and reserve inventory for all items
      for (const item of command.items) {
        const reserved = await this.inventoryRepo.reserve(item.itemId, item.quantity);
        if (!reserved) {
          throw new InsufficientInventoryError(item.itemId, item.quantity, 0);
        }
      }

      // 2. Instantiate and confirm domain entity
      const order = new Order(
        crypto.randomUUID(),
        command.customerId,
        command.items
      );
      order.confirm();

      // 3. Save order
      await this.orderRepo.save(order);

      return order;
    });
  }
}

// ============================================================================
// 5. CONTRACT & VALIDATION LAYER (Zod Schema & RFC 9457 Mapping)
// ============================================================================

export const CreateOrderRequestSchema = z.object({
  customerId: z.string().uuid({ message: 'customerId must be a valid UUID v4' }),
  items: z.array(
    z.object({
      itemId: z.string().min(1, { message: 'itemId cannot be empty' }),
      quantity: z.number().int().positive({ message: 'quantity must be a positive integer' }),
      unitPriceCents: z.number().int().nonnegative({ message: 'unitPriceCents must be non-negative' }),
    })
  ).min(1, { message: 'Order must contain at least one item' }),
});

export type CreateOrderDTO = z.infer<typeof CreateOrderRequestSchema>;

export interface ProblemDetails {
  type: string;
  title: string;
  status: number;
  detail: string;
  instance: string;
  invalidParams?: Array<{ name: string; reason: string }>;
}

// ============================================================================
// 6. TRANSPORT LAYER (HTTP Controller with Idempotency & Error Mapping)
// ============================================================================

export interface HttpRequest {
  path: string;
  headers: Record<string, string | undefined>;
  body: any;
}

export interface HttpResponse {
  status: number;
  headers: Record<string, string>;
  body: any;
}

export class OrderHttpController {
  constructor(
    private readonly orderService: OrderApplicationService,
    private readonly idempotencyStore: IdempotencyStore
  ) {}

  async handleCreateOrder(req: HttpRequest): Promise<HttpResponse> {
    const traceId = req.headers['x-trace-id'] || crypto.randomUUID();
    const idempotencyKey = req.headers['idempotency-key'];

    logger.info('Received create order request', {
      trace_id: traceId,
      idempotency_key: idempotencyKey,
      path: req.path,
    });

    // 1. Enforce Idempotency-Key for mutating order creation
    if (!idempotencyKey) {
      return {
        status: 400,
        headers: { 'Content-Type': 'application/problem+json', 'X-Trace-ID': traceId },
        body: {
          type: 'https://api.example.com/errors/missing-idempotency-key',
          title: 'Bad Request',
          status: 400,
          detail: 'Mutating POST requests require an Idempotency-Key header.',
          instance: req.path,
        } as ProblemDetails,
      };
    }

    // 2. Check cached idempotent response
    const cachedResponse = await this.idempotencyStore.get(idempotencyKey);
    if (cachedResponse) {
      logger.info('Returning cached idempotent response', { trace_id: traceId, idempotency_key: idempotencyKey });
      return {
        status: cachedResponse.statusCode,
        headers: {
          'Content-Type': 'application/json',
          'X-Trace-ID': traceId,
          'X-Cache-Replay': 'true',
        },
        body: cachedResponse.body,
      };
    }

    // 3. Acquire concurrent in-flight lock
    const lockAcquired = await this.idempotencyStore.acquireLock(idempotencyKey, 30);
    if (!lockAcquired) {
      return {
        status: 409,
        headers: { 'Content-Type': 'application/problem+json', 'X-Trace-ID': traceId },
        body: {
          type: 'https://api.example.com/errors/concurrent-mutation',
          title: 'Conflict',
          status: 409,
          detail: 'A request with this Idempotency-Key is currently being processed.',
          instance: req.path,
        } as ProblemDetails,
      };
    }

    try {
      // 4. Validate input against schema
      const parseResult = CreateOrderRequestSchema.safeParse(req.body);
      if (!parseResult.success) {
        const problem: ProblemDetails = {
          type: 'https://api.example.com/errors/validation-failed',
          title: 'Unprocessable Content',
          status: 422,
          detail: 'The payload contains validation errors.',
          instance: req.path,
          invalidParams: parseResult.error.issues.map((issue) => ({
            name: issue.path.join('.'),
            reason: issue.message,
          })),
        };
        return {
          status: 422,
          headers: { 'Content-Type': 'application/problem+json', 'X-Trace-ID': traceId },
          body: problem,
        };
      }

      // 5. Execute application service workflow
      const order = await this.orderService.createOrder(parseResult.data);

      const responsePayload = {
        orderId: order.id,
        status: order.status,
        totalCents: order.calculateTotalCents(),
        createdAt: order.createdAt.toISOString(),
      };

      // 6. Cache successful idempotent response (e.g. 24 hour TTL)
      await this.idempotencyStore.set(idempotencyKey, 201, responsePayload, 86400);

      logger.info('Order created successfully', { trace_id: traceId, order_id: order.id });

      return {
        status: 201,
        headers: {
          'Content-Type': 'application/json',
          'Location': `/api/v1/orders/${order.id}`,
          'X-Trace-ID': traceId,
        },
        body: responsePayload,
      };
    } catch (error: any) {
      if (error instanceof InsufficientInventoryError) {
        return {
          status: 409,
          headers: { 'Content-Type': 'application/problem+json', 'X-Trace-ID': traceId },
          body: {
            type: 'https://api.example.com/errors/insufficient-inventory',
            title: 'Conflict',
            status: 409,
            detail: error.message,
            instance: req.path,
          } as ProblemDetails,
        };
      }

      logger.error('Unhandled internal error in handleCreateOrder', {
        trace_id: traceId,
        error_name: error.name,
        error_message: error.message,
      });

      return {
        status: 500,
        headers: { 'Content-Type': 'application/problem+json', 'X-Trace-ID': traceId },
        body: {
          type: 'https://api.example.com/errors/internal-server-error',
          title: 'Internal Server Error',
          status: 500,
          detail: 'An unexpected internal error occurred while processing your order.',
          instance: req.path,
        } as ProblemDetails,
      };
    } finally {
      await this.idempotencyStore.releaseLock(idempotencyKey);
    }
  }
}
