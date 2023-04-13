// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/impl/ProCounter.sol";
import "../src/mocks/MockSocket.sol";

contract ProCounterTest is Test {
    ProCounter public srcProCounter__;
    ProCounter public dstProCounter__;
    MockSocket public mockSocket__;

    uint256 chainSlug_ = 1;
    uint256 siblingChainSlug_ = 2;
    address public constant fastSwitchboard = address(1);
    address public constant optimisticSwitchboard = address(2);
    address immutable counterOwner = address(uint160(3));

    function setUp() public {
        mockSocket__ = new MockSocket(chainSlug_, siblingChainSlug_);

        vm.startPrank(counterOwner);
        srcProCounter__ = new ProCounter(address(mockSocket__));
        dstProCounter__ = new ProCounter(address(mockSocket__));

        dstProCounter__.connect(
            chainSlug_,
            address(srcProCounter__),
            fastSwitchboard,
            fastSwitchboard
        );
        srcProCounter__.connect(
            siblingChainSlug_,
            address(dstProCounter__),
            fastSwitchboard,
            fastSwitchboard
        );

        vm.stopPrank();
    }

    function testSetNumber() public {
        uint256 x = 55;

        hoax(counterOwner);
        srcProCounter__.setRemoteNumber(x, siblingChainSlug_);

        assertEq(dstProCounter__.number(), x);
    }

    function testSetSequentialNumbers() public {
        uint256[] memory slugs = new uint256[](4);
        uint256[] memory fees = new uint256[](4);

        slugs[0] = siblingChainSlug_;
        slugs[1] = siblingChainSlug_;
        slugs[2] = siblingChainSlug_;
        slugs[3] = siblingChainSlug_;

        fees[0] = 0;
        fees[1] = 0;
        fees[2] = 0;
        fees[3] = 0;

        hoax(counterOwner);
        srcProCounter__.setSequentialNumbers(1, 5, slugs, fees);

        assertEq(dstProCounter__.number(), 4);
    }

    function testBroadcastNumber() public {
        uint256 newNumber = 10;
        uint256[] memory slugs = new uint256[](1);
        uint256[] memory fees = new uint256[](1);

        slugs[0] = siblingChainSlug_;
        fees[0] = 0;

        hoax(counterOwner);
        srcProCounter__.broadcastNumber(newNumber, slugs, fees);
        assertEq(dstProCounter__.number(), newNumber);
    }

    function testUnicastNumbers() public {
        uint256 fees = 0;
        hoax(counterOwner);
        srcProCounter__.unicastNumber(1, 5, siblingChainSlug_, fees);

        assertEq(dstProCounter__.number(), 4);
    }
}
