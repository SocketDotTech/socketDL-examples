pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import "../../interfaces/ISocket.sol";
import "./ExchangeRate.sol";
import "./Gauge.sol";

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
contract Controller is PlugBase, Gauge {
    IMintableERC20 public token__;
    ExchangeRate public exchangeRate__;
    mapping(uint32 => uint256) public totalLockedAmounts;
    mapping(uint32 => LimitParams) _mintLimitParams;
    mapping(uint32 => LimitParams) _burnLimitParams;

    mapping(address => uint256) public pendingMints;

    error LengthMismatch();

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

    // @todo: update only required
    function updateMintLimitParams(
        uint32[] chainSlugs,
        LimitParams[] calldata limitParams_
    ) external onlyOwner {
        if (chainSlugs.length != limitParams_.length) revert LengthMismatch();
        for (uint256 i; i < chainSlugs.length; i++) {
            _mintLimitParams[chainSlugs[i]] = limitParams_[i];
        }
    }

    // @todo: update only required
    function updateBurnLimitParams(
        LimitParams calldata limitParams_
    ) external onlyOwner {
        if (chainSlugs.length != limitParams_.length) revert LengthMismatch();
        for (uint256 i; i < chainSlugs.length; i++) {
            _burnLimitParams[chainSlugs[i]] = limitParams_[i];
        }
    }

    // do we throttle burn amount or unlock amount? burn for now
    function withdrawFromAevo(
        uint32 toChainSlug_,
        address receiver_,
        uint256 burnAmount_,
        uint256 gasLimit_
    ) external payable {
        _consumeFullLimit(burnAmount_, _burnLimitParams); // reverts on limit hit
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

    function mintPendingFor(address receiver_) external {
        uint256 pendingMint = pendingMints[receiver_];
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            pendingMint,
            _mintLimitParams
        );
        pendingMints[receiver] = pendingAmount;
        token__.safeTransfer(receiver, consumedAmount);
    }

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
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            mintAmount,
            _mintLimitParams
        );
        if (pendingAmount > 0) {
            // add instead of overwrite to handle case where already pending amount is left
            pendingMints[receiver] += pendingAmount;
        }
        token__.mint(receiver, consumedAmount);
    }
}
