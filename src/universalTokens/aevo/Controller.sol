pragma solidity 0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import {IExchangeRate} from "./ExchangeRate.sol";
import {Gauge} from "./Gauge.sol";
import {PlugBase} from "./PlugBase.sol";

abstract contract IMintableERC20 is ERC20 {
    function mint(address receiver_, uint256 amount_) external virtual;

    function burn(address burner_, uint256 amount_) external virtual;
}

contract Controller is PlugBase, Gauge {
    using SafeTransferLib for IMintableERC20;
    IMintableERC20 public token__;
    IExchangeRate public exchangeRate__;
    mapping(uint32 => uint256) public totalLockedAmounts;
    mapping(uint32 => LimitParams) _mintLimitParams;
    mapping(uint32 => LimitParams) _burnLimitParams;

    // siblingChain => receiver => amount
    mapping(uint32 => mapping(address => uint256)) public pendingMints;

    error LengthMismatch();

    constructor(
        address token_,
        address exchangeRate_,
        address socket_
    ) PlugBase(socket_) {
        token__ = IMintableERC20(token_);
        exchangeRate__ = IExchangeRate(exchangeRate_);
    }

    function updateExchangeRate(address exchangeRate_) external onlyOwner {
        exchangeRate__ = IExchangeRate(exchangeRate_);
    }

    // @todo: update only required
    function updateMintLimitParams(
        uint32[] calldata chainSlugs_,
        LimitParams[] calldata limitParams_
    ) external onlyOwner {
        if (chainSlugs_.length != limitParams_.length) revert LengthMismatch();
        for (uint256 i; i < chainSlugs_.length; i++) {
            _mintLimitParams[chainSlugs_[i]] = limitParams_[i];
        }
    }

    // @todo: update only required
    function updateBurnLimitParams(
        uint32[] calldata chainSlugs_,
        LimitParams[] calldata limitParams_
    ) external onlyOwner {
        if (chainSlugs_.length != limitParams_.length) revert LengthMismatch();
        for (uint256 i; i < chainSlugs_.length; i++) {
            _burnLimitParams[chainSlugs_[i]] = limitParams_[i];
        }
    }

    // do we throttle burn amount or unlock amount? burn for now
    function withdrawFromAevo(
        uint32 toChainSlug_,
        address receiver_,
        uint256 burnAmount_,
        uint256 gasLimit_
    ) external payable {
        _consumeFullLimit(burnAmount_, _burnLimitParams[toChainSlug_]); // reverts on limit hit
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

    function mintPendingFor(
        address receiver_,
        uint32 siblingChainSlug_
    ) external {
        uint256 pendingMint = pendingMints[siblingChainSlug_][receiver_];
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            pendingMint,
            _mintLimitParams[siblingChainSlug_]
        );
        pendingMints[siblingChainSlug_][receiver_] = pendingAmount;
        token__.safeTransfer(receiver_, consumedAmount);
    }

    function _receiveInbound(
        uint32 siblingChainSlug_,
        bytes memory payload_
    ) internal override {
        (address receiver, uint256 lockAmount) = abi.decode(
            payload_,
            (address, uint256)
        );
        totalLockedAmounts[siblingChainSlug_] += lockAmount;
        uint256 mintAmount = exchangeRate__.getMintAmount(
            lockAmount,
            totalLockedAmounts[siblingChainSlug_]
        );
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            mintAmount,
            _mintLimitParams[siblingChainSlug_]
        );
        if (pendingAmount > 0) {
            // add instead of overwrite to handle case where already pending amount is left
            pendingMints[siblingChainSlug_][receiver] += pendingAmount;
        }
        token__.mint(receiver, consumedAmount);
    }
}
