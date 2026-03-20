// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// Import the Test contract from forge standard library
// We also import console to print things on the terminal (useful for debugging)
import {Test, console} from "forge-std/Test.sol";

import {FundMe} from "../src/FundMe.sol";

// Our Test contract Inherits from the Test contract of the forge standard lib
contract FundMeTest is Test {
    FundMe fundMe;

    // Deploy the smart contract (need before we can test it)
    // Later we learn how to deploy from the script, so that our testing and deploy environment are the same
    // its the first function executed when testing
    function setUp() external {
        fundMe = new FundMe();
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }
}
