pragma solidity 0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import {Gauge} from "./Gauge.sol";
import {PlugBase} from "./PlugBase.sol";

// @todo: separate our connecter plugs
contract Vault is PlugBase, Gauge {
    using SafeTransferLib for ERC20;
    ERC20 public token__;
    uint32 immutable _aevoSlug;
    mapping(address => uint256) public pendingUnlocks;
    LimitParams _lockLimitParams;
    LimitParams _unlockLimitParams;

    constructor(
        address token_,
        address socket_,
        uint32 aevoSlug_,
        LimitParams memory lockLimitParams_,
        LimitParams memory unlockLimitParams_
    ) PlugBase(socket_) {
        token__ = ERC20(token_);
        _aevoSlug = aevoSlug_;
        _lockLimitParams = lockLimitParams_;
        _unlockLimitParams = unlockLimitParams_;
    }

    // @todo: update only required
    function updateLockLimitParams(
        LimitParams calldata limitParams_
    ) external onlyOwner {
        _lockLimitParams = limitParams_;
    }

    // @todo: update only required
    function updateUnlockLimitParams(
        LimitParams calldata limitParams_
    ) external onlyOwner {
        _unlockLimitParams = limitParams_;
    }

    function depositToAevo(
        address receiver_,
        uint256 amount_,
        uint256 gasLimit_
    ) external payable {
        _consumeFullLimit(amount_, _lockLimitParams); // reverts on limit hit
        token__.safeTransferFrom(msg.sender, address(this), amount_);
        _outbound(
            _aevoSlug,
            gasLimit_,
            msg.value,
            abi.encode(receiver_, amount_)
        );
    }

    function unlockPendingFor(address receiver_) external {
        uint256 pendingUnlock = pendingUnlocks[receiver_];
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            pendingUnlock,
            _unlockLimitParams
        );
        pendingUnlocks[receiver_] = pendingAmount;
        token__.safeTransfer(receiver_, consumedAmount);
    }

    function _receiveInbound(
        uint32 /* siblingChainSlug_ */,
        bytes memory payload_
    ) internal override {
        (address receiver, uint256 unlockAmount) = abi.decode(
            payload_,
            (address, uint256)
        );
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            unlockAmount,
            _unlockLimitParams
        );
        if (pendingAmount > 0) {
            // add instead of overwrite to handle case where already pending amount is left
            pendingUnlocks[receiver] += pendingAmount;
        }
        token__.safeTransfer(receiver, consumedAmount);
    }
}