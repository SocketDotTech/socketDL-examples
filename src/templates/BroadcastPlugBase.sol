// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";

abstract contract BroadcastPlugBase is PlugBase {
    function _broadcast(
        uint256 gasLimit,
        uint256[] calldata chainSlugs,
        uint256[] calldata fees,
        bytes calldata message
    ) internal {
        for (uint256 index = 0; index < chainSlugs.length; index++) {
            outbound(chainSlugs[index], gasLimit, fees[index], message);
        }
    }
}
