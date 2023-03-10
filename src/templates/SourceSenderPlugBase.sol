// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";
import "../lib/BytesLib.sol";

abstract contract SourceSenderPlugBase is PlugBase {
    uint256 private _offset;

    constructor(uint256 offset_) {
        _offset = offset_;
    }

    function _outboundWithSender(
        uint256 gasLimit_,
        uint256 chainSlug_,
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
    ) internal view returns (bytes memory message, address sender) {
        address msgSender = address(
            bytes20(BytesLib.slice(payload_, _offset, 20))
        );

        uint256 len = payload_.length - 20;
        message = BytesLib.slice(payload_, 0, len);

        return (message, msgSender);
    }
}
