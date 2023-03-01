// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";

abstract contract SequentialPlugBase is PlugBase {
    uint256 internal _msgCounter;

    uint256 public latestMsgExecuted;
    mapping(uint256 => mapping(bytes => bool)) public executionBook;

    function sequentialOutbound(
        uint256 gasLimit,
        uint256 chainSlug,
        uint256 fees,
        bytes calldata message
    ) internal {
        bytes memory newPayload = abi.encode(message, _msgCounter++);
        PlugBase.outbound(chainSlug, gasLimit, fees, newPayload);
    }

    function _beforeInbound(
        uint256,
        bytes memory payload_
    ) internal override returns (bytes memory, bool canExecute) {
        (bytes memory message, uint256 msgCounter) = abi.decode(
            payload_,
            (bytes, uint256)
        );

        if (msgCounter == latestMsgExecuted + 1) {
            canExecute = true;
            executionBook[msgCounter][message] = true;
            latestMsgExecuted++;
        }

        return (message, canExecute);
    }
}
