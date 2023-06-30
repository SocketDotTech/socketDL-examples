// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";

abstract contract BroadcastPlugBase is PlugBase {
    function _broadcast(
        uint256 gasLimit_,
        uint32[] calldata chainSlugs_,
        uint256[] calldata fees_,
        bytes memory message_
    ) internal {
        for (uint256 index = 0; index < chainSlugs_.length; index++) {
            _outbound(chainSlugs_[index], gasLimit_, fees_[index], message_);
        }
    }
}
