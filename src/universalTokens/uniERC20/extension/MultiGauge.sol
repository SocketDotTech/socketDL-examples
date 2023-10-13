pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract MultiGauge is AccessControl {
    mapping(address => Limits) public bridgeLimits;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // bytes32 public constant BURNER_ROLE = keccak256("UNI_ERC20_ROLE");

    uint256 private constant _DURATION = 1 days;

    struct Limits {
        LimitParameters mintingLimits;
        LimitParameters burningLimits;
    }

    struct LimitParameters {
        uint256 timestamp;
        uint256 ratePerSecond;
        uint256 maxLimit;
        uint256 currentLimit;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Sets Bridging limits for specified sibling chain. This is an admin only function
     * @dev Both minting limits from the sibling chain and burning limits to sibling chain need to be specified
     * @param _bridgeType address of Plug that connects to a specific Socket Switchboard
     * @param _limits Minting and burning limits for specified sibling chain
     */
    function setLimits(
        address _bridgeType,
        Limits memory _limits
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, _bridgeType);
        bridgeLimits[_bridgeType] = _limits;
    }

    /**
     * @notice Returns bridging limits set for given sibling chain
     * @param _bridgeType address of Plug that connects to a specific Socket Switchboard
     */
    function getBridgeLimits(
        address _bridgeType
    ) public view returns (Limits memory) {
        return bridgeLimits[_bridgeType];
    }

    /**
     * @notice Checks validity of token minting amount
     * @param _bridgeType address of Plug that connects to a specific Socket Switchboard
     * @param _amount Amount of tokens to be minted
     */
    function checkMintValidity(
        address _bridgeType,
        uint256 _amount
    ) public view returns (bool) {
        uint256 _limit = getMintCurrentLimit(_bridgeType);

        if (_amount <= _limit) return true;
        return false;
    }

    function getMintCurrentLimit(
        address _bridgeType
    ) public view returns (uint256) {
        return
            _getCurrentLimit(
                bridgeLimits[_bridgeType].mintingLimits.currentLimit,
                bridgeLimits[_bridgeType].mintingLimits.maxLimit,
                bridgeLimits[_bridgeType].mintingLimits.timestamp,
                bridgeLimits[_bridgeType].mintingLimits.ratePerSecond
            );
    }

    /**
     * @notice Checks validity of token burning amount
     * @param _bridgeType address of Plug that connects to a specific Socket Switchboard
     * @param _amount Amount of tokens being burnt
     */
    function checkBurnValidity(
        address _bridgeType,
        uint256 _amount
    ) public view returns (bool) {
        uint256 _limit = getBurnCurrentLimit(_bridgeType);

        if (_amount <= _limit) return true;
        return false;
    }

    function getBurnCurrentLimit(
        address _bridgeType
    ) public view returns (uint256) {
        return
            _getCurrentLimit(
                bridgeLimits[_bridgeType].burningLimits.currentLimit,
                bridgeLimits[_bridgeType].burningLimits.maxLimit,
                bridgeLimits[_bridgeType].burningLimits.timestamp,
                bridgeLimits[_bridgeType].burningLimits.ratePerSecond
            );
    }

    /************************************************************************
        Internal Functions
    ************************************************************************/

    /**
     * @notice Returns the current limit based on the duration passed since the limit was last updated
     * @param _currentLimit currentLimit that was last updated at _timestamp
     * @param _maxLimit Max limit that can be minted or burnt on current chain
     * @param _timestamp Timestamp when the limit was updated
     * @param _ratePerSecond Number of tokens that can be minted every second
     */
    function _getCurrentLimit(
        uint256 _currentLimit,
        uint256 _maxLimit,
        uint256 _timestamp,
        uint256 _ratePerSecond
    ) internal view returns (uint256 _limit) {
        _limit = _currentLimit;
        if (_limit == _maxLimit) {
            return _limit;
        } else if (_timestamp + _DURATION <= block.timestamp) {
            _limit = _maxLimit;
        } else if (_timestamp + _DURATION > block.timestamp) {
            uint256 _timeInterval = block.timestamp - _timestamp;
            uint256 _calculatedLimit = _limit +
                (_timeInterval * _ratePerSecond);
            _limit = _calculatedLimit > _maxLimit
                ? _maxLimit
                : _calculatedLimit;
        }
    }

    function _useTokensMinted(address _bridgeType, uint256 _amount) internal {
        _updateMintLimits(_bridgeType, _amount);
    }

    /**
     * @notice Updates the currentLimit and timestamp when tokens are minted
     * @param _bridgeType address of Plug that connects to a specific Socket Switchboard
     * @param _amount Amount of tokens minted
     */
    function _updateMintLimits(address _bridgeType, uint256 _amount) internal {
        uint256 _currentLimit = getMintCurrentLimit(_bridgeType);
        bridgeLimits[_bridgeType].mintingLimits.timestamp = block.timestamp;
        bridgeLimits[_bridgeType].mintingLimits.currentLimit =
            _currentLimit -
            _amount;
    }

    function _useTokensBurnt(address _bridgeType, uint256 _amount) internal {
        _updateBurnLimits(_bridgeType, _amount);
    }

    /**
     * @notice Updates the currentLimit and timestamp when tokens are burned
     * @param _bridgeType address of Plug that connects to a specific Socket Switchboard
     * @param _amount Amount of tokens burnt
     */
    function _updateBurnLimits(address _bridgeType, uint256 _amount) internal {
        uint256 _currentLimit = getBurnCurrentLimit(_bridgeType);
        bridgeLimits[_bridgeType].burningLimits.timestamp = block.timestamp;
        bridgeLimits[_bridgeType].burningLimits.currentLimit =
            _currentLimit -
            _amount;
    }
}
