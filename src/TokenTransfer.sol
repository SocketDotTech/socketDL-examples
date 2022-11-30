// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {PlugBase} from "./templates/PlugBase.sol";
import "./interfaces/ISocket.sol";
import "./utils/Ownable.sol";

interface SpokePool {
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    ) external payable;

    function numberOfDeposits() external view returns (uint32);
}

struct Transfer {
    address recipient;
    uint256 amount;
    bool isDone;
}

contract TokenTransfer is PlugBase {
    using SafeERC20 for IERC20;

    address public token;
    uint64 public relayerFeePct;
    uint256 public chainId;
    mapping(string => Transfer) public transfers;

    SpokePool public immutable spokePool;
    event Deposit(
        uint256 toChainId,
        address recipient,
        uint256 amount,
        string depositId
    );
    event FullFilled(address recipient, uint256 amount, string depositId);
    event FullFilledFailed(address recipient, uint256 amount, string depositId);

    constructor(
        address socket_,
        address token_,
        address spokePool_,
        uint64 relayerFeePct_
    ) PlugBase(socket_) {
        token = token_;
        spokePool = SpokePool(spokePool_);
        relayerFeePct = relayerFeePct_;
        uint256 id;
        assembly {
            id := chainid()
        }
        chainId = id;
    }

    function bridgeAndTransfer(
        address receiver_,
        uint256 amount_,
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_
    ) external payable {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount_);
        IERC20(token).safeIncreaseAllowance(address(spokePool), amount_);
        uint32 numberOfDeposits = spokePool.numberOfDeposits();
        uint32 quoteTimestamp = uint32(block.timestamp);
        spokePool.deposit(
            receiver_,
            token,
            amount_,
            remoteChainSlug_,
            relayerFeePct,
            quoteTimestamp
        );

        string memory depositId = string(
            abi.encodePacked(numberOfDeposits, chainId)
        );
        emit Deposit(remoteChainSlug_, receiver_, amount_, depositId);
        bytes memory payload = abi.encode(receiver_, amount_, depositId);
        outbound(remoteChainSlug_, msgGasLimit_, msg.value, payload);
    }

    function rescueFunds(
        address _token,
        address _userAddress,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_userAddress, _amount);
    }

    function rescueEther(address payable _userAddress, uint256 _amount)
        external
        onlyOwner
    {
        _userAddress.transfer(_amount);
    }

    function _receiveInbound(bytes memory payload_)
        internal
        virtual
        override
    {
        (address receiver, uint256 amount, string memory depositId) = abi
            .decode(payload_, (address, uint256, string));

        try IERC20(token).transfer(receiver, amount) {
            transfers[depositId] = Transfer(receiver, amount, true);
            emit FullFilled(receiver, amount, depositId);
        } catch {
            transfers[depositId] = Transfer(receiver, amount, false);
            emit FullFilledFailed(receiver, amount, depositId);
        }
    }

    function retryClaim(string memory depositId) external payable {
        Transfer memory transfer = transfers[depositId];
        require(
            transfer.recipient != address(0),
            "TokenTransfer: Invalid depositId"
        );
        require(transfer.isDone == false, "TokenTransfer: Already claimed");
        _transfer(transfer.recipient, transfer.amount);
        transfers[depositId].isDone = true;
    }

    function _transfer(address receiver_, uint256 amount_) private {
        IERC20(token).transfer(receiver_, amount_);
    }
}
