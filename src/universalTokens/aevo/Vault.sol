pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import "solmate/utils/SafeTransferLib.sol";
import {ISocket} from "../../interfaces/ISocket.sol";

abstract contract PlugBase is Ownable2Step {
    ISocket public socket__;

    constructor(address socket_) {
        socket__ = ISocket(socket_);
    }

    function connect(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external onlyOwner {
        socket__.connect(
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_
        );
    }

    function inbound(
        uint32 siblingChainSlug_,
        bytes calldata payload_
    ) external payable {
        require(msg.sender == address(socket__), "no auth");
        _receiveInbound(siblingChainSlug_, payload_);
    }

    function _outbound(
        uint32 chainSlug_,
        uint256 gasLimit_,
        uint256 fees_,
        bytes memory payload_
    ) internal {
        socket__.outbound{value: fees_}(
            chainSlug_,
            gasLimit_,
            bytes32(0),
            bytes32(0),
            payload_
        );
    }

    function _receiveInbound(
        uint32 siblingChainSlug_,
        bytes memory payload_
    ) internal virtual;
}

// @todo: separate our connecter plugs
contract Vault is PlugBase {
    using SafeTransferLib for ERC20;
    ERC20 public token__;
    uint32 immutable _aevoSlug;
    mapping(address => uint256) public pendingUnlocks;

    constructor(
        address token_,
        address socket_,
        uint32 aevoSlug_
    ) PlugBase(socket_) {
        token__ = ERC20(token_);
        _aevoSlug = aevoSlug_;
    }

    // todo: impl local throttling
    function depositToAevo(
        address receiver_,
        uint256 amount_,
        uint256 gasLimit_
    ) external payable {
        token__.safeTransferFrom(msg.sender, address(this), amount_);
        _outbound(
            _aevoSlug,
            gasLimit_,
            msg.value,
            abi.encode(receiver_, amount_)
        );
    }

    // todo: impl local throttling, caching, pending
    function unlockPendingFor(address receiver_) external {
        uint256 pendingUnlock = pendingUnlocks[receiver_];
        pendingUnlocks[receiver_] = 0;
        token__.safeTransfer(receiver_, pendingUnlock);
    }

    // todo: impl local throttling, caching, pending
    function _receiveInbound(
        uint32 /* siblingChainSlug_ */,
        bytes memory payload_
    ) internal override {
        (address receiver, uint256 amount) = abi.decode(
            payload_,
            (uint256, address)
        );
        token__.safeTransfer(receiver, amount);
    }
}
