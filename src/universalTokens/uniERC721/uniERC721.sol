pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ISocket} from "../../interfaces/ISocket.sol";
import {PlugBase} from "../../base/PlugBase.sol";

contract uniERC721 is ERC721, PlugBase {
    uint256 mintedTokenId;
    bool isMintingAllowed;

    /**
     * @notice destination gasLimit of executing payload for respective chains
     */
    mapping(uint32 => uint256) public destGasLimits;

    modifier onlySocket() {
        require(msg.sender == address(socket), "Not Socket");
        _;
    }

    /**
     * @notice set to define if NFT can be minted on a given chain
     */
    modifier mintingAllowed() {
        require(isMintingAllowed, "Minting not allowed");
        _;
    }

    event TokenMinted(address minter, uint256 tokenId);

    event UniTransfer(
        uint32 destChainSlug,
        address destReceiver,
        uint256 tokenId
    );

    event UniReceive(
        address sender,
        address destReceiver,
        uint256 tokenId,
        uint32 srcChainSlug
    );

    /**
     * @notice Initiatls uniERC721, ERC721 and PlugBase
     * @dev isMintingAllowed_ should be enabled only on a single instance/chain for this example contract
     * @param socket_ Address of Socket on respective chain
     * @param name_ Name of NFT token
     * @param symbol_ Symbol of token
     * @param isMintingAllowed_ Boolean set to enable minting on a given chain
     */
    constructor(
        address socket_,
        string memory name_,
        string memory symbol_,
        bool isMintingAllowed_
    ) ERC721(name_, symbol_) PlugBase(socket_) {
        isMintingAllowed = isMintingAllowed_;
    }

    /************************************************************************
        Config Functions 
    ************************************************************************/

    /**
     * @notice Sets isMintingAllowed_ allowed value
     * @param _val boolean value to be set
     */
    function setIsMintingAllowed(bool _val) external onlyOwner {
        isMintingAllowed = _val;
    }

    /**
     * @notice Sets destGasLimits required to mint & transfer token on destination chain
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
        Minting & Transfering NFT
    ************************************************************************/

    /**
     * @notice mints a token to msg.sender if minting is allowed
     */
    function mintToken() public mintingAllowed {
        _safeMint(msg.sender, mintedTokenId);
        mintedTokenId++;
        emit TokenMinted(msg.sender, mintedTokenId);
    }

    /**
     * @notice uniTransfer transfers NFT from the source chain to the destination chain
     * @dev This function burns the NFT token by tokenId on the source chain, encodes details of the burn into a payload and passes the message to the destination chain by calling `outbound` on Socket.
     * @param _destChainSlug chainSlug of the chain the NFT are being sent to
     * @param _destReceiver address of receiver on the destination chain
     * @param tokenId tokenId of NFT being transferred
     */
    function uniTransfer(
        uint32 _destChainSlug,
        address _destReceiver,
        uint256 tokenId
    ) external payable {
        _burn(tokenId);

        bytes memory payload = abi.encode(msg.sender, _destReceiver, tokenId);

        _outbound(
            _destChainSlug,
            destGasLimits[_destChainSlug],
            bytes32(0),
            bytes32(0),
            payload
        );

        emit UniTransfer(_destChainSlug, _destReceiver, tokenId);
    }

    /**
     * @notice Decodes payload sent from `uniTransfer`, mints tokenId that was burn on source chain and transfer to receiver
     * @param _siblingChainSlug chainSlug of chain the NFT was sent from
     * @param _sender Address of address that sent the NFT from source chain
     * @param _receiver Address of receiver on the destination chain
     * @param _tokenId tokenID of NFT that was transferred
     */
    function _uniReceive(
        uint32 _siblingChainSlug,
        address _sender,
        address _receiver,
        uint256 _tokenId
    ) internal {
        _safeMint(_receiver, _tokenId);

        emit UniReceive(_sender, _receiver, _tokenId, _siblingChainSlug);
    }

    /**
     * @notice Calls _uniReceive function to relay message & transfer NFT on the destination chain
     * @dev
     * @param siblingChainSlug_ chainSlug of the sibling chain the message was sent from
     * @param payload_ Payload sent in the message
     */
    function _receiveInbound(
        uint32 siblingChainSlug_,
        bytes memory payload_
    ) internal virtual override onlySocket {
        (address sender, address receiver, uint256 tokenId) = abi.decode(
            payload_,
            (address, address, uint256)
        );
        _uniReceive(siblingChainSlug_, sender, receiver, tokenId);
    }
}
