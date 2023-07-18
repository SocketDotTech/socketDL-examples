pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract ExchangeRate is Ownable2Step {
    // chainId input needed? what else?
    function getMintAmount(
        uint256 lockAmount,
        uint256 /* totalLockedAmount */
    ) external returns (uint256 mintAmount) {
        return lockAmount;
    }

    function getUnlockAmount(
        uint256 burnAmount,
        uint256 /* totalLockedAmount */
    ) external returns (uint256 unlockAmount) {
        return burnAmount;
    }
}
