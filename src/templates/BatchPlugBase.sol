// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";

abstract contract BatchPlugBase is PlugBase {
    function _batch(
        uint256[] memory gasLimit,
        uint256[] memory chainSlugs,
        uint256[] memory fees,
        bytes[] memory payloads_,
        function(bytes memory) external returns (bytes memory) getPayloadFunction
    ) internal {
        for (uint256 index = 0; index < chainSlugs.length; index++) {
            bytes memory message = getPayloadFunction(payloads_[index]);
            outbound(chainSlugs[index], gasLimit[index], fees[index], message);
        }
    }
}
