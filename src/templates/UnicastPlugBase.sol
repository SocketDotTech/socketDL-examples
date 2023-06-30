// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";

abstract contract UnicastPlugBase is PlugBase {
    function _unicast(
        uint32 chainSlug_,
        uint256 gasLimit_,
        uint256 fees_,
        bytes[] memory payloads_,
        function(bytes memory) internal returns (bytes memory) createPayload_
    ) internal {
        uint256 feesPerMessage = fees_ / payloads_.length;
        for (uint256 index = 0; index < payloads_.length; index++) {
            bytes memory message = createPayload_(payloads_[index]);
            _outbound(chainSlug_, gasLimit_, feesPerMessage, message);
        }
    }
}
