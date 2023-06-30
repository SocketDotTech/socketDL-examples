// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/universalTokens/uniERC20/GaugedUniERC20.sol";
import "../src/mocks/MockSocket.sol";
import "forge-std/console.sol";

contract GaugedUniERC20Test is Test, Gauge {
    GaugedUniERC20 public srcToken__;
    GaugedUniERC20 public dstToken__;
    MockSocket public mockSocket__;

    uint32 chainSlug_ = 1;
    uint32 siblingChainSlug_ = 2;

    address public constant fastSwitchboard = address(1);
    address public constant optimisticSwitchboard = address(2);
    address public constant testUser = address(3);

    function setUp() public {
        mockSocket__ = new MockSocket(chainSlug_, siblingChainSlug_);
        srcToken__ = new GaugedUniERC20(
            10 ether,
            address(mockSocket__),
            "TEST 1",
            "TEST"
        );
        dstToken__ = new GaugedUniERC20(
            10 ether,
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

        testSetLimits();
    }

    function testSetDestChainGasLimit() public {
        uint x = 100000000;
        srcToken__.setDestChainGasLimit(siblingChainSlug_, x);
        assertEq(srcToken__.destGasLimits(siblingChainSlug_), x);
    }

    function testSetLimits() public {
        LimitParameters memory mintLimits__ = LimitParameters(
            block.timestamp,
            1 ether,
            1000000 ether,
            1000000 ether
        );
        LimitParameters memory burnLimits__ = LimitParameters(
            block.timestamp,
            1 ether,
            10000 ether,
            10000 ether
        );

        Limits memory _srcLimits = Limits({
            mintingLimits: mintLimits__,
            burningLimits: burnLimits__
        });

        Limits memory _dstLimits = Limits({
            mintingLimits: burnLimits__,
            burningLimits: mintLimits__
        });

        srcToken__.setLimits(siblingChainSlug_, _srcLimits);
        dstToken__.setLimits(chainSlug_, _dstLimits);

        assertEq(
            srcToken__
                .getBridgeLimits(siblingChainSlug_)
                .burningLimits
                .maxLimit,
            _srcLimits.burningLimits.maxLimit
        );
        assertEq(
            dstToken__.getBridgeLimits(chainSlug_).mintingLimits.timestamp,
            _dstLimits.mintingLimits.timestamp
        );
    }

    function testCheckValidity() public {
        uint256 _mintAmount = 1000000000000 ether;
        uint256 _burnAmount = 100 ether;

        bool _srcMintBool = srcToken__.checkMintValidity(
            siblingChainSlug_,
            _mintAmount
        );

        bool _dstBurnBool = srcToken__.checkBurnValidity(
            siblingChainSlug_,
            _burnAmount
        );

        assertEq(_srcMintBool, false);
        assertEq(_dstBurnBool, true);
    }

    function testUniTransfer() public {
        uint x = 100000000;
        srcToken__.setDestChainGasLimit(siblingChainSlug_, x);

        uint _burnLimit = srcToken__.getBurnCurrentLimit(siblingChainSlug_);
        uint _mintLimit = dstToken__.getMintCurrentLimit(chainSlug_);

        assertEq(_burnLimit, 10000 ether);
        assertEq(_mintLimit, 10000 ether);

        uint256 _amount = 1 ether;
        srcToken__.uniTransfer(siblingChainSlug_, testUser, _amount);

        _burnLimit = srcToken__.getBurnCurrentLimit(siblingChainSlug_);
        _mintLimit = dstToken__.getMintCurrentLimit(chainSlug_);

        assertEq(_burnLimit, 10000 ether - _amount);
        assertEq(_mintLimit, 10000 ether - _amount);

        uint256 srcBalance = srcToken__.balanceOf(testUser);
        uint256 destBalance = dstToken__.balanceOf(testUser);

        assertEq(srcBalance, 0);
        assertEq(destBalance, _amount);
    }

    function testOverLimit() public {
        uint x = 100000000;
        srcToken__.setDestChainGasLimit(siblingChainSlug_, x);

        uint _burnLimit = srcToken__.getBurnCurrentLimit(siblingChainSlug_);
        uint _mintLimit = dstToken__.getMintCurrentLimit(chainSlug_);

        assertEq(_burnLimit, 10000 ether);
        assertEq(_mintLimit, 10000 ether);

        uint256 _amount = 100000000000 ether;
        vm.expectRevert();
        srcToken__.uniTransfer(siblingChainSlug_, testUser, _amount);

        _burnLimit = srcToken__.getBurnCurrentLimit(siblingChainSlug_);
        _mintLimit = dstToken__.getMintCurrentLimit(chainSlug_);

        assertEq(_burnLimit, 10000 ether);
        assertEq(_mintLimit, 10000 ether);
    }
}
