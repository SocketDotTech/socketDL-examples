pragma solidity 0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {IExchangeRate} from "./ExchangeRate.sol";
import {Gauge} from "./Gauge.sol";
import {IConnector, IHub} from "./ConnectorPlug.sol";
import {IMintableERC20} from "./MintableToken.sol";

contract Controller is IHub, Gauge, Ownable2Step {
    using SafeTransferLib for IMintableERC20;
    IMintableERC20 public token__;
    IExchangeRate public exchangeRate__;

    struct UpdateLimitParams {
        bool isMint;
        address connector;
        uint256 maxLimit;
        uint256 ratePerSecond;
    }

    // connector => totalLockedAmount
    mapping(address => uint256) public totalLockedAmounts;

    // connector => mintLimitParams
    mapping(address => LimitParams) _mintLimitParams;

    // connector => burnLimitParams
    mapping(address => LimitParams) _burnLimitParams;

    // connector => receiver => amount
    mapping(address => mapping(address => uint256)) public pendingMints;

    error ConnectorUnavailable();
    error LengthMismatch();

    constructor(address token_, address exchangeRate_) {
        token__ = IMintableERC20(token_);
        exchangeRate__ = IExchangeRate(exchangeRate_);
    }

    function updateExchangeRate(address exchangeRate_) external onlyOwner {
        exchangeRate__ = IExchangeRate(exchangeRate_);
    }

    function updateLimitParams(
        UpdateLimitParams[] calldata updates_
    ) external onlyOwner {
        for (uint256 i; i < updates_.length; i++) {
            if (updates_[i].isMint) {
                _mintLimitParams[updates_[i].connector].maxLimit = updates_[i].maxLimit;
                _mintLimitParams[updates_[i].connector].ratePerSecond = updates_[i].ratePerSecond;
            } else {
                _burnLimitParams[updates_[i].connector].maxLimit = updates_[i].maxLimit;
                _burnLimitParams[updates_[i].connector].ratePerSecond = updates_[i].ratePerSecond;
            }
        }
    }

    // do we throttle burn amount or unlock amount? burn for now
    function withdrawFromAppChain(
        address receiver_,
        uint256 burnAmount_,
        uint256 gasLimit_,
        address connector_
    ) external payable {
        if (_burnLimitParams[connector_].maxLimit == 0)
            revert ConnectorUnavailable();

        _consumeFullLimit(burnAmount_, _burnLimitParams[connector_]); // reverts on limit hit
        token__.burn(msg.sender, burnAmount_);

        uint256 unlockAmount = exchangeRate__.getUnlockAmount(
            burnAmount_,
            totalLockedAmounts[connector_]
        );
        totalLockedAmounts[connector_] -= unlockAmount; // underflow revert expected

        IConnector(connector_).outbound{value: msg.value}(
            gasLimit_,
            abi.encode(receiver_, unlockAmount)
        );
    }

    function mintPendingFor(address receiver_, address connector_) external {
        if (_mintLimitParams[connector_].maxLimit == 0)
            revert ConnectorUnavailable();

        uint256 pendingMint = pendingMints[connector_][receiver_];
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            pendingMint,
            _mintLimitParams[connector_]
        );

        pendingMints[connector_][receiver_] = pendingAmount;
        token__.safeTransfer(receiver_, consumedAmount);
    }

    // receive inbound assuming connector called
    // if connector is not configured (malicious), its mint amount will forever stay in pending
    function receiveInbound(bytes memory payload_) external override {
        (address receiver, uint256 lockAmount) = abi.decode(
            payload_,
            (address, uint256)
        );

        totalLockedAmounts[msg.sender] += lockAmount;
        uint256 mintAmount = exchangeRate__.getMintAmount(
            lockAmount,
            totalLockedAmounts[msg.sender]
        );
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            mintAmount,
            _mintLimitParams[msg.sender]
        );

        if (pendingAmount > 0) {
            // add instead of overwrite to handle case where already pending amount is left
            pendingMints[msg.sender][receiver] += pendingAmount;
        }
        token__.mint(receiver, consumedAmount);
    }
}
