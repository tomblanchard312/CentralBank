import { describe, expect, it } from 'vitest';
import path from 'path';
import {
  assertProfileParametersCoherent,
  loadProfile,
  profileSchema,
} from '../src/config/profile';
import { loadParameters, parametersSchema } from '../src/config/parameters';

describe('eurosystem-reference profile coherence', () => {
  it('loads the repository profile and parameters together', () => {
    const profile = loadProfile(
      path.resolve(__dirname, '../../profiles/eurosystem-reference.json')
    );
    expect(profile.profile).toBe('eurosystem-reference');
    expect(profile.token.symbol).toBe('CBDT');
    expect(profile.platform).toBe('CentralBank');

    const parameters = loadParameters();
    expect(() => assertProfileParametersCoherent(profile, parameters)).not.toThrow();
  });

  it('rejects waterfall without holding limits', () => {
    const profile = profileSchema.parse({
      profile: 'broken',
      platform: 'CentralBank',
      protocol: 'CentralBank Digital Token Protocol',
      token: { name: 'Central Bank Digital Token', symbol: 'CBDT', decimals: 2 },
      denomination: { currency: 'EUR', minorUnit: 'cent' },
      policy: {
        holdingLimits: false,
        waterfall: true,
        reverseWaterfall: false,
        sanctions: false,
        emergencyControls: false,
        conditionalPayments: false,
      },
      disclaimer: 'test',
    });

    const parameters = parametersSchema.parse({
      holding_limit_individual: 0,
      holding_limit_merchant: 0,
      offline_cap_per_device: 1,
      transfer_velocity_limit_window_seconds: 60,
      transfer_velocity_limit_max_amount: 1,
      fee_transfer_basis_points: 0,
      governance_change_delay_seconds: 0,
      offline_reconciliation_window_seconds: 0,
      offline_daily_velocity_per_wallet: 0,
      fee_merchant_retail_bps: 0,
      fee_merchant_hospitality_bps: 0,
      fee_merchant_ecommerce_bps: 0,
      fee_instant_settlement_fixed_cents: 0,
      fee_cross_border_bps: 0,
      fee_atm_fixed_cents: 0,
      fee_atm_bps: 0,
      high_risk_countries: [],
      suspicious_volume_threshold_cents: 0,
      default_arbiter_address: '0x0000000000000000000000000000000000000001',
    });

    expect(() => assertProfileParametersCoherent(profile, parameters)).toThrow(
      /waterfall\/reverseWaterfall require policy.holdingLimits=true/
    );
  });
});
