pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ISocket} from "../../interfaces/ISocket.sol";

contract uniERC20 is ERC20, Ownable {
    address public socket;

    // Gas limits for executing message on destination chains
    mapping(uint256 => uint256) public destGasLimits;

    event UniTransfer(
        uint256 destChainSlug,
        address destReceiver,
        uint256 amount
    );

    event UniReceive(
        address sender,
        address destReceiver,
        uint256 amount,
        uint256 srcChainSlug
    );

    modifier onlySocket() {
        require(msg.sender == socket, "Not authorised");
        _;
    }

    constructor(
        uint256 initialSupply,
        address _socket,
        string memory tokenName,
        string memory tokenSymbol
    ) ERC20(tokenName, tokenSymbol) {
        socket = _socket;
        _mint(msg.sender, initialSupply);
    }

    /************************************************************************
        Config Functions 
    ************************************************************************/

    function connectRemoteToken(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external onlyOwner {
        ISocket(socket).connect(
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_
        );
    }

    function setSocketAddress(address _socket) external onlyOwner {
        socket = _socket;
    }

    function setDestChainGasLimit(
        uint256 _chainSlug,
        uint256 _gasLimit
    ) external onlyOwner {
        destGasLimits[_chainSlug] = _gasLimit;
    }

    /************************************************************************
        Cross-chain Token Transfer & Receive 
    ************************************************************************/

    /* Burns user tokens on source chain and sends mint message on destination chain */
    function uniTransfer(
        uint32 _destChainSlug,
        address _destReceiver,
        uint256 _amount
    ) external payable {
        _burn(msg.sender, _amount);

        bytes memory payload = abi.encode(msg.sender, _destReceiver, _amount);

        ISocket(socket).outbound{value: msg.value}(
            _destChainSlug,
            destGasLimits[_destChainSlug],
            bytes32(0),
            bytes32(0),
            payload
        );

        emit UniTransfer(_destChainSlug, _destReceiver, _amount);
    }

    /* Decodes destination data and mints equivalent tokens burnt on source chain */
    function _uniReceive(
        uint256 siblingChainSlug_,
        bytes calldata payload_
    ) internal {
        (address _sender, address _receiver, uint256 _amount) = abi.decode(
            payload_,
            (address, address, uint256)
        );

        _mint(_receiver, _amount);

        emit UniReceive(_sender, _receiver, _amount, siblingChainSlug_);
    }

    /* Called by Socket on destination chain when sending message */
    function inbound(
        uint256 siblingChainSlug_,
        bytes calldata payload_
    ) public onlySocket {
        _uniReceive(siblingChainSlug_, payload_);
    }
}
