// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PlugBase} from "./templates/PlugBase.sol";
pragma abicoder v2;

contract PingPong is PlugBase {
    uint256 constant public destGasLimit = 1000000;
    uint256 public localChainSlug;
    uint256 public fees=0.0001 ether;

    // event emitted every ping() to keep track of consecutive pings count
    event Ping(uint pings);

    // constructor requires the socket address for this chain
    constructor(address _socket) PlugBase(_socket) {
        localChainSlug = getChainSlug();
    }

    // pings the destination chain, along with the current number of pings sent
    function ping(
        uint256 toChainSlug, // send a ping to this destination slug 
        uint pings // the number of pings
    ) public payable {
        require(address(this).balance > 0, "no gas");

        emit Ping(++pings);

        // encode the payload with the number of pings
        bytes memory payload = abi.encode(pings, localChainSlug);
        outbound( 
            toChainSlug, 
            destGasLimit,
            fees,
            payload 
        );
    }

    function receiveInbound(bytes memory payload_) internal virtual override{ 
        // decode the number of pings sent thus far
        (uint pings, uint256 remoteChainSlug) = abi.decode(payload_, (uint, uint256));

        // *pong* back to the other side
        ping(remoteChainSlug, pings);
    }

    // allow this contract to receive ether
    receive() external payable {}
}