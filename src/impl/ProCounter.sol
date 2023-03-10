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

    function setNumber(
        uint256 newNumber_,
        uint256 toChainSlug_
    ) external payable {
        _outbound(toChainSlug_, destGasLimit, msg.value, abi.encode(newNumber_));
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
        uint256 start_,
        uint256 end_,
        uint256[] memory toChainSlugs_,
        uint256[] memory fees_
    ) external payable {
        bytes[] memory payloads;
        uint256[] memory destGasLimits;

        for (uint256 index = 0; index < end_ - start_; index++) {
            payloads[index] = abi.encode(start_ + index);
            destGasLimits[index] = destGasLimit;
        }

        _batch(
            destGasLimits,
            toChainSlugs_,
            fees_,
            payloads,
            this.createPayload
        );
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

    function setNumber(uint256 newNumber_) public {
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
        if (sender != owner) revert InvalidSender();
        (message, canExecute) = _checkSequence(tmpMsg);
    }
}
