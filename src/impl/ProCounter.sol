// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {BatchPlugBase} from "../templates/BatchPlugBase.sol";
import {BroadcastPlugBase} from "../templates/BroadcastPlugBase.sol";

import "../templates/SequentialPlugBase.sol";
import "../templates/SourceSenderPlugBase.sol";

contract ProCounter is
    BatchPlugBase,
    BroadcastPlugBase,
    SequentialPlugBase,
    SourceSenderPlugBase
{
    uint256 public number;
    uint256 public constant destGasLimit = 1000000;
    error InvalidSender();

    constructor(
        address socket_,
        uint256 sequentialOffset_,
        uint256 senderOffset_
    )
        PlugBase(socket_)
        SequentialPlugBase(sequentialOffset_)
        SourceSenderPlugBase(senderOffset_)
    {
        owner = msg.sender;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function setNumber(uint256 newNumber, uint256 toChainSlug) public payable {
        outbound(toChainSlug, destGasLimit, msg.value, abi.encode(newNumber));
    }

    function createPayload(
        bytes memory payload_
    ) external returns (bytes memory payload) {
        // append sequential counter
        payload = _addCounter(payload_);

        // append msg sender
        payload = _addSender(payload_);
    }

    function setSequentialNumbers(
        uint256 start,
        uint256 end,
        uint256[] memory toChainSlugs,
        uint256[] memory fees
    ) external payable {
        bytes[] memory payloads;
        uint256[] memory destGasLimits;

        for (uint256 index = 0; index < end - start; index++) {
            payloads[index] = abi.encode(start + index);
            destGasLimits[index] = destGasLimit;
        }

        _batch(destGasLimits, toChainSlugs, fees, payloads, this.createPayload);
    }

    function broadcastNumber(
        uint256 newNumber,
        uint256[] calldata toChainSlugs,
        uint256[] calldata fees
    ) public payable {
        bytes memory payload = abi.encode(newNumber);

        // append sequential counter
        payload = _addCounter(payload);

        // append msg sender
        payload = _addSender(payload);

        _broadcast(destGasLimit, toChainSlugs, fees, payload);
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
        if (sender != owner) revert InvalidSender();
        (message, canExecute) = _checkSequence(tmpMsg);
    }
}
