pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ISocket} from "../../interfaces/ISocket.sol";
import {PlugBase} from "../../base/PlugBase.sol";
import {Gauge} from "./extension/Gauge.sol";

contract GaugedUniERC20 is ERC20, PlugBase, Gauge {
    /**
     * @notice destination gasLimit of executing payload for respective chains
     */
    mapping(uint32 => uint256) public destGasLimits;

    event UniTransfer(
        uint32 destChainSlug,
        address destReceiver,
        uint256 amount
    );

    event UniReceive(
        address sender,
        address destReceiver,
        uint256 amount,
        uint32 srcChainSlug
    );

    modifier onlySocket() {
        require(msg.sender == address(socket), "Not Socket");
        _;
    }

    constructor(
        uint256 initialSupply,
        address _socket,
        string memory tokenName,
        string memory tokenSymbol
    ) ERC20(tokenName, tokenSymbol) PlugBase(_socket) {
        _mint(msg.sender, initialSupply);
    }

    /************************************************************************
        Config Functions 
    ************************************************************************/

    /**
     * @notice Sets destGasLimits required to mint & transfer tokens on destination chain
     * @param _chainSlug Chain Slug of chain for which destination gasLimit is being set
     * @param _gasLimit gasLimit value
     */
    function setDestChainGasLimit(
        uint32 _chainSlug,
        uint256 _gasLimit
    ) external onlyOwner {
        destGasLimits[_chainSlug] = _gasLimit;
    }

    /************************************************************************
        Cross-chain Token Transfer & Receive 
    ************************************************************************/

    /**
     * @notice uniTransfer transfers tokens from the source chain to the destination chain
     * @dev This function burns the tokens on the source chain, encodes details of the burn into a payload and passes the message to the destination chain by calling `outbound` on Socket.
     * @param _destChainSlug chainSlug of the chain the tokens are being sent to
     * @param _destReceiver address of receiver on the destination chain
     * @param _amount amount/value being transferred
     */
    function uniTransfer(
        uint32 _destChainSlug,
        address _destReceiver,
        uint256 _amount
    ) external payable {
        require(
            checkBurnValidity(_destChainSlug, _amount),
            "Out of limit range"
        );

        _burn(msg.sender, _amount);
        _useTokensBurnt(_destChainSlug, _amount);

        bytes memory payload = abi.encode(msg.sender, _destReceiver, _amount);

        _outbound(
            _destChainSlug,
            destGasLimits[_destChainSlug],
            msg.value,
            payload
        );

        emit UniTransfer(_destChainSlug, _destReceiver, _amount);
    }

    /**
     * @notice Decodes payload sent from `uniTransfer`, mints equivalent tokens burnt on source chain and transfer to receiver
     * @param siblingChainSlug_ chainSlug of the sibling chain the message was sent from
     * @param payload_ Payload sent in the message
     */
    function _uniReceive(
        uint32 siblingChainSlug_,
        bytes memory payload_
    ) internal {
        (address _sender, address _receiver, uint256 _amount) = abi.decode(
            payload_,
            (address, address, uint256)
        );

        require(
            checkMintValidity(siblingChainSlug_, _amount),
            "Out of limit range"
        );

        _mint(_receiver, _amount);
        _useTokensMinted(siblingChainSlug_, _amount);

        emit UniReceive(_sender, _receiver, _amount, siblingChainSlug_);
    }

    /**
     * @notice Calls _uniReceive function to relay message & transfer tokens on the destination chain
     * @dev
     * @param siblingChainSlug_ chainSlug of the sibling chain the message was sent from
     * @param payload_ Payload sent in the message
     */
    function _receiveInbound(
        uint32 siblingChainSlug_,
        bytes memory payload_
    ) internal virtual override onlySocket {
        _uniReceive(siblingChainSlug_, payload_);
    }
}
