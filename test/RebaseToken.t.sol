// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract RebaseTokenTest is Test {
    RebaseToken private s_rebaseToken;
    Vault private s_vault;

    address private owner = makeAddr("owner");
    address private user = makeAddr("user");

    function setUp() external {
        vm.startPrank(owner);
        s_rebaseToken = new RebaseToken();
        s_vault = new Vault(IRebaseToken(address(s_rebaseToken)));
        s_rebaseToken.grantMintAndBurnRole(address(s_vault));
        vm.stopPrank();
    }

    function addRewardsToVault(uint256 rewardsAmount) public {
        (bool success,) = payable(address(s_vault)).call{value: rewardsAmount}("");
    }

    function testDepositLinear(uint256 amount) external {
        // vm.assume(amount > 1e5);
        amount = bound(amount, 1e5, type(uint96).max);

        vm.startPrank(user);
        vm.deal(user, amount);
        s_vault.deposit{value: amount}();

        uint256 startBalance = s_rebaseToken.balanceOf(user);
        console.log("startBalance", startBalance);
        assertEq(startBalance, amount);

        vm.warp(block.timestamp + 1 hours);
        uint256 middleBalance = s_rebaseToken.balanceOf(user);
        console.log("middleBalance", middleBalance);
        assertGt(middleBalance, startBalance);

        vm.warp(block.timestamp + 1 hours);
        uint256 endBalance = s_rebaseToken.balanceOf(user);
        console.log("endBalance", endBalance);
        assertGt(endBalance, middleBalance);

        assertApproxEqAbs((endBalance - middleBalance), (middleBalance - startBalance), 1);
        vm.stopPrank();
    }

    function testRedeemStraightAway(uint256 amount) external {
        amount = bound(amount, 1e5, type(uint96).max);

        vm.startPrank(user);
        vm.deal(user, amount);
        s_vault.deposit{value: amount}();
        assertEq(s_rebaseToken.balanceOf(user), amount);

        s_vault.redeem(type(uint256).max);
        assertEq(s_rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, amount);
        vm.stopPrank();
    }

    function testRedeemAfterTimePassed(uint256 depositAmount, uint256 time) external {
        time = bound(time, 1000, type(uint96).max);
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);

        vm.deal(user, depositAmount);
        vm.prank(user);
        s_vault.deposit{value: depositAmount}();

        vm.warp(block.timestamp + time);
        uint256 balanceAfterSomeTime = s_rebaseToken.balanceOf(user);

        vm.deal(owner, balanceAfterSomeTime - depositAmount);
        vm.prank(owner);
        addRewardsToVault(balanceAfterSomeTime - depositAmount);

        vm.prank(user);
        s_vault.redeem(type(uint256).max);

        uint256 ethBalance = address(user).balance;
        assertEq(balanceAfterSomeTime, ethBalance);
        assertGt(ethBalance, depositAmount);
    }

    function testTransfer(uint256 amount, uint256 amountToSend) external {
        amount = bound(amount, 1e5 + 1e5, type(uint96).max);
        amountToSend = bound(amountToSend, 1e5, amount - 1e5);
        vm.deal(user, amount);
        vm.prank(user);
        s_vault.deposit{value: amount}();

        address user2 = makeAddr("userToReceive");
        uint256 userBalance = s_rebaseToken.balanceOf(user);
        uint256 user2Balance = s_rebaseToken.balanceOf(user2);
        assertEq(userBalance, amount);
        assertEq(user2Balance, 0);

        vm.prank(owner);
        s_rebaseToken.setInterestRate(4e10);

        vm.prank(user);
        s_rebaseToken.transfer(user2, amountToSend);

        uint256 userBalanceAfterTransfer = s_rebaseToken.balanceOf(user);
        uint256 user2BalanceAfterTransfer = s_rebaseToken.balanceOf(user2);
        assertEq(userBalanceAfterTransfer, userBalance - amountToSend);
        assertEq(user2BalanceAfterTransfer, amountToSend);

        assertEq(s_rebaseToken.getUserInterestRate(user), 5e10);
        assertEq(s_rebaseToken.getUserInterestRate(user2), 5e10);
    }

    function testCannotSetInterestRate(uint256 newInterestRate) external {
        vm.prank(user);
        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        s_rebaseToken.setInterestRate(newInterestRate);
    }

    function testCannotCallMintAndBurn() external {
        vm.prank(user);
        uint256 interestRate = s_rebaseToken.getInterestRate();
        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        s_rebaseToken.mint(user, 100, interestRate);
        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        s_rebaseToken.burn(user, 100);
    }

    function testGetPrincipalAmount(uint256 amount) external {
        amount = bound(amount, 1e5, type(uint96).max);
        vm.deal(user, amount);
        vm.prank(user);
        s_vault.deposit{value: amount}();
        assertEq(s_rebaseToken.principalBalanceOf(user), amount);

        vm.warp(block.timestamp + 1 hours);
        assertEq(s_rebaseToken.principalBalanceOf(user), amount);
    }

    function testGetRebaseTokenAddress() external view {
        address rebaseTokenAddress = s_vault.getRebaseTokenAddress();
        assertEq(rebaseTokenAddress, address(s_rebaseToken));
    }

    function testInterestRateCanOnlyDecrease(uint256 newInterestRate) external {
        uint256 initialInterestRate = s_rebaseToken.getInterestRate();
        newInterestRate = bound(newInterestRate, initialInterestRate, type(uint96).max);
        vm.expectPartialRevert(RebaseToken.RebaseToken__InterestRateCanOnlyDecrease.selector);
        vm.prank(owner);
        s_rebaseToken.setInterestRate(newInterestRate);
        assertEq(initialInterestRate, s_rebaseToken.getInterestRate());
    }
}
