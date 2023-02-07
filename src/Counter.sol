// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import {PlugBase} from "./templates/PlugBase.sol";

contract Counter is PlugBase {
    uint256 public number;
    uint256 public constant destGasLimit = 1000000;

    constructor(address _socket) PlugBase(_socket) {
        owner = msg.sender;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function setNumber(uint256 newNumber, uint256 toChainSlug) public payable {
        outbound(toChainSlug, destGasLimit, msg.value, abi.encode(newNumber));
    }

    function _receiveInbound(
        uint256,
        bytes memory payload_
    ) internal virtual override {
        uint256 newNumber = abi.decode(payload_, (uint256));
        setNumber(newNumber);
    }
}
