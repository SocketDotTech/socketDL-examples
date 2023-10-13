// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

/**
 * @title IConnectionPlug
 * @notice Interface for IConnectionPlug
 */
interface IConnectionPlug {
    function outboundTransfer(
        uint32 _destChainSlug,
        uint256 _minGasLimit,
        bytes memory payload_
    ) external payable;
}
