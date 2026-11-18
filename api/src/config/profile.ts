import fs from 'fs';
import path from 'path';
import { z } from 'zod';
import type { Parameters } from './parameters';

export const profileSchema = z.object({
  profile: z.string().min(1),
  platform: z.literal('CentralBank'),
  protocol: z.string().min(1),
  token: z.object({
    name: z.string().min(1),
    symbol: z.literal('CBDT'),
    decimals: z.number().int().nonnegative(),
  }),
  denomination: z.object({
    currency: z.string().min(1),
    minorUnit: z.string().min(1),
  }),
  policy: z.object({
    holdingLimits: z.boolean(),
    waterfall: z.boolean(),
    reverseWaterfall: z.boolean(),
    sanctions: z.boolean(),
    emergencyControls: z.boolean(),
    conditionalPayments: z.boolean(),
  }),
  disclaimer: z.string().min(1),
});

export type DeploymentProfile = z.infer<typeof profileSchema>;

const defaultProfilePath = path.resolve(__dirname, '../../../profiles/eurosystem-reference.json');

export function resolveProfilePath(): string {
  return process.env['PROFILE_FILE'] || defaultProfilePath;
}

export function loadProfile(filePath: string = resolveProfilePath()): DeploymentProfile {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Deployment profile not found: ${filePath}`);
  }
  const raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  return profileSchema.parse(raw);
}

/**
 * Fail closed when the active profile enables a policy that parameters cannot support.
 * This is a thin bridge: profile JSON remains the policy intent; parameters.json remains
 * the numeric runtime rulebook until a full profile runtime loader exists.
 */
export function assertProfileParametersCoherent(
  profile: DeploymentProfile,
  parameters: Parameters
): void {
  const errors: string[] = [];

  if (profile.token.decimals !== 2 && profile.denomination.currency === 'EUR') {
    errors.push('eurosystem-style EUR denomination expects token.decimals=2');
  }

  if (profile.policy.holdingLimits) {
    if (parameters.holding_limit_individual <= 0) {
      errors.push('policy.holdingLimits requires holding_limit_individual > 0');
    }
    if (parameters.holding_limit_merchant <= 0) {
      errors.push('policy.holdingLimits requires holding_limit_merchant > 0');
    }
  }

  if (profile.policy.waterfall || profile.policy.reverseWaterfall) {
    if (!profile.policy.holdingLimits) {
      errors.push('waterfall/reverseWaterfall require policy.holdingLimits=true');
    }
  }

  if (profile.policy.conditionalPayments) {
    if (!/^0x[a-fA-F0-9]{40}$/.test(parameters.default_arbiter_address)) {
      errors.push('policy.conditionalPayments requires a valid default_arbiter_address');
    }
  }

  if (errors.length > 0) {
    throw new Error(
      `Profile/parameters coherence failed for ${profile.profile}: ${errors.join('; ')}`
    );
  }
}

export function loadAndValidateProfile(parameters: Parameters): DeploymentProfile {
  const profile = loadProfile();
  assertProfileParametersCoherent(profile, parameters);
  return profile;
}
