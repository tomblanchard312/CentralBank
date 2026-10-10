import { describe, expect, it } from 'vitest';
import { generatePaymentStatusReport } from './payment-status-report';

describe('generatePaymentStatusReport', () => {
  it('rejects malformed transaction IDs before making an API request', async () => {
    await expect(generatePaymentStatusReport('../admin')).rejects.toThrow(
      'Invalid transaction ID format',
    );
  });

  it('generates a statement from a supplied transaction record', async () => {
    const xml = await generatePaymentStatusReport('tx-123', {
      timestamp: '2026-10-09T12:00:00.000Z',
      from: '0x0000000000000000000000000000000000000001',
      to: '0x0000000000000000000000000000000000000002',
      fromBalanceBefore: 2500,
      fromBalanceAfter: 1500,
      amount: 1000,
      txHash: '0xabc123',
    });

    expect(xml).toContain('tx-123');
    expect(xml).toContain('0xabc123');
    expect(xml).toContain('10.00');
  });
});
