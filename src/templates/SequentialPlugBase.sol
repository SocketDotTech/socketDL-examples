// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";
import "../lib/BytesLib.sol";

abstract contract SequentialPlugBase is PlugBase {
    uint256 internal _msgCounter = 1;

    uint256 public latestMsgExecuted;

    error NotInOrder();

    function _addCounter(
        bytes memory message_
    ) internal returns (bytes memory) {
        return abi.encodePacked(message_, _msgCounter++);
    }

    function _sequentialOutbound(
        uint256 gasLimit_,
        uint32 chainSlug_,
        uint256 fees_,
        bytes memory message_
    ) internal {
        bytes memory newPayload = _addCounter(message_);
        _outbound(chainSlug_, gasLimit_, fees_, newPayload);
    }

    function _checkSequence(
        bytes memory payload_
    ) internal returns (bytes memory message) {
        uint256 pos = payload_.length - 32;
        uint256 msgCounter = uint256(
            bytes32(BytesLib.slice(payload_, pos, 32))
        );

        if (msgCounter != latestMsgExecuted + 1) revert NotInOrder();
        latestMsgExecuted++;

        message = BytesLib.slice(payload_, 0, pos);
    }
}
