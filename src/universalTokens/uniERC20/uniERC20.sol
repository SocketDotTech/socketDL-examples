pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ISocket} from "../../interfaces/ISocket.sol";

contract uniERC20 is ERC20 {
    address public socket;

    mapping(uint256 => uint256) public destGasLimits;

    mapping(uint256 => address) public uniPlugs;

    constructor(
        uint256 initialSupply,
        address _socket,
        string tokenName,
        string tokenSymbol
    ) ERC20(tokenName, tokenSymbol) {
        socket = _socket;
        _mint(msg.sender, initialSupply);
    }

    //  Add owner
    function changeSocketAddress(address _socket) external {
        socket = _socket;
    }

    //  Add owner
    function chainDestGasLimit(uint256 _chainSlug, uint256 _gasLimit) external {
        destGasLimits[_chainSlug] = _gasLimit;
    }

    function addUniPlug(uint _chainSlug, address _uniTokenAddress) {
        uniPlugs[_chainSlug] = _uniTokenAddress;
    }

    function uniTransfer(
        uint256 _destChainSlug,
        address _destReceiver,
        uint256 _amount
    ) external payable {
        _burn(msg.sender, _amount);

        bytes memory payload = abi.encode(msg.sender, _destReceiver, _amount);

        ISocket(socket).outbound(
            _destChainSlug,
            destGasLimits(_destChainSlug),
            payload
        );
    }

    // Make only Socket
    function inbound(
        uint256 siblingChainSlug_,
        bytes calldata payload_
    ) public {
        uniReceive(siblingChainSlug_, payload_);
    }

    function uniReceive(
        uint256 siblingChainSlug_,
        bytes calldata payload_
    ) external payable {
        (senderAddress, receiverAddress, sendingAmount) = abi.decode(
            payload_,
            (address, address, uint256)
        );

        _mint(receiverAddress, sendingAmount);
    }
}
