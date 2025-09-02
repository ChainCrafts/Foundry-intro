// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
/*               setUp()
                testFunction1()

                setUp()
                testFunction2()

                setUp()
                testFunction3()

                            like this */

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
/*4 different types of tests:

Unit tests: Focus on isolating and testing individual smart contract functions or functionalities.

Integration tests: Verify how a smart contract interacts with other contracts or external systems.

Forking tests: Forking refers to creating a copy of a blockchain state at a specific point in time. This copy, called a fork, is then used to run tests in a simulated environment.

Staging tests: Execute tests against a deployed smart contract on a staging environment before mainnet deployment.

 */

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user1"); //1000 ether is the initial balance of this address
    address USER2 = makeAddr("user2"); //1000 ether is the initial balance of this address

    uint256 constant STARTING_BALANCE_OF_USER = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;

    uint256 GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE_OF_USER);
        vm.deal(USER2, STARTING_BALANCE_OF_USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOwnerIsMessageSender() external view {
        // assertEq(fundMe.i_owner(), address(this)); // Test contract deployed FundMe, so it's the owner

        //now that we updated the codebase and creating the contract from the deploy contract .thus the owner is msg.sender
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testMinimumUSDIsFive() external view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
        assertNotEq(fundMe.MINIMUM_USD(), 1e18);
    }

    function testPriceFeedVersionIsAccurate() external view {
        if (block.chainid == 11155111) {
            assertEq(fundMe.getVersion(), 4);
        } else if (block.chainid == 1) {
            assertEq(fundMe.getVersion(), 6);
        }
    }

    function testFundFailsWithoutEnoughETH() external {
        vm.expectRevert(); //expect the next line to revert
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() external funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() external funded {
        vm.prank(USER2);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        address funder2 = fundMe.getFunder(1);
        assertEq(funder, USER);
        assertEq(funder2, USER2);
    }

    function testOnlyOwnerCanWithdraw() external funded {
        vm.expectRevert();
        vm.prank(USER); //msg.sender is the owner
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() external funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithMultipleFundersWithdraw() external funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        // uint160 is used because addresses are 160-bit values;
        // using uint160 ensures the integer can safely be cast to an address without overflow.
        //because in here we are generating or getting address from numbers address(i)
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); //this is equivalent to vm.prank + vm.deal
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used:", gasUsed);

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithMultipleFundersWithdrawCheaper() external funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        // uint160 is used because addresses are 160-bit values;
        // using uint160 ensures the integer can safely be cast to an address without overflow.
        //because in here we are generating or getting address from numbers address(i)
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); //this is equivalent to vm.prank + vm.deal
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used:", gasUsed);

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }
}
