// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";

abstract contract UnicastPlugBase is PlugBase {
    function _unicast(
        uint256 chainSlug,
        uint256 gasLimit,
        uint256 fees,
        bytes[] memory payloads_,
        function(bytes memory) external returns (bytes memory) getPayload
    ) internal {
        uint256 feesPerMessage = fees / payloads_.length;
        for (uint256 index = 0; index < payloads_.length; index++) {
            bytes memory message = getPayload(payloads_[index]);
            outbound(chainSlug, gasLimit, feesPerMessage, message);
        }
    }
}
