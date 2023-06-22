pragma solidity 0.8.13;

// import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Gauge {
    mapping(uint256 => Limits) public bridgeLimits;

    uint256 private constant _DURATION = 1 days;

    struct Limits {
        LimitParameters mintingLimits;
        LimitParameters burningLimits;
    }

    struct LimitParameters {
        uint256 timestamp;
        uint256 maxLimit;
        uint256 currentLimit;
    }

    function setLimits(uint256 _siblingSlug, Limits memory _limits) public {
        bridgeLimits[_siblingSlug] = _limits;
    }

    function getLimits(uint256 _siblingSlug) public returns (Limits memory) {
        return bridgeLimits[_siblingSlug];
    }

    function checkMintValidity(
        uint256 _amount,
        uint256 _siblingSlug
    ) public view returns (bool) {
        uint256 maxLimit = bridgeLimits[_siblingSlug].mintingLimits.maxLimit;
        uint256 currentLimit = bridgeLimits[_siblingSlug]
            .mintingLimits
            .currentLimit;
        if (_amount <= maxLimit - currentLimit) {} else false;
    }

    function checkBurnValidity(
        uint256 _amount,
        uint256 _siblingSlug
    ) public view returns (bool) {
        uint256 maxLimit = bridgeLimits[_siblingSlug].burningLimits.maxLimit;
        uint256 currentLimit = bridgeLimits[_siblingSlug]
            .burningLimits
            .currentLimit;
        if (_amount <= maxLimit - currentLimit) {
            return true;
        } else false;
    }

    /************************************************************************
        Internal Functions
    ************************************************************************/

    function _updateMintLimits(uint256 _amount, uint256 _siblingSlug) internal {
        uint256 currentLimit__ = bridgeLimits[_siblingSlug]
            .mintingLimits
            .currentLimit;
        uint256 maxLimit__ = bridgeLimits[_siblingSlug].mintingLimits.maxLimit;

        if ((currentLimit__ + _amount) < maxLimit__) {
            currentLimit__ += _amount;
        }
    }

    function _updateBurnLimits(uint256 _amount, uint256 _siblingSlug) internal {
        uint256 currentLimit__ = bridgeLimits[_siblingSlug]
            .burningLimits
            .currentLimit;
        uint256 maxLimit__ = bridgeLimits[_siblingSlug].burningLimits.maxLimit;

        if ((currentLimit__ + _amount) < maxLimit__) {
            currentLimit__ += _amount;
        }
    }
}
