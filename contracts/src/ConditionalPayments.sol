// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interfaces/IConditionalPayments.sol";
import "./interfaces/IDigitalToken.sol";
import "./Permissioning.sol";

/**
 * @title ConditionalPayments
 * @notice Escrow-based conditional payment system for the CentralBank digital token.
 * @dev Conditional release does not make the token itself programmable money.
 *      Funds remain fungible; only release from escrow is conditional.
 */
contract ConditionalPayments is IConditionalPayments {
    IDigitalToken public immutable token;
    Permissioning public immutable permissioning;

    mapping(bytes32 => ConditionalPayment) private _payments;
    mapping(address => bytes32[]) private _payerPayments;
    mapping(address => bytes32[]) private _payeePayments;
    mapping(bytes32 => mapping(uint256 => bool)) private _milestones;
    mapping(bytes32 => bool) private _usedIdempotencyKeys;

    uint256 public constant MIN_EXPIRY = 1 hours;
    uint256 public constant MAX_EXPIRY = 365 days;
    uint256 public constant DEFAULT_EXPIRY = 30 days;

    error Unauthorized();
    error InvalidAmount();
    error InvalidExpiry();
    error PaymentNotFound();
    error PaymentNotPending();
    error PaymentExpired();
    error PaymentNotExpired();
    error ConditionNotMet();
    error NotArbiter();
    error NotDisputed();
    error AlreadyDisputed();
    error IdempotencyKeyUsed();
    error ZeroAddress();
    error InsufficientBalance();

    modifier onlyPayer(bytes32 paymentId) {
        if (_payments[paymentId].payer != msg.sender) revert Unauthorized();
        _;
    }

    modifier onlyPayee(bytes32 paymentId) {
        if (_payments[paymentId].payee != msg.sender) revert Unauthorized();
        _;
    }

    modifier onlyArbiter(bytes32 paymentId) {
        if (_payments[paymentId].arbiter != msg.sender) revert NotArbiter();
        _;
    }

    modifier paymentExists(bytes32 paymentId) {
        if (_payments[paymentId].createdAt == 0) revert PaymentNotFound();
        _;
    }

    modifier paymentPending(bytes32 paymentId) {
        if (_payments[paymentId].status != PaymentStatus.PENDING) revert PaymentNotPending();
        _;
    }

    modifier idempotent(bytes32 key) {
        if (_usedIdempotencyKeys[key]) revert IdempotencyKeyUsed();
        _usedIdempotencyKeys[key] = true;
        _;
    }

    constructor(address _token, address _permissioning) {
        if (_token == address(0) || _permissioning == address(0)) revert ZeroAddress();
        token = IDigitalToken(_token);
        permissioning = Permissioning(_permissioning);
    }

    function createConditionalPayment(
        address payee,
        uint256 amount,
        ConditionType conditionType,
        bytes32 conditionData,
        uint256 expiresAt,
        address arbiter,
        bytes32 idempotencyKey
    ) external idempotent(idempotencyKey) returns (bytes32 paymentId) {
        if (payee == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidAmount();
        if (expiresAt != 0 && (expiresAt < block.timestamp + MIN_EXPIRY || expiresAt > block.timestamp + MAX_EXPIRY)) {
            revert InvalidExpiry();
        }

        uint256 actualExpiry = expiresAt == 0 ? block.timestamp + DEFAULT_EXPIRY : expiresAt;

        paymentId = keccak256(abi.encodePacked(msg.sender, payee, amount, idempotencyKey, block.timestamp));

        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert InsufficientBalance();

        _payments[paymentId] = ConditionalPayment({
            paymentId: paymentId,
            payer: msg.sender,
            payee: payee,
            amount: amount,
            conditionType: conditionType,
            conditionData: conditionData,
            createdAt: block.timestamp,
            expiresAt: actualExpiry,
            status: PaymentStatus.PENDING,
            arbiter: arbiter
        });

        _payerPayments[msg.sender].push(paymentId);
        _payeePayments[payee].push(paymentId);

        emit ConditionalPaymentCreated(paymentId, msg.sender, payee, amount, conditionType, actualExpiry);
    }

    function confirmDelivery(bytes32 paymentId, bytes32 deliveryProof)
        external
        paymentExists(paymentId)
        paymentPending(paymentId)
    {
        ConditionalPayment storage payment = _payments[paymentId];

        if (payment.conditionType != ConditionType.DELIVERY) revert ConditionNotMet();

        bool authorized = (msg.sender == payment.payer) || permissioning.isOracle(msg.sender);
        if (!authorized) revert Unauthorized();

        emit DeliveryConfirmed(paymentId, msg.sender, deliveryProof);
        _releasePayment(paymentId, deliveryProof);
    }

    function confirmMilestone(bytes32 paymentId, uint256 milestoneIndex)
        external
        paymentExists(paymentId)
        paymentPending(paymentId)
    {
        ConditionalPayment storage payment = _payments[paymentId];

        if (payment.conditionType != ConditionType.MILESTONE) revert ConditionNotMet();

        bool authorized = (msg.sender == payment.payer) || permissioning.isOracle(msg.sender);
        if (!authorized) revert Unauthorized();

        _milestones[paymentId][milestoneIndex] = true;
        emit MilestoneCompleted(paymentId, milestoneIndex, msg.sender);

        uint256 totalMilestones = uint256(payment.conditionData);
        bool allComplete = true;
        for (uint256 i = 0; i < totalMilestones; i++) {
            if (!_milestones[paymentId][i]) {
                allComplete = false;
                break;
            }
        }

        if (allComplete) {
            _releasePayment(paymentId, bytes32(totalMilestones));
        }
    }

    function releasePayment(bytes32 paymentId, bytes32 proofOfCondition)
        external
        paymentExists(paymentId)
        paymentPending(paymentId)
    {
        ConditionalPayment storage payment = _payments[paymentId];

        if (payment.conditionType == ConditionType.TIME_LOCK) {
            uint256 unlockTime = uint256(payment.conditionData);
            if (block.timestamp < unlockTime) revert ConditionNotMet();
        } else if (payment.conditionType == ConditionType.NONE) {
            if (msg.sender != payment.payee) revert Unauthorized();
        } else {
            revert ConditionNotMet();
        }

        _releasePayment(paymentId, proofOfCondition);
    }

    function refundPayment(bytes32 paymentId, string calldata reason)
        external
        paymentExists(paymentId)
        paymentPending(paymentId)
        onlyPayer(paymentId)
    {
        _refundPayment(paymentId, reason);
    }

    function disputePayment(bytes32 paymentId, string calldata reason)
        external
        paymentExists(paymentId)
        paymentPending(paymentId)
    {
        ConditionalPayment storage payment = _payments[paymentId];

        if (msg.sender != payment.payer && msg.sender != payment.payee) {
            revert Unauthorized();
        }

        if (payment.arbiter == address(0)) revert NotArbiter();

        payment.status = PaymentStatus.DISPUTED;
        emit PaymentDisputed(paymentId, msg.sender, reason);
    }

    function resolveDispute(bytes32 paymentId, bool releaseToPayee)
        external
        paymentExists(paymentId)
        onlyArbiter(paymentId)
    {
        ConditionalPayment storage payment = _payments[paymentId];

        if (payment.status != PaymentStatus.DISPUTED) revert NotDisputed();

        if (releaseToPayee) {
            payment.status = PaymentStatus.RELEASED;
            token.transfer(payment.payee, payment.amount);
            emit PaymentReleased(paymentId, payment.payee, payment.amount, bytes32("DISPUTE_RESOLVED"));
        } else {
            payment.status = PaymentStatus.REFUNDED;
            token.transfer(payment.payer, payment.amount);
            emit PaymentRefunded(paymentId, payment.payer, payment.amount, "Dispute resolved in payer's favor");
        }

        emit DisputeResolved(paymentId, msg.sender, releaseToPayee);
    }

    function claimExpiredPayment(bytes32 paymentId) external paymentExists(paymentId) {
        ConditionalPayment storage payment = _payments[paymentId];

        if (payment.status != PaymentStatus.PENDING) revert PaymentNotPending();
        if (block.timestamp < payment.expiresAt) revert PaymentNotExpired();

        payment.status = PaymentStatus.EXPIRED;
        token.transfer(payment.payer, payment.amount);
        emit PaymentRefunded(paymentId, payment.payer, payment.amount, "Payment expired");
    }

    function _releasePayment(bytes32 paymentId, bytes32 proofOfCondition) internal {
        ConditionalPayment storage payment = _payments[paymentId];

        payment.status = PaymentStatus.RELEASED;
        token.transfer(payment.payee, payment.amount);

        emit PaymentReleased(paymentId, payment.payee, payment.amount, proofOfCondition);
    }

    function _refundPayment(bytes32 paymentId, string calldata reason) internal {
        ConditionalPayment storage payment = _payments[paymentId];

        payment.status = PaymentStatus.REFUNDED;
        token.transfer(payment.payer, payment.amount);

        emit PaymentRefunded(paymentId, payment.payer, payment.amount, reason);
    }

    function getPayment(bytes32 paymentId) external view returns (ConditionalPayment memory) {
        return _payments[paymentId];
    }

    function getPaymentsByPayer(address payer) external view returns (bytes32[] memory) {
        return _payerPayments[payer];
    }

    function getPaymentsByPayee(address payee) external view returns (bytes32[] memory) {
        return _payeePayments[payee];
    }

    function isConditionMet(bytes32 paymentId) external view returns (bool) {
        ConditionalPayment storage payment = _payments[paymentId];

        if (payment.conditionType == ConditionType.NONE) {
            return true;
        }

        if (payment.conditionType == ConditionType.TIME_LOCK) {
            return block.timestamp >= uint256(payment.conditionData);
        }

        if (payment.conditionType == ConditionType.MILESTONE) {
            uint256 totalMilestones = uint256(payment.conditionData);
            for (uint256 i = 0; i < totalMilestones; i++) {
                if (!_milestones[paymentId][i]) {
                    return false;
                }
            }
            return true;
        }

        return payment.status == PaymentStatus.RELEASED;
    }

    function isMilestoneComplete(bytes32 paymentId, uint256 milestoneIndex) external view returns (bool) {
        return _milestones[paymentId][milestoneIndex];
    }
}
