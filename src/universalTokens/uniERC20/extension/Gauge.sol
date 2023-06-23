pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract Gauge is AccessControl {
    mapping(uint256 => Limits) public bridgeLimits;

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
        uint256 _siblingSlug,
        Limits memory _limits
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        bridgeLimits[_siblingSlug] = _limits;
    }

    /**
     * @notice Returns bridging limits set for given sibling chain
     * @param _siblingSlug chainSlug for which limits are set
     */
    function getBridgeLimits(
        uint256 _siblingSlug
    ) public view returns (Limits memory) {
        return bridgeLimits[_siblingSlug];
    }

    function checkMintValidity(
        uint256 _siblingChainSlug,
        uint256 _amount
    ) public view returns (bool) {
        uint256 _limit = getMintCurrentLimit(_siblingChainSlug);

        if (_amount >= _limit) return true;
        return false;
    }

    function getMintCurrentLimit(
        uint256 _siblingChainSlug
    ) public view returns (uint256) {
        return
            _getCurrentLimit(
                bridgeLimits[_siblingChainSlug].mintingLimits.currentLimit,
                bridgeLimits[_siblingChainSlug].mintingLimits.maxLimit,
                bridgeLimits[_siblingChainSlug].mintingLimits.timestamp,
                bridgeLimits[_siblingChainSlug].mintingLimits.ratePerSecond
            );
    }

    function checkBurnValidity(
        uint256 _siblingChainSlug,
        uint256 _amount
    ) public view returns (bool) {
        uint256 _limit = getBurnCurrentLimit(_siblingChainSlug);

        if (_amount >= _limit) return true;
        return false;
    }

    function getBurnCurrentLimit(
        uint256 _siblingChainSlug
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
        uint256 _siblingChainSlug,
        uint256 _amount
    ) internal {
        _updateMintLimits(_siblingChainSlug, _amount);
    }

    function _updateMintLimits(
        uint256 _siblingChainSlug,
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
        uint256 _siblingChainSlug,
        uint256 _amount
    ) internal {
        _updateBurnLimits(_siblingChainSlug, _amount);
    }

    function _updateBurnLimits(
        uint256 _siblingChainSlug,
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
