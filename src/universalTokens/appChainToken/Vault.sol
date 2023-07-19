pragma solidity 0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Gauge} from "./Gauge.sol";
import {IConnector, IHub} from "./ConnectorPlug.sol";

// @todo: separate our connecter plugs
contract Vault is Gauge, IHub, Ownable2Step {
    using SafeTransferLib for ERC20;
    ERC20 public token__;
    uint32 immutable _appChainSlug;

    // connector => receiver => pendingUnlock
    mapping(address => mapping(address => uint256)) public pendingUnlocks;

    // connector => lockLimitParams
    mapping(address => LimitParams) _lockLimitParams;

    // connector => unlockLimitParams
    mapping(address => LimitParams) _unlockLimitParams;

    error ConnectorUnavailable();
    error LengthMismatch();

    constructor(address token_, uint32 appChainSlug_) {
        token__ = ERC20(token_);
        _appChainSlug = appChainSlug_;
    }

    // @todo: update only required
    function updateLockLimitParams(
        address[] calldata connectors_,
        LimitParams[] calldata limitParams_
    ) external onlyOwner {
        if (connectors_.length != limitParams_.length) revert LengthMismatch();
        for (uint256 i; i < connectors_.length; i++) {
            _lockLimitParams[connectors_[i]] = limitParams_[i];
        }
    }

    // @todo: update only required
    function updateUnlockLimitParams(
        address[] calldata connectors_,
        LimitParams[] calldata limitParams_
    ) external onlyOwner {
        if (connectors_.length != limitParams_.length) revert LengthMismatch();
        for (uint256 i; i < connectors_.length; i++) {
            _unlockLimitParams[connectors_[i]] = limitParams_[i];
        }
    }

    function depositToAppChain(
        address receiver_,
        uint256 amount_,
        uint256 gasLimit_,
        address connector_
    ) external payable {
        if (_lockLimitParams[connector_].maxLimit == 0)
            revert ConnectorUnavailable();

        _consumeFullLimit(amount_, _lockLimitParams[connector_]); // reverts on limit hit

        token__.safeTransferFrom(msg.sender, address(this), amount_);

        IConnector(connector_).outbound{value: msg.value}(
            gasLimit_,
            abi.encode(receiver_, amount_)
        );
    }

    function unlockPendingFor(address receiver_, address connector_) external {
        if (_unlockLimitParams[connector_].maxLimit == 0)
            revert ConnectorUnavailable();

        uint256 pendingUnlock = pendingUnlocks[connector_][receiver_];
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            pendingUnlock,
            _unlockLimitParams[connector_]
        );

        pendingUnlocks[connector_][receiver_] = pendingAmount;
        token__.safeTransfer(receiver_, consumedAmount);
    }

    // receive inbound assuming connector called
    // if connector is not configured (malicious), its unlock amount will forever stay in pending
    function receiveInbound(bytes memory payload_) external override {
        (address receiver, uint256 unlockAmount) = abi.decode(
            payload_,
            (address, uint256)
        );

        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            unlockAmount,
            _unlockLimitParams[msg.sender]
        );

        if (pendingAmount > 0) {
            // add instead of overwrite to handle case where already pending amount is left
            pendingUnlocks[msg.sender][receiver] += pendingAmount;
        }
        token__.safeTransfer(receiver, consumedAmount);
    }
}
