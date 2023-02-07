// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IPlug {
    /**
     * @notice executes the message received from source chain
     * @dev this should be only executable by socket
     * @param siblingChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on destination
     */
    function inbound(
        uint256 siblingChainSlug_,
        bytes calldata payload_
    ) external;
}
