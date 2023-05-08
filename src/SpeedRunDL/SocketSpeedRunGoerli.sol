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
    address owner;

    /**
     * @dev Hardcoded values for Goerli
     */
    uint256 destGasLimit = 100000; // Gas cost of sending "Hello World" on Mumbai
    uint32 public remoteChainSlug = 80001; // Mumbai testnet chain ID
    address public socket = 0xA78426325b5e32Affd5f4Bc8ab6575B24DCB1762; // Socket Address on Goerli
    address public inboundSwitchboard =
        0x483D7e9dDBbbE0d376986168Ac4d94E35c485C69; // FAST Switchboard on Goerli
    address public outboundSwitchboard =
        0x483D7e9dDBbbE0d376986168Ac4d94E35c485C69; // FAST Switchboard on Goerli

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

    constructor() {
        owner = msg.sender;
    }

    /************************************************************************
        Config Functions 
    ************************************************************************/

    /**
     * @dev Configures plug to send/receive message
     */
    function connectPlug(address siblingPlug_) external isOwner {
        ISocket(socket).connect(
            remoteChainSlug,
            siblingPlug_,
            inboundSwitchboard,
            outboundSwitchboard
        );
    }

    /**
     * @dev Sets destination chain gas limit
     */
    function setDestGasLimit(uint256 _destGasLimit) external isOwner {
        destGasLimit = _destGasLimit;
    }

    function setRemoteChainSlug(uint32 _remoteChainSlug) external isOwner {
        remoteChainSlug = _remoteChainSlug;
    }

    function setSocketAddress(address _socket) external isOwner {
        socket = _socket;
    }

    function setSwitchboards(
        address _inboundSwitchboard,
        address _outboundSwitchboard
    ) external isOwner {
        inboundSwitchboard = _inboundSwitchboard;
        outboundSwitchboard = _outboundSwitchboard;
    }

    /************************************************************************
        Send Messages
    ************************************************************************/

    /**
     * @dev Sends message to remote chain HelloWorld plug
     */
    function sendMessage() external payable {
        uint256 totalFees = _getMinimumFees(destGasLimit, remoteChainSlug);

        if (msg.value < totalFees) revert InsufficientFees();

        bytes memory payload = abi.encode("Hello World");

        ISocket(socket).outbound{value: msg.value}(remoteChainSlug, destGasLimit, payload);

        emit MessageSent(remoteChainSlug, message);
    }

    function _getMinimumFees(
        uint256 msgGasLimit_,
        uint32 _remoteChainSlug
    ) internal view returns (uint256) {
        return
            ISocket(socket).getMinFees(
                msgGasLimit_,
                _remoteChainSlug,
                address(this)
            );
    }

    /************************************************************************
        Receive Messages
    ************************************************************************/

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
