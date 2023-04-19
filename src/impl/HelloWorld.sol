// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title ISocket
 * @dev Interface that lets smart contracts interact with Socket
 */
interface ISocket {
    function outbound(
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable returns (bytes32 msgId);

    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    function getMinFees(
        uint256 msgGasLimit_,
        uint32 remoteChainSlug_,
        address plug_
    ) external view returns (uint256 totalFees);
}

/**
 * @title Hello World
 * @dev Sends "Hello World" message from one chain to another
 */
contract HelloWorld {
    string public message;
    uint256 destGasLimit = 100000;
    address owner;
    address socket;

    event MessageSent(uint256 destChainSlug, string message);

    event MessageReceived(uint256 srcChainSlug, string message);

    modifier isOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier isSocket() {
        require(msg.sender == socket, "Not Socket");
        _;
    }

    error InsufficientFees();

    constructor(address _socket) {
        owner = msg.sender;
        socket = _socket;
    }

    /************************************************************************
        Config Functions 
    ************************************************************************/

    /**
     * @dev Configures plug to send/receive message
     */
    function configurePlug(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external isOwner {
        ISocket(socket).connect(
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_
        );
    }

    /**
     * @dev Sets destination chain gas limit
     */
    function setDestGasLimit(uint256 _destGasLimit) external isOwner {
        destGasLimit = _destGasLimit;
    }

    /************************************************************************
        Send Messages
    ************************************************************************/

    /**
     * @dev Sends message to remote chain HelloWorld plug
     * @param remoteChainSlug_ Address of remote chain the message will be sent to
     */
    function sendMessage(uint256 remoteChainSlug_) external payable {
        uint256 totalFees = _getMinimumFees(destGasLimit, remoteChainSlug_);

        if (msg.value < totalFees) revert InsufficientFees();

        bytes memory payload = abi.encode("Hello World");

        ISocket(socket).outbound(remoteChainSlug_, destGasLimit, payload);

        emit MessageSent(remoteChainSlug_, message);
    }

    /************************************************************************
        Receive Messages
    ************************************************************************/

    function _getMinimumFees(
        uint256 msgGasLimit_,
        uint256 remoteChainSlug_
    ) internal view returns (uint256) {
        return
            ISocket(socket).getMinFees(
                msgGasLimit_,
                uint32(remoteChainSlug_),
                address(this)
            );
    }

    /**
     * @dev Sets new message on destination chain and emits event
     */
    function _receiveMessage(
        uint256 _srcChainSlug,
        string memory _message
    ) internal {
        message = _message;
        emit MessageReceived(_srcChainSlug, _message);
    }

    /**
     * @dev Called by Socket when sending destination payload
     */
    function inbound(
        uint256 srcChainSlug_,
        bytes calldata payload_
    ) external isSocket {
        string memory _message = abi.decode(payload_, (string));
        _receiveMessage(srcChainSlug_, _message);
    }
}
