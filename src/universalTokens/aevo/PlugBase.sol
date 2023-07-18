pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
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
