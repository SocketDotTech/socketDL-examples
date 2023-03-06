// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";
import "../lib/BytesLib.sol";

abstract contract SequentialPlugBase is PlugBase {
    uint256 internal _msgCounter;
    uint256 private _offset;

    uint256 public latestMsgExecuted;
    mapping(uint256 => mapping(bytes => bool)) public executionBook;

    constructor(uint256 offset) {
        _offset = offset;
    }

    function _addCounter(
        bytes memory message_
    ) internal returns (bytes memory) {
        return abi.encodePacked(message_, _msgCounter++);
    }

    function sequentialOutbound(
        uint256 gasLimit,
        uint256 chainSlug,
        uint256 fees,
        bytes memory message
    ) internal {
        bytes memory newPayload = _addCounter(message);
        PlugBase.outbound(chainSlug, gasLimit, fees, newPayload);
    }

    function _checkSequence(
        bytes memory payload_
    ) internal returns (bytes memory message, bool canExecute) {
        uint256 msgCounter = uint256(
            bytes32(BytesLib.slice(payload_, _offset, 32))
        );

        if (msgCounter == latestMsgExecuted + 1) {
            canExecute = true;
            executionBook[msgCounter][payload_] = true;
            latestMsgExecuted++;
        }

        uint256 len = payload_.length - 32;
        message = BytesLib.slice(payload_, 0, len);

        return (message, canExecute);
    }
}
