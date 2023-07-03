// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

/**
 * @title IMultiGaugeUniERC20
 * @notice Interface for MultiGaugeUniERC20
 */
interface IMultiGaugeUniERC20 {
    function uniReceive(
        uint32 siblingChainSlug_,
        bytes memory payload_
    ) external payable;
}
