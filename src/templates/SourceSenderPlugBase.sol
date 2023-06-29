// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";
import "../lib/BytesLib.sol";

abstract contract SourceSenderPlugBase is PlugBase {
    function _outboundWithSender(
        uint256 gasLimit_,
        uint32 chainSlug_,
        uint256 fees_,
        bytes memory message_
    ) internal {
        bytes memory newPayload = _addSender(message_);
        PlugBase._outbound(chainSlug_, gasLimit_, fees_, newPayload);
    }

    function _addSender(
        bytes memory message_
    ) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                message_,
                bytes32(uint256(uint160(address(msg.sender))))
            );
    }

    function _getSender(
        bytes memory payload_
    ) internal pure returns (bytes memory message, address sender) {
        uint256 pos = payload_.length - 32;

        // pos is increased by 12 (32 - 20) to avoid empty bytes
        address msgSender = address(
            bytes20(BytesLib.slice(payload_, pos + 12, 20))
        );

        message = BytesLib.slice(payload_, 0, pos);
        return (message, msgSender);
    }
}
