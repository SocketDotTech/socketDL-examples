// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/impl/Counter.sol";
import "../src/mocks/MockSocket.sol";

contract CounterTest is Test {
    Counter public srcCounter__;
    Counter public dstCounter__;
    MockSocket public mockSocket__;

    uint256 chainSlug_ = 1;
    uint256 siblingChainSlug_ = 2;
    address public constant fastSwitchboard = address(1);
    address public constant optimisticSwitchboard = address(2);

    function setUp() public {
        mockSocket__ = new MockSocket(chainSlug_, siblingChainSlug_);

        srcCounter__ = new Counter(address(mockSocket__));
        dstCounter__ = new Counter(address(mockSocket__));

        dstCounter__.connect(
            chainSlug_,
            address(srcCounter__),
            fastSwitchboard,
            fastSwitchboard
        );
        srcCounter__.connect(
            siblingChainSlug_,
            address(dstCounter__),
            fastSwitchboard,
            fastSwitchboard
        );
    }

    function testSetNumber(uint256 x) public {
        srcCounter__.setRemoteNumber(x, siblingChainSlug_);
        assertEq(dstCounter__.number(), x);
    }
}
