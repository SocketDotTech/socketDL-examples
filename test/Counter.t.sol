// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Counter.sol";
import "../src/mocks/MockSocket.sol";

contract CounterTest is Test {
    Counter public srcCounter__;
    Counter public dstCounter__;
    MockSocket public mockSocket__;

    uint256 chainSlug_ = 1;
    uint256 remoteChainSlug_ = 2;
    string integrationType = "FAST";

    function setUp() public {
        mockSocket__ = new MockSocket(chainSlug_, remoteChainSlug_);
        
        srcCounter__ = new Counter(address(mockSocket__));
        dstCounter__ = new Counter(address(mockSocket__));

        dstCounter__.connect(chainSlug_, address(srcCounter__), integrationType);
        srcCounter__.connect(remoteChainSlug_, address(dstCounter__), integrationType);
    }

    function testSetNumber(uint256 x) public {
        srcCounter__.setNumber(x, remoteChainSlug_);
        assertEq(dstCounter__.number(), x);
    }
}