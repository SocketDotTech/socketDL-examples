// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PlugBase} from "./templates/PlugBase.sol";

contract Counter is PlugBase {
    uint256 public number;

    constructor(address _socket) PlugBase(_socket) {
        owner = msg.sender;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function setNumber(uint256 newNumber, uint256 chainSlug) public payable {
        outbound(chainSlug, 1000000, abi.encode(newNumber));
    }

    function receiveInbound(bytes memory payload_) internal virtual override{ 
        uint256 newNumber = abi.decode(payload_, (uint256));
        setNumber(newNumber);
    }
}
