// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployToken} from "../script/DeployToken.s.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    MyToken public myToken;
    DeployToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address carol = makeAddr("carol");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployToken();
        myToken = deployer.run();

        // Give Bob some tokens from deployer
        vm.prank(msg.sender);
        myToken.transfer(bob, STARTING_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                              BASIC TESTS
    //////////////////////////////////////////////////////////////*/

    function testNameAndSymbol() public view {
        assertEq(myToken.name(), "My Token");
        assertEq(myToken.symbol(), "MTK");
        assertEq(myToken.decimals(), 18);
    }

    function testTotalSupplyAfterMint() public view {
        assertGt(myToken.totalSupply(), 0);
    }

    function testBobBalance() public view {
        assertEq(myToken.balanceOf(bob), STARTING_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function testTransferUpdatesBalances() public {
        uint256 transferAmount = 10 ether;

        vm.prank(bob);
        myToken.transfer(alice, transferAmount);

        assertEq(myToken.balanceOf(alice), transferAmount);
        assertEq(myToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testTransferEmitsEvent() public {
        uint256 amount = 5 ether;

        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, alice, amount);

        myToken.transfer(alice, amount);
    }

    function testTransferFailsIfInsufficientBalance() public {
        uint256 tooMuch = STARTING_BALANCE + 1 ether;

        vm.prank(bob);
        vm.expectRevert();
        myToken.transfer(alice, tooMuch);
    }

    /*//////////////////////////////////////////////////////////////
                            ALLOWANCE TESTS
    //////////////////////////////////////////////////////////////*/

    function testApproveSetsAllowance() public {
        vm.prank(bob);
        myToken.approve(alice, 1000);

        assertEq(myToken.allowance(bob, alice), 1000);
    }

    function testApprovalEmitsEvent() public {
        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Approval(bob, alice, 1000);
        myToken.approve(alice, 1000);
    }

    function testIncreaseAllowance() public {
        vm.prank(bob);
        myToken.approve(alice, 1000);

        vm.prank(bob);
        myToken.increaseAllowance(alice, 500);

        assertEq(myToken.allowance(bob, alice), 1500);
    }

    function testDecreaseAllowance() public {
        vm.prank(bob);
        myToken.approve(alice, 1000);

        vm.prank(bob);
        myToken.decreaseAllowance(alice, 400);

        assertEq(myToken.allowance(bob, alice), 600);
    }

    function testTransferFromWorks() public {
        uint256 initialAllowance = 1000;
        uint256 transferAmount = 500;

        vm.prank(bob);
        myToken.approve(alice, initialAllowance);

        vm.prank(alice);
        myToken.transferFrom(bob, alice, transferAmount);

        assertEq(myToken.balanceOf(alice), transferAmount);
        assertEq(myToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(
            myToken.allowance(bob, alice),
            initialAllowance - transferAmount
        );
    }

    function testTransferFromFailsWithoutApproval() public {
        vm.expectRevert();
        vm.prank(alice);
        myToken.transferFrom(bob, alice, 1);
    }

    function testTransferFromEmitsEvent() public {
        vm.prank(bob);
        myToken.approve(alice, 1000);

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, alice, 100);
        myToken.transferFrom(bob, alice, 100);
    }

    /*//////////////////////////////////////////////////////////////
                            EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function testApproveZeroAddressFails() public {
        vm.expectRevert();
        vm.prank(address(0));
        myToken.approve(alice, 100);
    }

    function testTransferToZeroAddressReverts() public {
        vm.prank(bob);
        vm.expectRevert();
        myToken.transfer(address(0), 1 ether);
    }

    function testTransferFromToZeroAddressReverts() public {
        vm.prank(bob);
        myToken.approve(alice, 100);

        vm.prank(alice);
        vm.expectRevert();
        myToken.transferFrom(bob, address(0), 1);
    }

    function testAllowanceDoesNotUnderflow() public {
        vm.prank(bob);
        myToken.approve(alice, 50);

        vm.prank(alice);
        myToken.transferFrom(bob, alice, 50);

        // try to spend more than allowance
        vm.expectRevert();
        vm.prank(alice);
        myToken.transferFrom(bob, alice, 1);
    }

    function testCannotTransferMoreThanTotalSupply() public {
        uint256 tooMuch = myToken.totalSupply() + 1;

        vm.expectRevert();
        vm.prank(bob);
        myToken.transfer(alice, tooMuch);
    }
}
