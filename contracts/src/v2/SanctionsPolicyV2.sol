// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/ITransferPolicyV2.sol";

/**
 * @title SanctionsPolicyV2
 * @notice Freeze-only sanctions enforcement for Protocol v2 transfers.
 * @dev Stores opaque case-reference hashes only. No legal narrative or PII on-chain.
 *      Wired through CompositeTransferPolicyV2 into TokenLedgerV2._move.
 */
contract SanctionsPolicyV2 is ITransferPolicyV2 {
    address public immutable governance;
    address public sanctionsAuthority;

    mapping(address => bool) public frozenAccounts;
    mapping(address => bytes32) public caseReferenceHash;

    event SanctionsAuthorityUpdated(address indexed previousAuthority, address indexed newAuthority);
    event AccountFrozen(address indexed account, bytes32 indexed caseReferenceHash, address indexed authority);
    event AccountUnfrozen(address indexed account, address indexed authority);

    error Unauthorized();
    error ZeroAddress();
    error InvalidReference();
    error AccountIsFrozen(address account);
    error AccountNotFrozen(address account);

    modifier onlyGovernance() {
        if (msg.sender != governance) revert Unauthorized();
        _;
    }

    modifier onlySanctionsAuthority() {
        if (msg.sender != sanctionsAuthority) revert Unauthorized();
        _;
    }

    constructor(address governanceAddress, address sanctionsAuthorityAddress) {
        if (governanceAddress == address(0) || sanctionsAuthorityAddress == address(0)) revert ZeroAddress();
        governance = governanceAddress;
        sanctionsAuthority = sanctionsAuthorityAddress;
    }

    function setSanctionsAuthority(address newAuthority) external onlyGovernance {
        if (newAuthority == address(0)) revert ZeroAddress();
        address previous = sanctionsAuthority;
        sanctionsAuthority = newAuthority;
        emit SanctionsAuthorityUpdated(previous, newAuthority);
    }

    function freezeAccount(address account, bytes32 caseRefHash) external onlySanctionsAuthority {
        if (account == address(0)) revert ZeroAddress();
        if (caseRefHash == bytes32(0)) revert InvalidReference();
        frozenAccounts[account] = true;
        caseReferenceHash[account] = caseRefHash;
        emit AccountFrozen(account, caseRefHash, msg.sender);
    }

    function unfreezeAccount(address account) external onlySanctionsAuthority {
        if (account == address(0)) revert ZeroAddress();
        if (!frozenAccounts[account]) revert AccountNotFrozen(account);
        frozenAccounts[account] = false;
        caseReferenceHash[account] = bytes32(0);
        emit AccountUnfrozen(account, msg.sender);
    }

    function validateTransfer(address, address from, address to, uint256) external view {
        if (frozenAccounts[from]) revert AccountIsFrozen(from);
        if (frozenAccounts[to]) revert AccountIsFrozen(to);
    }
}
