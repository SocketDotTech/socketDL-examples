// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/universalTokens/uniERC20/GaugedUniERC20.sol";
import "../src/mocks/MockSocket.sol";
import "forge-std/console.sol";

contract GaugedUniERC20Test is Test {
    uniERC20 public srcToken__;
    uniERC20 public dstToken__;
    MockSocket public mockSocket__;

    uint256 chainSlug_ = 1;
    uint256 siblingChainSlug_ = 2;

    address public constant fastSwitchboard = address(1);
    address public constant optimisticSwitchboard = address(2);
    address public constant testUser = address(3);

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

    function setUp() public {
        mockSocket__ = new MockSocket(chainSlug_, siblingChainSlug_);
        srcToken__ = new GaugedUniERC20(
            10000000000,
            address(mockSocket__),
            "TEST 1",
            "TEST"
        );
        dstToken__ = new GaugedUniERC20(
            10000000000,
            address(mockSocket__),
            "TEST 2",
            "TEST"
        );
        dstToken__.connect(
            chainSlug_,
            address(srcToken__),
            fastSwitchboard,
            fastSwitchboard
        );
        srcToken__.connect(
            siblingChainSlug_,
            address(dstToken__),
            fastSwitchboard,
            fastSwitchboard
        );
    }

    function testSetDestChainGasLimit() public {
        uint x = 100000000;
        srcToken__.setDestChainGasLimit(siblingChainSlug_, x);
        assertEq(srcToken__.destGasLimits(siblingChainSlug_), x);
    }

    function testSetLimits() public {
        Limits _limits = new Limits({
            mintingParams : ,
            burningParams : {
                timestamp: block.timestamp,
                
            }
        })
        srcToken__.setLimits(siblingChainSlug_, )
    }

    function testUniTransfer() public {
        uint x = 100000000;
        srcToken__.setDestChainGasLimit(siblingChainSlug_, x);

        uint256 _amount = 10000;
        srcToken__.uniTransfer(siblingChainSlug_, testUser, _amount);

        uint256 srcBalance = srcToken__.balanceOf(testUser);
        uint256 destBalance = dstToken__.balanceOf(testUser);

        assertEq(srcBalance, 0);
        assertEq(destBalance, _amount);
    }
}
