// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";
import "../lib/BytesLib.sol";

abstract contract SourceSenderPlugBase is PlugBase {
    uint256 private _offset;

    constructor(uint256 offset) {
        _offset = offset;
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

    function _outbound(
        uint256 gasLimit,
        uint256 chainSlug,
        uint256 fees,
        bytes memory message
    ) internal {
        bytes memory newPayload = _addSender(message);
        outbound(chainSlug, gasLimit, fees, newPayload);
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
