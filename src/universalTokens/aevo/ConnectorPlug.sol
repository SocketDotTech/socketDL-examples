pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ISocket} from "../../interfaces/ISocket.sol";

interface IApp {
    function receiveInbound(bytes memory payload_) external;
}

interface IConnector {
    function outbound(
        uint256 gasLimit_,
        bytes memory payload_
    ) external payable;

    function siblingChainSlug() external returns (uint32);
}

contract ConnectorPlug is IConnector, Ownable2Step {
    IApp public app__;
    ISocket public socket__;
    uint32 public immutable siblingChainSlug;

    error NotApp();
    error NotSocket();

    constructor(address app_, address socket_, uint32 siblingChainSlug_) {
        app__ = IApp(app_);
        socket__ = ISocket(socket_);
        siblingChainSlug = siblingChainSlug_;
    }

    function outbound(
        uint256 gasLimit_,
        bytes memory payload_
    ) external payable override {
        if (msg.sender != address(app__)) revert NotApp();

        socket__.outbound{value: msg.value}(
            siblingChainSlug,
            gasLimit_,
            bytes32(0),
            bytes32(0),
            payload_
        );
    }

    function inbound(
        uint32 /* siblingChainSlug_ */, // cannot be connected for any other slug, immutable variable
        bytes calldata payload_
    ) external payable {
        if (msg.sender != address(socket__)) revert NotSocket();
        app__.receiveInbound(payload_);
    }

    function connect(
        address siblingPlug_,
        address switchboard_
    ) external onlyOwner {
        socket__.connect(
            siblingChainSlug,
            siblingPlug_,
            switchboard_,
            switchboard_
        );
    }
}
