// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenTransfer.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenTranferTest is Test {
    using SafeERC20 for IERC20;
    TokenTransfer public tokenTransfer;    
    address constant sender = 0x5a5a25F48742f9d3D0F11b09ED96DBe4E3cCe7b5;
    
    function setUp() public {
        uint256 fork = vm.createFork("https://polygon-rpc.com/");
        vm.selectFork(fork);
     
        tokenTransfer = new TokenTransfer(0x38e55351Dc02320A555b137e559D71f213694c15, 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, 0x69B5c72837769eF1e7C164Abc6515DcFf217F920, 1e16);
        tokenTransfer.connect(42161, 0x32a80b98e33c3A0E57D635C56707208D29f970a2, "FAST");
        vm.startPrank(0x166716C2838e182d64886135a96f1AABCA9A9756);
        IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174).transfer(address(tokenTransfer), 1000000000);
        vm.stopPrank();
   }

    function testBridge() public {
        vm.startPrank(0x166716C2838e182d64886135a96f1AABCA9A9756);
        IERC20(address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)).safeIncreaseAllowance(address(tokenTransfer), 100000000);
        tokenTransfer.bridgeAndTransfer{value: 1}(0x32a80b98e33c3A0E57D635C56707208D29f970a2, 100000000, 42161, 1000000);
        // assertEq(counter.number(), 1);
    }
    function testInbound() public {
        vm.startPrank(0x38e55351Dc02320A555b137e559D71f213694c15);
        bytes memory payload = abi.encode(0x32a80b98e33c3A0E57D635C56707208D29f970a2, 1000000, "1");
        tokenTransfer.inbound(payload);
    }

    function testInboundFailedandClaim() public {
        vm.startPrank(0x38e55351Dc02320A555b137e559D71f213694c15);
        bytes memory payload = abi.encode(0x32a80b98e33c3A0E57D635C56707208D29f970a2, 1000000001, "2");
        tokenTransfer.inbound(payload);
        vm.stopPrank();
        vm.startPrank(0x166716C2838e182d64886135a96f1AABCA9A9756);
        IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174).transfer(address(tokenTransfer), 1000000000);
        tokenTransfer.retryClaim("2");
        vm.expectRevert(bytes("TokenTransfer: Already claimed"));
        tokenTransfer.retryClaim("2");
    }

    function testRetryClaimFail() public {
        vm.startPrank(0x166716C2838e182d64886135a96f1AABCA9A9756);
        vm.expectRevert(bytes("TokenTransfer: Invalid depositId"));
        tokenTransfer.retryClaim("2");
    }



    // function testSetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
