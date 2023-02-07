// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ISocket} from "../interfaces/ISocket.sol";

abstract contract PlugBase {
    address public owner;
    ISocket socket;

    constructor(address _socket) {
        owner = msg.sender;
        socket = ISocket(_socket);
    }

    //
    // Modifiers
    //
    modifier onlyOwner() {
        require(msg.sender == owner, "no auth");
        _;
    }

    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external onlyOwner {
        socket.connect(
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_
        );
    }

    function outbound(
        uint256 chainSlug,
        uint256 gasLimit,
        uint256 fees,
        bytes memory payload
    ) internal {
        socket.outbound{value: fees}(chainSlug, gasLimit, payload);
    }

    function inbound(
        uint256 siblingChainSlug_,
        bytes calldata payload_
    ) external payable {
        require(msg.sender == address(socket), "no auth");
        _receiveInbound(siblingChainSlug_, payload_);
    }

    function _receiveInbound(
        uint256 siblingChainSlug_,
        bytes memory payload_
    ) internal virtual;

    function getChainSlug() internal view returns (uint256) {
        return socket._chainSlug();
    }

    function removeOwner() external onlyOwner {
        owner = address(0);
    }
}
