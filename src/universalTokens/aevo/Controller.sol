pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import "../../interfaces/ISocket.sol";
import "./ExchangeRate.sol";

interface IMintableERC20 {
    function mint(address receiver_, uint256 amount_) external;

    function burn(address burner_, uint256 amount_) external;
}

abstract contract PlugBase is Ownable2Step {
    ISocket public socket__;

    constructor(address socket_) {
        socket__ = ISocket(socket_);
    }

    function connect(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external onlyOwner {
        socket__.connect(
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_
        );
    }

    function inbound(
        uint32 siblingChainSlug_,
        bytes calldata payload_
    ) external payable {
        require(msg.sender == address(socket__), "no auth");
        _receiveInbound(siblingChainSlug_, payload_);
    }

    function _outbound(
        uint32 chainSlug_,
        uint256 gasLimit_,
        uint256 fees_,
        bytes memory payload_
    ) internal {
        socket__.outbound{value: fees_}(
            chainSlug_,
            gasLimit_,
            bytes32(0),
            bytes32(0),
            payload_
        );
    }

    function _receiveInbound(
        uint32 siblingChainSlug_,
        bytes memory payload_
    ) internal virtual;
}

// @todo: separate our connecter plugs
// @todo: multitoken support
// @todo: events, errors
contract Controller is PlugBase {
    IMintableERC20 public token__;
    ExchangeRate public exchangeRate__;
    mapping(uint32 => uint256) public totalLockedAmounts;

    mapping(address => uint256) public pendingMints;

    constructor(
        address token_,
        address exchangeRate_,
        address socket_
    ) PlugBase(socket_) {
        token__ = IMintableERC20(token_);
        exchangeRate__ = ExchangeRate(exchangeRate_);
    }

    function updateExchangeRate(address exchangeRate_) external onlyOwner {
        exchangeRate__ = ExchangeRate(exchangeRate_);
    }

    // todo: impl local throttling
    function withdrawFromAevo(
        uint32 toChainSlug_,
        address receiver_,
        uint256 burnAmount_,
        uint256 gasLimit_
    ) external payable {
        token__.burn(msg.sender, burnAmount_);
        uint256 unlockAmount = exchangeRate__.getUnlockAmount(
            burnAmount_,
            totalLockedAmounts[toChainSlug_]
        );
        totalLockedAmounts[toChainSlug_] -= unlockAmount; // underflow revert expected
        _outbound(
            toChainSlug_,
            gasLimit_,
            msg.value,
            abi.encode(receiver_, unlockAmount)
        );
    }

    // todo: impl local throttling, caching, pending
    function mintPendingFor(address receiver_) external {
        uint256 pendingMint = pendingMints[receiver_];
        pendingMints[receiver_] = 0;
        token__.mint(receiver_, pendingMint);
    }

    // todo: impl local throttling, caching, pending
    function _receiveInbound(
        uint32 siblingChainSlug_,
        bytes memory payload_
    ) internal override {
        (address receiver, uint256 lockAmount) = abi.decode(
            payload_,
            (uint256, address)
        );
        totalLockedAmounts[siblingChainSlug_] += lockAmount;
        uint256 mintAmount = exchangeRate__.getMintAmount(
            lockAmount,
            totalLockedAmounts[siblingChainSlug_]
        );
        token__.mint(receiver, mintAmount);
    }
}
