pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {PlugBase} from "../../../base/PlugBase.sol";
import {IMultiGaugeUniERC20} from "../interfaces/IMultiGaugeUniERC20.sol";

contract ConnectionPlug is PlugBase, AccessControl {
    IMultiGaugeUniERC20 public uniERC20;
    bytes32 public constant UNI_ERC20_ROLE = keccak256("UNI_ERC20_ROLE");
    bytes32 public constant SOCKET_ROLE = keccak256("SOCKET_ROLE");

    constructor(address _socket, address _uniERC20) PlugBase(_socket) {
        uniERC20 = IMultiGaugeUniERC20(_uniERC20);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UNI_ERC20_ROLE, _uniERC20);
        _grantRole(SOCKET_ROLE, _socket);
    }

    function outboundTransfer(
        uint32 _destChainSlug,
        uint256 _minGasLimit,
        bytes memory payload_
    ) external payable onlyRole(UNI_ERC20_ROLE) {
        _outbound(_destChainSlug, _minGasLimit, msg.value, payload_);
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
    ) internal virtual override onlyRole(SOCKET_ROLE) {
        uniERC20.uniReceive(siblingChainSlug_, payload_);
    }
}
