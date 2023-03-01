// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";

abstract contract UnicastPlugBase is PlugBase {
    function _unicast(
        uint256 chainSlug,
        uint256 gasLimit,
        uint256 fees,
        bytes[] calldata payload
    ) internal {
        uint256 feesPerMessage = fees / payload.length;
        for (uint256 index = 0; index < payload.length; index++) {
            outbound(chainSlug, gasLimit, feesPerMessage, payload[index]);
        }
    }
}
