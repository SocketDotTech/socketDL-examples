// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";

abstract contract SourceSenderPlugBase is PlugBase {
    function _outbound(
        uint256 gasLimit,
        uint256 chainSlug,
        uint256 fees,
        bytes calldata message
    ) internal {
        bytes memory newPayload = abi.encode(message, msg.sender);
        outbound(chainSlug, gasLimit, fees, newPayload);
    }

    function _beforeInbound(
        uint256,
        bytes memory payload_
    ) internal pure override returns (bytes memory, bool canExecute) {
        (bytes memory message, ) = abi.decode(payload_, (bytes, address));
        // add check related to sender and return canExecute as expected
        return (message, true);
    }
}
