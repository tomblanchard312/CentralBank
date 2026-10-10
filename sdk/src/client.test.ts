import { describe, expect, it } from 'vitest';
import { TEurClient } from './client';

describe('TEurClient amount helpers', () => {
  it('converts euros to integer cents and cents back to euros', () => {
    expect(TEurClient.eurosToCents(12.34)).toBe(1234);
    expect(TEurClient.centsToEuros(1234)).toBe(12.34);
  });

  it('creates UUID-shaped idempotency keys', () => {
    expect(TEurClient.generateIdempotencyKey()).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
    );
  });
});
