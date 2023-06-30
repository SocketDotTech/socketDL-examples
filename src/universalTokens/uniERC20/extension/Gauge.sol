pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract Gauge is AccessControl {
    mapping(uint32 => Limits) public bridgeLimits;

    // bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
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
        // _grantRole(MINTER_ROLE, _minter);
        // _grantRole(BURNER_ROLE, _burner);
    }

    /**
     * @notice Sets Bridging limits for specified sibling chain. This is an admin only function
     * @dev Both minting limits from the sibling chain and burning limits to sibling chain need to be specified
     * @param _siblingSlug chainSlug for which limits are set
     * @param _limits Minting and burning limits for specified sibling chain
     */
    function setLimits(
        uint32 _siblingSlug,
        Limits memory _limits
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        bridgeLimits[_siblingSlug] = _limits;
    }

    /**
     * @notice Returns bridging limits set for given sibling chain
     * @param _siblingSlug chainSlug for which limits are set
     */
    function getBridgeLimits(
        uint32 _siblingSlug
    ) public view returns (Limits memory) {
        return bridgeLimits[_siblingSlug];
    }

    /**
     * @notice Checks validity of token minting amount
     * @param _siblingChainSlug chainSlug of sibling chain that triggered the mint
     * @param _amount Amount of tokens to be minted
     */
    function checkMintValidity(
        uint32 _siblingChainSlug,
        uint256 _amount
    ) public view returns (bool) {
        uint32 _limit = getMintCurrentLimit(_siblingChainSlug);

        if (_amount <= _limit) return true;
        return false;
    }

    function getMintCurrentLimit(
        uint32 _siblingChainSlug
    ) public view returns (uint256) {
        return
            _getCurrentLimit(
                bridgeLimits[_siblingChainSlug].mintingLimits.currentLimit,
                bridgeLimits[_siblingChainSlug].mintingLimits.maxLimit,
                bridgeLimits[_siblingChainSlug].mintingLimits.timestamp,
                bridgeLimits[_siblingChainSlug].mintingLimits.ratePerSecond
            );
    }

    /**
     * @notice Checks validity of token burning amount
     * @param _siblingChainSlug chainSlug of sibling chain where tokens will be minted
     * @param _amount Amount of tokens being burnt
     */
    function checkBurnValidity(
        uint32 _siblingChainSlug,
        uint256 _amount
    ) public view returns (bool) {
        uint256 _limit = getBurnCurrentLimit(_siblingChainSlug);

        if (_amount <= _limit) return true;
        return false;
    }

    function getBurnCurrentLimit(
        uint32 _siblingChainSlug
    ) public view returns (uint256) {
        return
            _getCurrentLimit(
                bridgeLimits[_siblingChainSlug].burningLimits.currentLimit,
                bridgeLimits[_siblingChainSlug].burningLimits.maxLimit,
                bridgeLimits[_siblingChainSlug].burningLimits.timestamp,
                bridgeLimits[_siblingChainSlug].burningLimits.ratePerSecond
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

    function _useTokensMinted(
        uint32 _siblingChainSlug,
        uint256 _amount
    ) internal {
        _updateMintLimits(_siblingChainSlug, _amount);
    }

    /**
     * @notice Updates the currentLimit and timestamp when tokens are minted
     * @param _siblingChainSlug chainSlug of the siblingChain
     * @param _amount Amount of tokens minted
     */
    function _updateMintLimits(
        uint32 _siblingChainSlug,
        uint256 _amount
    ) internal {
        uint256 _currentLimit = getMintCurrentLimit(_siblingChainSlug);
        bridgeLimits[_siblingChainSlug].mintingLimits.timestamp = block
            .timestamp;
        bridgeLimits[_siblingChainSlug].mintingLimits.currentLimit =
            _currentLimit -
            _amount;
    }

    function _useTokensBurnt(
        uint32 _siblingChainSlug,
        uint256 _amount
    ) internal {
        _updateBurnLimits(_siblingChainSlug, _amount);
    }

    /**
     * @notice Updates the currentLimit and timestamp when tokens are burned
     * @param _siblingChainSlug chainSlug of the siblingChain
     * @param _amount Amount of tokens burnt
     */
    function _updateBurnLimits(
        uint32 _siblingChainSlug,
        uint256 _amount
    ) internal {
        uint256 _currentLimit = getBurnCurrentLimit(_siblingChainSlug);
        bridgeLimits[_siblingChainSlug].burningLimits.timestamp = block
            .timestamp;
        bridgeLimits[_siblingChainSlug].burningLimits.currentLimit =
            _currentLimit -
            _amount;
    }
}
