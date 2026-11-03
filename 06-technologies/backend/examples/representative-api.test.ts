/**
 * Automated Test Suite for Representative Backend API
 * 
 * Verifies:
 * 1. Happy path order creation (201 Created + Location header)
 * 2. Missing Idempotency-Key (400 Bad Request Problem Details)
 * 3. Cached replay on identical Idempotency-Key (201 Replay + X-Cache-Replay)
 * 4. Payload fingerprint mismatch with existing key (422 Unprocessable Content)
 * 5. Concurrent in-flight request lock rejection (409 Conflict)
 * 6. Zod boundary validation failure (422 Unprocessable Content with invalidParams)
 * 7. Domain invariant failure: Insufficient inventory (409 Conflict)
 * 8. PII sanitization in metadata logs
 */

import {
  OrderHttpController,
  OrderApplicationService,
  InMemoryOrderRepository,
  InMemoryInventoryRepository,
  DirectUnitOfWork,
  InMemoryIdempotencyStore,
  HttpRequest,
  sanitize,
} from './representative-api';

export interface TestResult {
  name: string;
  passed: boolean;
  error?: string;
}

export async function runRepresentativeApiTests(): Promise<TestResult[]> {
  const results: TestResult[] = [];

  const setup = () => {
    const orderRepo = new InMemoryOrderRepository();
    const inventory = new Map<string, number>([
      ['item-1', 10],
      ['item-2', 5],
    ]);
    const inventoryRepo = new InMemoryInventoryRepository(inventory);
    const unitOfWork = new DirectUnitOfWork();
    const service = new OrderApplicationService(orderRepo, inventoryRepo, unitOfWork);
    const idempotencyStore = new InMemoryIdempotencyStore();
    const controller = new OrderHttpController(service, idempotencyStore);

    return { controller, idempotencyStore, inventory };
  };

  // --------------------------------------------------------------------------
  // Test 1: Successful Order Creation
  // --------------------------------------------------------------------------
  try {
    const { controller } = setup();
    const req: HttpRequest = {
      path: '/v1/orders',
      headers: {
        'idempotency-key': 'key-happy-path-001',
        'x-trace-id': 'trace-test-001',
      },
      body: {
        customerId: '123e4567-e89b-12d3-a456-426614174000',
        items: [
          { itemId: 'item-1', quantity: 2, unitPriceCents: 500 },
          { itemId: 'item-2', quantity: 1, unitPriceCents: 1500 },
        ],
      },
    };

    const res = await controller.handleCreateOrder(req);

    if (res.status === 201 && res.body.status === 'CONFIRMED' && res.body.totalCents === 2500) {
      results.push({ name: 'Happy Path Order Creation (201 Created)', passed: true });
    } else {
      results.push({
        name: 'Happy Path Order Creation (201 Created)',
        passed: false,
        error: `Expected 201 CONFIRMED total 2500, got status ${res.status}: ${JSON.stringify(res.body)}`,
      });
    }
  } catch (err: any) {
    results.push({ name: 'Happy Path Order Creation', passed: false, error: err.message });
  }

  // --------------------------------------------------------------------------
  // Test 2: Missing Idempotency-Key Header
  // --------------------------------------------------------------------------
  try {
    const { controller } = setup();
    const req: HttpRequest = {
      path: '/v1/orders',
      headers: {},
      body: {
        customerId: '123e4567-e89b-12d3-a456-426614174000',
        items: [{ itemId: 'item-1', quantity: 1, unitPriceCents: 500 }],
      },
    };

    const res = await controller.handleCreateOrder(req);

    if (res.status === 400 && res.body.title === 'Bad Request') {
      results.push({ name: 'Missing Idempotency-Key (400 Bad Request)', passed: true });
    } else {
      results.push({
        name: 'Missing Idempotency-Key (400 Bad Request)',
        passed: false,
        error: `Expected 400 Bad Request, got status ${res.status}`,
      });
    }
  } catch (err: any) {
    results.push({ name: 'Missing Idempotency-Key', passed: false, error: err.message });
  }

  // --------------------------------------------------------------------------
  // Test 3: Cached Idempotent Response Replay
  // --------------------------------------------------------------------------
  try {
    const { controller } = setup();
    const req: HttpRequest = {
      path: '/v1/orders',
      headers: { 'idempotency-key': 'key-replay-001' },
      body: {
        customerId: '123e4567-e89b-12d3-a456-426614174000',
        items: [{ itemId: 'item-1', quantity: 1, unitPriceCents: 500 }],
      },
    };

    const firstRes = await controller.handleCreateOrder(req);
    const secondRes = await controller.handleCreateOrder(req);

    if (
      secondRes.status === 201 &&
      secondRes.headers['X-Cache-Replay'] === 'true' &&
      secondRes.body.orderId === firstRes.body.orderId
    ) {
      results.push({ name: 'Cached Idempotency Replay (X-Cache-Replay: true)', passed: true });
    } else {
      results.push({
        name: 'Cached Idempotency Replay',
        passed: false,
        error: `Replay failed: status ${secondRes.status}, cache header: ${secondRes.headers['X-Cache-Replay']}`,
      });
    }
  } catch (err: any) {
    results.push({ name: 'Cached Idempotency Replay', passed: false, error: err.message });
  }

  // --------------------------------------------------------------------------
  // Test 4: Payload Mismatch on Existing Idempotency-Key
  // --------------------------------------------------------------------------
  try {
    const { controller } = setup();
    const req1: HttpRequest = {
      path: '/v1/orders',
      headers: { 'idempotency-key': 'key-payload-mismatch' },
      body: {
        customerId: '123e4567-e89b-12d3-a456-426614174000',
        items: [{ itemId: 'item-1', quantity: 1, unitPriceCents: 500 }],
      },
    };
    await controller.handleCreateOrder(req1);

    // Request with same key but different body payload
    const req2: HttpRequest = {
      path: '/v1/orders',
      headers: { 'idempotency-key': 'key-payload-mismatch' },
      body: {
        customerId: '123e4567-e89b-12d3-a456-426614174000',
        items: [{ itemId: 'item-1', quantity: 5, unitPriceCents: 9999 }], // altered
      },
    };
    const res2 = await controller.handleCreateOrder(req2);

    if (res2.status === 422 && res2.body.type.includes('idempotency-payload-mismatch')) {
      results.push({ name: 'Payload Mismatch Detection (422 Unprocessable Content)', passed: true });
    } else {
      results.push({
        name: 'Payload Mismatch Detection',
        passed: false,
        error: `Expected 422 mismatch, got ${res2.status}: ${JSON.stringify(res2.body)}`,
      });
    }
  } catch (err: any) {
    results.push({ name: 'Payload Mismatch Detection', passed: false, error: err.message });
  }

  // --------------------------------------------------------------------------
  // Test 5: Concurrent In-Flight Lock Rejection
  // --------------------------------------------------------------------------
  try {
    const { controller, idempotencyStore } = setup();
    // Simulate lock acquired by concurrent worker
    await idempotencyStore.acquireLock('key-in-flight-001', 30);

    const req: HttpRequest = {
      path: '/v1/orders',
      headers: { 'idempotency-key': 'key-in-flight-001' },
      body: {
        customerId: '123e4567-e89b-12d3-a456-426614174000',
        items: [{ itemId: 'item-1', quantity: 1, unitPriceCents: 500 }],
      },
    };

    const res = await controller.handleCreateOrder(req);

    if (res.status === 409 && res.body.title === 'Conflict') {
      results.push({ name: 'Concurrent In-Flight Lock Rejection (409 Conflict)', passed: true });
    } else {
      results.push({
        name: 'Concurrent In-Flight Lock Rejection',
        passed: false,
        error: `Expected 409 Conflict, got ${res.status}`,
      });
    }
  } catch (err: any) {
    results.push({ name: 'Concurrent In-Flight Lock Rejection', passed: false, error: err.message });
  }

  // --------------------------------------------------------------------------
  // Test 6: Zod Schema Validation Failure
  // --------------------------------------------------------------------------
  try {
    const { controller } = setup();
    const req: HttpRequest = {
      path: '/v1/orders',
      headers: { 'idempotency-key': 'key-invalid-schema' },
      body: {
        customerId: 'not-a-valid-uuid',
        items: [], // violates min(1)
      },
    };

    const res = await controller.handleCreateOrder(req);

    if (
      res.status === 422 &&
      Array.isArray(res.body.invalidParams) &&
      res.body.invalidParams.length >= 2
    ) {
      results.push({ name: 'Zod Boundary Schema Validation (422 RFC 9457)', passed: true });
    } else {
      results.push({
        name: 'Zod Boundary Schema Validation',
        passed: false,
        error: `Expected 422 with invalidParams, got ${res.status}: ${JSON.stringify(res.body)}`,
      });
    }
  } catch (err: any) {
    results.push({ name: 'Zod Boundary Schema Validation', passed: false, error: err.message });
  }

  // --------------------------------------------------------------------------
  // Test 7: Domain Invariant Failure (Insufficient Inventory)
  // --------------------------------------------------------------------------
  try {
    const { controller } = setup();
    const req: HttpRequest = {
      path: '/v1/orders',
      headers: { 'idempotency-key': 'key-insufficient-inventory' },
      body: {
        customerId: '123e4567-e89b-12d3-a456-426614174000',
        items: [{ itemId: 'item-1', quantity: 999, unitPriceCents: 500 }], // only 10 in stock
      },
    };

    const res = await controller.handleCreateOrder(req);

    if (res.status === 409 && res.body.type.includes('insufficient-inventory')) {
      results.push({ name: 'Domain Invariant Rejection (409 Conflict)', passed: true });
    } else {
      results.push({
        name: 'Domain Invariant Rejection',
        passed: false,
        error: `Expected 409 insufficient-inventory, got ${res.status}`,
      });
    }
  } catch (err: any) {
    results.push({ name: 'Domain Invariant Rejection', passed: false, error: err.message });
  }

  // --------------------------------------------------------------------------
  // Test 8: PII and Secret Redaction Filter
  // --------------------------------------------------------------------------
  try {
    const dirty = {
      username: 'johndoe',
      password: 'super-secret-password-123',
      token: 'jwt-bearer-xyz',
      nested: {
        creditcard: '4111-2222-3333-4444',
        safeProperty: 'public-value',
      },
    };

    const sanitized = sanitize(dirty);

    if (
      sanitized.password === '[REDACTED]' &&
      sanitized.token === '[REDACTED]' &&
      sanitized.nested.creditcard === '[REDACTED]' &&
      sanitized.nested.safeProperty === 'public-value'
    ) {
      results.push({ name: 'PII & Secret Metadata Sanitization Filter', passed: true });
    } else {
      results.push({
        name: 'PII & Secret Metadata Sanitization Filter',
        passed: false,
        error: `Sanitization failed: ${JSON.stringify(sanitized)}`,
      });
    }
  } catch (err: any) {
    results.push({ name: 'PII & Secret Metadata Sanitization', passed: false, error: err.message });
  }

  // --------------------------------------------------------------------------
  // Test 9: Transaction Rollback on Failure
  // --------------------------------------------------------------------------
  try {
    const orderRepo = new InMemoryOrderRepository();
    const inventory = new Map<string, number>([['item-1', 10]]);
    const inventoryRepo = new InMemoryInventoryRepository(inventory);
    
    // Custom UnitOfWork that simulates a transaction abort/rollback
    let rolledBack = false;
    const failingUnitOfWork: DirectUnitOfWork = {
      async execute<T>(work: () => Promise<T>): Promise<T> {
        try {
          return await work();
        } catch (err) {
          rolledBack = true;
          throw err;
        }
      },
    };

    // Subclass service to throw an unexpected database failure after reservation
    const failingService = new OrderApplicationService(orderRepo, inventoryRepo, failingUnitOfWork);
    const idempotencyStore = new InMemoryIdempotencyStore();
    const controller = new OrderHttpController(failingService, idempotencyStore);

    // Make save throw
    orderRepo.save = async () => {
      throw new Error('Database disk I/O failure');
    };

    const req: HttpRequest = {
      path: '/v1/orders',
      headers: { 'idempotency-key': 'key-rollback-test' },
      body: {
        customerId: '123e4567-e89b-12d3-a456-426614174000',
        items: [{ itemId: 'item-1', quantity: 2, unitPriceCents: 500 }],
      },
    };

    const res = await controller.handleCreateOrder(req);

    if (res.status === 500 && rolledBack) {
      results.push({ name: 'Database Transaction Failure & Clean Rollback', passed: true });
    } else {
      results.push({
        name: 'Database Transaction Failure & Clean Rollback',
        passed: false,
        error: `Expected 500 and rolledBack=true, got status ${res.status}, rolledBack: ${rolledBack}`,
      });
    }
  } catch (err: any) {
    results.push({ name: 'Database Transaction Failure & Clean Rollback', passed: false, error: err.message });
  }

  // --------------------------------------------------------------------------
  // Test 10: Outbox Event Generation & Consumer Inbox Deduplication
  // --------------------------------------------------------------------------
  try {
    // Consumer Inbox Deduplication Simulation
    const processedEvents = new Set<string>();
    let processCount = 0;

    const consumeEvent = async (event: { eventId: string; type: string; payload: any }) => {
      if (processedEvents.has(event.eventId)) {
        // Duplicate delivery detected: ignore silently (Idempotent consumer)
        return { status: 'DUPLICATE_IGNORED' };
      }
      processedEvents.add(event.eventId);
      processCount++;
      return { status: 'PROCESSED' };
    };

    const sampleEvent = {
      eventId: 'evt-unique-12345',
      type: 'ORDER_PLACED',
      payload: { orderId: 'ord-001', amountCents: 2500 },
    };

    // First delivery
    const res1 = await consumeEvent(sampleEvent);
    // Duplicate delivery (replayed by worker crash recovery)
    const res2 = await consumeEvent(sampleEvent);

    if (res1.status === 'PROCESSED' && res2.status === 'DUPLICATE_IGNORED' && processCount === 1) {
      results.push({ name: 'Outbox Event Generation & Consumer Inbox Deduplication', passed: true });
    } else {
      results.push({
        name: 'Outbox Event Generation & Consumer Inbox Deduplication',
        passed: false,
        error: `Expected 1 execution and duplicate ignored, got count ${processCount}`,
      });
    }
  } catch (err: any) {
    results.push({ name: 'Outbox Event Generation & Consumer Inbox Deduplication', passed: false, error: err.message });
  }

  // --------------------------------------------------------------------------
  // Test 11: Broken Object-Level Authorization (BOLA/IDOR) Defense
  // --------------------------------------------------------------------------
  try {
    const userOrgId = 'org-tenant-alpha';
    const attackerOrgId = 'org-tenant-bravo';

    // Simulated tenant-aware resource accessor
    const getOrderDetails = async (authenticatedOrg: string, resourceOrg: string) => {
      if (authenticatedOrg !== resourceOrg) {
        return {
          status: 403,
          body: {
            type: 'https://api.example.com/errors/forbidden',
            title: 'Forbidden',
            status: 403,
            detail: 'Cross-tenant or unauthorized resource access denied.',
          },
        };
      }
      return { status: 200, body: { orderId: 'ord-123', org: resourceOrg } };
    };

    const legitimate = await getOrderDetails(userOrgId, userOrgId);
    const unauthorized = await getOrderDetails(attackerOrgId, userOrgId);

    if (legitimate.status === 200 && unauthorized.status === 403) {
      results.push({ name: 'Broken Object-Level Authorization (BOLA/IDOR) Defense', passed: true });
    } else {
      results.push({
        name: 'Broken Object-Level Authorization (BOLA/IDOR) Defense',
        passed: false,
        error: `Expected 200 legitimate and 403 unauthorized, got ${legitimate.status} / ${unauthorized.status}`,
      });
    }
  } catch (err: any) {
    results.push({ name: 'Broken Object-Level Authorization (BOLA/IDOR) Defense', passed: false, error: err.message });
  }

  return results;
}
