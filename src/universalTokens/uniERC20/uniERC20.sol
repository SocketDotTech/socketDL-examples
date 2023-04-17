pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ISocket} from "../../interfaces/ISocket.sol";

contract uniERC20 is ERC20 {
    address public socket;

    mapping(uint256 => uint256) public destGasLimits;

    mapping(uint256 => address) public uniPlugs;

    constructor(
        uint256 initialSupply,
        address _socket,
        string memory tokenName,
        string memory tokenSymbol
    ) ERC20(tokenName, tokenSymbol) {
        socket = _socket;
        _mint(msg.sender, initialSupply);
    }

    //  Add owner
    function connectUniTokenToSiblings(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external {
        ISocket(socket).connect(
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_
        );
    }

    //  Add owner
    function changeSocketAddress(address _socket) external {
        socket = _socket;
    }

    //  Add owner
    function chainDestGasLimit(uint256 _chainSlug, uint256 _gasLimit) external {
        destGasLimits[_chainSlug] = _gasLimit;
    }

    // Add owner
    function addUniPlug(uint _chainSlug, address _uniTokenAddress) public {
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
            destGasLimits[_destChainSlug],
            payload
        );
    }

    function _uniReceive(
        uint256 siblingChainSlug_,
        bytes calldata payload_
    ) internal {
        (address _sender, address _receiver, uint256 _amount) = abi.decode(
            payload_,
            (address, address, uint256)
        );

        _mint(_receiver, _amount);
    }

    // Make only Socket
    function inbound(
        uint256 siblingChainSlug_,
        bytes calldata payload_
    ) public {
        _uniReceive(siblingChainSlug_, payload_);
    }
}
