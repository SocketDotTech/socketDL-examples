// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";
pragma abicoder v2;

contract PingPong is PlugBase {
    uint256 public constant destGasLimit = 1000000;
    uint256 public localChainSlug;
    uint256 public fees = 0.0001 ether;

    // event emitted every ping() to keep track of consecutive pings count
    event Ping(uint256 pings);

    // constructor requires the socket address for this chain
    constructor(address _socket) PlugBase(_socket) {
        localChainSlug = getChainSlug();
    }

    // pings the destination chain, along with the current number of pings sent
    function ping(
        uint256 toChainSlug, // send a ping to this destination slug
        uint256 pings // the number of pings
    ) public payable {
        require(address(this).balance > 0, "no gas");

        emit Ping(++pings);

        // encode the payload with the number of pings
        bytes memory payload = abi.encode(pings, localChainSlug);
        outbound(toChainSlug, destGasLimit, fees, payload);
    }

    function _receiveInbound(
        uint256 siblingChainSlug_,
        bytes memory payload_
    ) internal virtual override {
        // decode the number of pings sent thus far
        uint256 pings = abi.decode(payload_, (uint256));

        // *pong* back to the other side
        ping(siblingChainSlug_, pings);
    }

    // allow this contract to receive ether
    receive() external payable {}
}
