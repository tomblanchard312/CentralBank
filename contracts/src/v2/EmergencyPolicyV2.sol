// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/ITransferPolicyV2.sol";

/**
 * @title EmergencyPolicyV2
 * @notice Global transfer-pause policy for Protocol v2.
 * @dev Pause may be activated by the emergency authority. Recovery (unpause) requires
 *      dual control: one authorized actor proposes, a different authorized actor confirms.
 */
contract EmergencyPolicyV2 is ITransferPolicyV2 {
    address public immutable governance;
    address public emergencyAuthority;

    bool public transfersPaused;
    address public pendingUnpauseProposer;

    event EmergencyAuthorityUpdated(address indexed previousAuthority, address indexed newAuthority);
    event TransfersPaused(address indexed authority);
    event UnpauseProposed(address indexed proposer);
    event UnpauseConfirmed(address indexed confirmer);
    event UnpauseCancelled(address indexed cancelledBy);

    error Unauthorized();
    error ZeroAddress();
    error AlreadyPaused();
    error NotPaused();
    error NoPendingUnpause();
    error SelfConfirmation();
    error TransfersArePaused();

    modifier onlyGovernance() {
        if (msg.sender != governance) revert Unauthorized();
        _;
    }

    modifier onlyEmergencyAuthority() {
        if (msg.sender != emergencyAuthority) revert Unauthorized();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != governance && msg.sender != emergencyAuthority) revert Unauthorized();
        _;
    }

    constructor(address governanceAddress, address emergencyAuthorityAddress) {
        if (governanceAddress == address(0) || emergencyAuthorityAddress == address(0)) revert ZeroAddress();
        governance = governanceAddress;
        emergencyAuthority = emergencyAuthorityAddress;
    }

    function setEmergencyAuthority(address newAuthority) external onlyGovernance {
        if (newAuthority == address(0)) revert ZeroAddress();
        address previous = emergencyAuthority;
        emergencyAuthority = newAuthority;
        emit EmergencyAuthorityUpdated(previous, newAuthority);
    }

    function pauseTransfers() external onlyEmergencyAuthority {
        if (transfersPaused) revert AlreadyPaused();
        transfersPaused = true;
        pendingUnpauseProposer = address(0);
        emit TransfersPaused(msg.sender);
    }

    function proposeUnpause() external onlyAuthorized {
        if (!transfersPaused) revert NotPaused();
        pendingUnpauseProposer = msg.sender;
        emit UnpauseProposed(msg.sender);
    }

    function confirmUnpause() external onlyAuthorized {
        if (!transfersPaused) revert NotPaused();
        if (pendingUnpauseProposer == address(0)) revert NoPendingUnpause();
        if (msg.sender == pendingUnpauseProposer) revert SelfConfirmation();
        transfersPaused = false;
        address confirmer = msg.sender;
        pendingUnpauseProposer = address(0);
        emit UnpauseConfirmed(confirmer);
    }

    function cancelUnpauseProposal() external onlyAuthorized {
        if (pendingUnpauseProposer == address(0)) revert NoPendingUnpause();
        pendingUnpauseProposer = address(0);
        emit UnpauseCancelled(msg.sender);
    }

    function validateTransfer(address, address, address, uint256) external view {
        if (transfersPaused) revert TransfersArePaused();
    }
}
