//in this script, we will define the interactions for the smart contract
//in this particular case they are 'fund' and 'withdraw'

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 public constant FUND_AMOUNT = 0.1 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: FUND_AMOUNT}();
        vm.stopBroadcast();
    }

    function run() external {
        // Implement the fund interaction logic here
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(mostRecentlyDeployed);
    }
}

contract WithdrawFundMe is Script {
    uint256 public constant WITHDRAW_AMOUNT = 0.1 ether;

    function withdrawFundMe(address mostRecentlyyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyyDeployed)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(mostRecentlyDeployed);
    }
}
