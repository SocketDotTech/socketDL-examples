// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/universalTokens/uniERC721/uniERC721.sol";
import "../src/mocks/MockSocket.sol";

contract uniERC721Test is Test {
    uniERC721 public srcToken__;
    uniERC721 public dstToken__;
    MockSocket public mockSocket__;

    uint32 chainSlug_ = 1;
    uint32 siblingChainSlug_ = 2;

    address public constant fastSwitchboard = address(1);
    address public constant optimisticSwitchboard = address(2);
    address public constant testUser = address(3);

    function setUp() public {
        mockSocket__ = new MockSocket(chainSlug_, siblingChainSlug_);
        srcToken__ = new uniERC721(
            address(mockSocket__),
            "TEST 1",
            "TEST",
            true
        );
        dstToken__ = new uniERC721(
            address(mockSocket__),
            "TEST 2",
            "TEST",
            false
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

    function testMintToken() public {
        vm.prank(testUser);
        srcToken__.mintToken();
        uint256 balance = srcToken__.balanceOf(testUser);
        assertEq(balance, 1);

        vm.expectRevert();
        dstToken__.mintToken();
        uint256 balanceDest = dstToken__.balanceOf(testUser);
        assertEq(balanceDest, 0);
    }

    function testUniTransfer() public {
        uint x = 100000000;
        srcToken__.setDestChainGasLimit(siblingChainSlug_, x);

        vm.prank(testUser);
        srcToken__.mintToken();
        uint256 _tokenId = 0;

        address _owner = srcToken__.ownerOf(_tokenId);
        uint256 _ownerSrcBalance = srcToken__.balanceOf(testUser);
        assertEq(_owner, testUser);
        assertEq(_ownerSrcBalance, 1);

        srcToken__.uniTransfer(siblingChainSlug_, testUser, _tokenId);

        vm.expectRevert();
        _owner = srcToken__.ownerOf(_tokenId);
        _ownerSrcBalance = srcToken__.balanceOf(testUser);
        assertEq(_ownerSrcBalance, 0);

        _owner = dstToken__.ownerOf(_tokenId);
        uint256 _ownerDstBalance = dstToken__.balanceOf(testUser);
        assertEq(_owner, testUser);
        assertEq(_ownerDstBalance, 1);
    }
}
