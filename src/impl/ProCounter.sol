// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {BatchPlugBase} from "../templates/BatchPlugBase.sol";
import {BroadcastPlugBase} from "../templates/BroadcastPlugBase.sol";
import {UnicastPlugBase} from "../templates/UnicastPlugBase.sol";

import "../templates/SequentialPlugBase.sol";
import "../templates/SourceSenderPlugBase.sol";

contract ProCounter is
    BatchPlugBase,
    BroadcastPlugBase,
    SequentialPlugBase,
    UnicastPlugBase,
    SourceSenderPlugBase
{
    uint256 public number;
    uint256 public constant destGasLimit = 1000000;
    error InvalidSender();

    constructor(address socket_) PlugBase(socket_) {
        owner = msg.sender;
    }

    function setRemoteNumber(
        uint256 newNumber_,
        uint256 toChainSlug_
    ) external payable {
        bytes memory payload = abi.encode(newNumber_);

        // append sequential counter
        payload = _addCounter(payload);

        // append msg sender
        payload = _addSender(payload);

        _outbound(toChainSlug_, destGasLimit, msg.value, payload);
    }

    function createPayload(
        bytes memory payload_
    ) internal returns (bytes memory payload) {
        // append sequential counter
        payload = _addCounter(payload_);

        // append msg sender
        payload = _addSender(payload);
    }

    function setSequentialNumbers(
        uint256 start_,
        uint256 end_,
        uint256[] memory toChainSlugs_,
        uint256[] memory fees_
    ) external payable {
        uint256 len = end_ - start_;

        bytes[] memory payloads = new bytes[](len);
        uint256[] memory destGasLimits = new uint256[](len);

        for (uint256 index = 0; index < len; index++) {
            payloads[index] = abi.encode(start_ + index);
            destGasLimits[index] = destGasLimit;
        }

        _batch(destGasLimits, toChainSlugs_, fees_, payloads, createPayload);
    }

    function broadcastNumber(
        uint256 newNumber_,
        uint256[] calldata toChainSlugs_,
        uint256[] calldata fees_
    ) external payable {
        bytes memory payload = abi.encode(newNumber_);

        // append sequential counter
        payload = _addCounter(payload);

        // append msg sender
        payload = _addSender(payload);

        _broadcast(destGasLimit, toChainSlugs_, fees_, payload);
    }

    function unicastNumber(
        uint256 start_,
        uint256 end_,
        uint256 toChainSlug_,
        uint256 fees_
    ) external payable {
        uint256 len = end_ - start_;

        bytes[] memory payloads = new bytes[](len);
        uint256[] memory destGasLimits = new uint256[](len);

        for (uint256 index = 0; index < len; index++) {
            payloads[index] = abi.encode(start_ + index);
            destGasLimits[index] = destGasLimit;
        }

        _unicast(toChainSlug_, destGasLimit, fees_, payloads, createPayload);
    }

    function setLocalNumber(uint256 newNumber_) external {
        setNumber(newNumber_);
    }

    function setNumber(uint256 newNumber_) internal {
        number = newNumber_;
    }

    function _receiveInbound(
        uint256,
        bytes memory payload_
    ) internal virtual override {
        (bytes memory payload, bool canExecute) = _beforeInbound(payload_);

        if (!canExecute) return;
        uint256 newNumber = abi.decode(payload, (uint256));

        setNumber(newNumber);
    }

    function _beforeInbound(
        bytes memory payload_
    ) internal returns (bytes memory message, bool canExecute) {
        (bytes memory tmpMsg, address sender) = _getSender(payload_);

        if (sender != owner) return (tmpMsg, false);

        message = _checkSequence(tmpMsg);

        return (message, true);
    }
}
