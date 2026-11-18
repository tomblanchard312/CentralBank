import { describe, expect, it } from 'vitest';
import { CentralBankClient } from './client';

describe('CentralBankClient amount helpers', () => {
  it('converts euros to integer cents and cents back to euros', () => {
    expect(CentralBankClient.eurosToCents(12.34)).toBe(1234);
    expect(CentralBankClient.centsToEuros(1234)).toBe(12.34);
  });

  it('creates UUID-shaped idempotency keys', () => {
    expect(CentralBankClient.generateIdempotencyKey()).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
    );
  });
});
