// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IPlug.sol";
import "../interfaces/ISocket.sol";
import "../utils/Ownable.sol";

interface SpokePool {
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    ) external payable;
}

contract TokenTransfer is IPlug, Ownable(msg.sender) {
    using SafeERC20 for IERC20;

    // immutables
    address private immutable socket;
    address public token;
    uint64 public relayerFeePct;
    uint32 public quoteTimestamp;

    SpokePool public immutable spokePool;

    constructor(
        address socket_,
        address token_,
        address spokePool_,
        uint64 relayerFeePct_,
        uint32 quoteTimestamp_
    ) {
        socket = socket_;
        token = token_;
        spokePool = SpokePool(spokePool_);

        relayerFeePct = relayerFeePct_;
        quoteTimestamp = quoteTimestamp_;
    }

    function bridgeAndTransfer(
        address receiver_,
        uint256 amount_,
        uint256 remoteChainSlug_,
        uint256 remoteChainId_,
        uint256 msgGasLimit_
    ) external payable {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount_);
        IERC20(token).safeIncreaseAllowance(address(spokePool), amount_);

        spokePool.deposit(
            receiver_,
            token,
            amount_,
            remoteChainId_,
            relayerFeePct,
            quoteTimestamp
        );

        bytes memory payload = abi.encode(receiver_, amount_);
        _outbound(remoteChainSlug_, msgGasLimit_, payload);
    }

    function inbound(
        uint256,
        bytes calldata payload_
    ) external payable override {
        require(msg.sender == socket, "Counter: Invalid Socket");
        (address receiver, uint256 amount) = abi.decode(
            payload_,
            (address, uint256)
        );

        _transfer(receiver, amount);
    }

    function _outbound(
        uint256 targetChain_,
        uint256 msgGasLimit_,
        bytes memory payload_
    ) private {
        ISocket(socket).outbound{value: msg.value}(
            targetChain_,
            msgGasLimit_,
            payload_
        );
    }

    function _transfer(address receiver_, uint256 amount_) private {
        IERC20(token).transfer(receiver_, amount_);
    }

    // settings
    function setSocketConfig(
        uint256 remoteChainSlug,
        address remotePlug,
        string calldata integrationType
    ) external onlyOwner {
        ISocket(socket).setPlugConfig(
            remoteChainSlug,
            remotePlug,
            integrationType,
            integrationType
        );
    }
}
