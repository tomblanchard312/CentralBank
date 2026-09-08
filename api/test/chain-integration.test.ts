/**
 * Gateway-against-deployed-contracts integration test.
 *
 * These cases exercise the API ABI against a real local deployment. They are
 * skipped unless the integration RPC URL and deployed contract addresses exist.
 */
import { describe, it, expect, beforeAll } from 'vitest';
import { ethers } from 'ethers';
import {
  WalletRegistryABI,
  DigitalTokenABI,
  WalletType,
} from '../src/services/abi.js';

const rpcUrl = process.env['CENTRALBANK_INTEGRATION_RPC_URL'];
const registryAddress = process.env['CONTRACT_WALLET_REGISTRY'];
const tokenAddress = process.env['CONTRACT_DIGITAL_TOKEN'];

const configured = Boolean(rpcUrl && registryAddress && tokenAddress);

describe.skipIf(!configured)('gateway calldata against deployed contracts', () => {
  let provider: ethers.JsonRpcProvider;
  let operator: ethers.NonceManager;
  let operatorAddress: string;
  let registry: ethers.Contract;
  let token: ethers.Contract;
  let holder: ethers.Wallet;

  const bank = '0x00000000000000000000000000000000000000b1';
  const individual = '0x00000000000000000000000000000000000000a1';

  function keyFor(label: string): string {
    return ethers.keccak256(ethers.toUtf8Bytes(label));
  }

  beforeAll(async () => {
    provider = new ethers.JsonRpcProvider(rpcUrl);
    operator = new ethers.NonceManager(await provider.getSigner(0));
    operatorAddress = await operator.getAddress();
    registry = new ethers.Contract(registryAddress!, [...WalletRegistryABI], operator);
    token = new ethers.Contract(tokenAddress!, [...DigitalTokenABI], operator);

    holder = ethers.Wallet.createRandom().connect(provider);
    await (await operator.sendTransaction({
      to: holder.address,
      value: ethers.parseEther('1'),
    })).wait();
  });

  it('registers a bank, an individual, and the funded holder using contract enum ordinals', async () => {
    await (await registry.registerWallet(
      bank,
      WalletType.BANK,
      ethers.ZeroAddress,
      keyFor('kyc-bank'),
    )).wait();

    await (await registry.registerWallet(
      individual,
      WalletType.INDIVIDUAL,
      bank,
      keyFor('kyc-individual'),
    )).wait();

    await (await registry.registerWallet(
      holder.address,
      WalletType.INDIVIDUAL,
      bank,
      keyFor('kyc-holder'),
    )).wait();

    const bankInfo = await registry.getWalletInfo(bank);
    const individualInfo = await registry.getWalletInfo(individual);
    const holderInfo = await registry.getWalletInfo(holder.address);

    expect(Number(bankInfo.walletType)).toBe(WalletType.BANK);
    expect(Number(individualInfo.walletType)).toBe(WalletType.INDIVIDUAL);
    expect(Number(holderInfo.walletType)).toBe(WalletType.INDIVIDUAL);
    expect(holderInfo.isActive).toBe(true);
  });

  it('decodes WalletInfo in the contract struct order', async () => {
    const info = await registry.getWalletInfo(individual);

    expect(info.isActive).toBe(true);
    expect(ethers.getAddress(info.linkedBankAccount)).toBe(ethers.getAddress(bank));
    expect(info.kycHash).toBe(keyFor('kyc-individual'));
    expect(Number(info.registrationTime)).toBeGreaterThan(0);
  });

  it('mints with the three-argument contract signature', async () => {
    const before = await token.balanceOf(holder.address);
    await (await token.mint(holder.address, 100_00n, keyFor('mint-1'))).wait();
    const after = await token.balanceOf(holder.address);

    expect(after - before).toBe(100_00n);
  });

  it('rejects a duplicate mint idempotency key', async () => {
    await expect(
      token.mint(holder.address, 100_00n, keyFor('mint-1')),
    ).rejects.toThrow();
  });

  it('moves funds from the payer, not the operator, and requires an allowance', async () => {
    const asHolder = token.connect(holder) as ethers.Contract;
    const operatorBefore = await token.balanceOf(operatorAddress);

    // Use a read-only simulation for the expected failure. Sending an invalid
    // transaction makes ethers poll for a receipt/revert and can exceed Vitest's
    // default timeout even though the contract rejects it immediately.
    await expect(
      token.transferFrom.staticCall(holder.address, bank, 10_00n),
    ).rejects.toThrow();

    await (await asHolder.approve(operatorAddress, 10_00n)).wait();

    const holderBefore = await token.balanceOf(holder.address);
    const bankBefore = await token.balanceOf(bank);
    await (await token.transferFrom(holder.address, bank, 10_00n)).wait();

    expect(await token.balanceOf(holder.address)).toBe(holderBefore - 10_00n);
    expect(await token.balanceOf(bank)).toBe(bankBefore + 10_00n);
    expect(await token.balanceOf(operatorAddress)).toBe(operatorBefore);
  });

  it('exposes escrowedBalances as separate members, not a tuple', async () => {
    const record = await token.escrowedBalances(individual);
    expect(record.amount).toBeDefined();
    expect(typeof record.legalBasis).toBe('string');
    expect(record.expiry).toBeDefined();
  });
});
