// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "../src/impl/Counter.sol";

contract CounterScript is Script {
    function deploy() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address socket = vm.envAddress("SOCKET");

        vm.startBroadcast(deployerPrivateKey);

        Counter test = new Counter(socket);

        vm.stopBroadcast();
    }

    function connectOnSocket() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address socket = vm.envAddress("SOCKET");

        Counter counter = Counter(socket);
        counter.connect(
            vm.envUint("SIBLING_CHAIN_SLUG"),
            vm.envAddress("SIBLING_ADDRESS"),
            vm.envAddress("INBOUND_SWITCHBOARD"),
            vm.envAddress("OUTBOUND_SWITCHBOARD")
        );

        vm.stopBroadcast();
    }

    function setRemoteNumber() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address socket = vm.envAddress("SOCKET");
        uint256 newNumber = vm.envUint("NEW_NUMBER");
        uint256 toChainSlug = vm.envUint("TO_CHAIN_SLUG");

        Counter counter = Counter(socket);

        counter.setRemoteNumber(newNumber, toChainSlug);

        vm.stopBroadcast();
    }
}
