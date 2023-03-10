// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";

abstract contract BatchPlugBase is PlugBase {
    function _batch(
        uint256[] memory gasLimit_,
        uint256[] memory chainSlugs_,
        uint256[] memory fees_,
        bytes[] memory payloads_,
        function(bytes memory) internal returns (bytes memory) createPayload_
    ) internal {
        for (uint256 index = 0; index < chainSlugs_.length; index++) {
            bytes memory message = createPayload_(payloads_[index]);
            _outbound(
                chainSlugs_[index],
                gasLimit_[index],
                fees_[index],
                message
            );
        }
    }
}
