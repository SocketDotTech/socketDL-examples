// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "../src/impl/Counter.sol";

contract CounterScript is Script {
    address public socket;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // create and select fork for ethereum
        address counter = address(new Counter(socket));
        console.log(counter);

        vm.stopBroadcast();
    }
}
