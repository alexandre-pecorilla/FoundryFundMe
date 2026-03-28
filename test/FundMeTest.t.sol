// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// Import the Test contract from forge standard library
// We also import console to print things on the terminal (useful for debugging)
import {Test, console} from "forge-std/Test.sol";

import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

// Our Test contract Inherits from the Test contract of the forge standard lib
contract FundMeTest is Test {
    FundMe fundMe;

    // Deploy the smart contract (need before we can test it)
    // Later we learn how to deploy from the script, so that our testing and deploy environment are the same
    // its the first function executed when testing
    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundMe.i_owner());
        console.log(msg.sender);

        // This works because DeployFundMe.run() uses vm.startBroadcast(), which makes
        // the deployment appear as if it comes from msg.sender (us), not from the DeployFundMe contract.
        // So FundMe's constructor sees msg.sender as our address, and i_owner matches msg.sender here.
        // Note: without the deploy script (using new FundMe(...) directly), the owner would be
        // address(FundMeTest) and this assertion would fail.
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 priceFeedVersion = fundMe.getVersion();
        console.log((priceFeedVersion));
        assertEq(priceFeedVersion, 4);
    }
}
