// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";

contract Counter is PlugBase {
    uint256 public number;
    uint256 public constant destGasLimit = 1000000;

    constructor(address socket_) PlugBase(socket_) {
        owner = msg.sender;
    }

    function setRemoteNumber(
        uint256 newNumber_,
        uint32 toChainSlug_
    ) external payable {
        _outbound(
            toChainSlug_,
            destGasLimit,
            msg.value,
            abi.encode(newNumber_)
        );
    }

    function setLocalNumber(uint256 newNumber_) external {
        setNumber(newNumber_);
    }

    function setNumber(uint256 newNumber_) internal {
        number = newNumber_;
    }

    function _receiveInbound(
        uint32,
        bytes memory payload_
    ) internal virtual override {
        uint256 newNumber = abi.decode(payload_, (uint256));
        setNumber(newNumber);
    }
}
