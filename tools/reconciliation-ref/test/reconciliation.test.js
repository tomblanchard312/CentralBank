const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { createConfig, VALID_ENVIRONMENTS } = require('../config');
const { createStorage } = require('../storage');
const { validateReconciliationBatch } = require('../validation');

describe('reconciliation-ref config', () => {
  it('accepts known environments', () => {
    for (const env of VALID_ENVIRONMENTS) {
      if (env === 'prod') continue; // durable storage constructs fail-closed
      const config = createConfig(env);
      assert.equal(config.environment, env);
      assert.ok(config.maxBatchSize > 0);
    }
  });

  it('rejects missing environment', () => {
    assert.throws(() => createConfig(undefined), /CENTRALBANK_ENV must be one of/);
  });

  it('maps test environment to memory storage', () => {
    const config = createConfig('test');
    assert.equal(config.storageType, 'memory');
    assert.equal(config.maxBatchSize, 50);
  });
});

describe('reconciliation-ref validation', () => {
  const validBatch = {
    device_id: 'device-1',
    wallet_id: 'wallet-1',
    transactions: [
      {
        sequence_number: 1,
        amount: 100,
        signature: 'sig-1',
        timestamp: '2026-01-01T00:00:00.000Z'
      }
    ]
  };

  it('accepts a valid batch', () => {
    const result = validateReconciliationBatch(validBatch, 50);
    assert.equal(result.valid, true);
  });

  it('rejects oversized batches', () => {
    const batch = {
      ...validBatch,
      transactions: Array.from({ length: 3 }, (_, i) => ({
        sequence_number: i + 1,
        amount: 1,
        signature: `sig-${i}`
      }))
    };
    const result = validateReconciliationBatch(batch, 2);
    assert.equal(result.valid, false);
    assert.match(result.error, /exceeds maximum/);
  });

  it('rejects duplicate sequence numbers', () => {
    const batch = {
      ...validBatch,
      transactions: [
        { sequence_number: 1, amount: 1, signature: 'a' },
        { sequence_number: 1, amount: 2, signature: 'b' }
      ]
    };
    const result = validateReconciliationBatch(batch, 50);
    assert.equal(result.valid, false);
    assert.match(result.error, /Duplicate sequence number/);
  });
});

describe('reconciliation-ref memory storage', () => {
  it('detects duplicates after markProcessed', async () => {
    const storage = createStorage('memory');
    await storage.init();

    assert.equal(await storage.hasProcessed('device-a', 'wallet-a', 99), false);
    await storage.markProcessed('device-a', 'wallet-a', 99, { amount: 10 });
    assert.equal(await storage.hasProcessed('device-a', 'wallet-a', 99), true);

    const seeded = await storage.hasProcessed('test-device', 'test-wallet', 1);
    assert.equal(seeded, true);
  });

  it('fails closed for durable storage construction', () => {
    assert.throws(() => createStorage('durable'), /Production storage not implemented/);
  });
});
