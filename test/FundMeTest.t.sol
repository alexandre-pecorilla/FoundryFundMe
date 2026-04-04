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

    /**
     * makeAddr is a Foundry utility (from forge-std) that generates a deterministic Ethereum address from a string label.
     * It's a clean way to create fake users for your tests without hardcoding random-looking addresses.
     */
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    // Deploy the smart contract (need before we can test it)
    // Later we learn how to deploy from the script, so that our testing and deploy environment are the same
    // its the first function executed when testing
    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // give some funds to the USER address
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);

        // This works because DeployFundMe.run() uses vm.startBroadcast(), which makes
        // the deployment appear as if it comes from msg.sender (us), not from the DeployFundMe contract.
        // So FundMe's constructor sees msg.sender as our address, and i_owner matches msg.sender here.
        // Note: without the deploy script (using new FundMe(...) directly), the owner would be
        // address(FundMeTest) and this assertion would fail.
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 priceFeedVersion = fundMe.getVersion();
        console.log((priceFeedVersion));
        assertEq(priceFeedVersion, 4);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // Expect the next call to revert. If that call does revert, the test passes; if it doesn't revert, the test fails.
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // With this, the next transaction will be sent by USER instead of msg.sender
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        // Each test runs in isolation: setUp() redeploys FundMe from scratch before every test,
        // so the funders array always starts empty. That's why we can safely read index 0 here,
        // even though other tests also call fund() — their state doesn't carry over.
        // This is the case even if the test function has a modifier
        address funder = fundMe.getFunder(0);

        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // It will revert, because msg.sender deployed the contract and is therefore the owner
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange (setup the test)
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // balance of the owner, 0 ETH
        uint256 startingFundMeBalance = address(fundMe).balance; // balance of the contract, 0.1 ETH

        // Act (do the action you actually want to test)

        // vm.prank is needed here because when FundMeTest calls fundMe.withdraw() directly,
        // FundMe sees msg.sender as address(FundMeTest), not as the owner.
        // The owner was set during deployment (DeployFundMe used vm.startBroadcast, which made
        // the default forge sender the deployer/owner), but that broadcast only applied to
        // that specific moment. After that, normal Solidity call rules apply:
        // when contract A calls contract B, msg.sender in B is address(A).
        // So without vm.prank, withdraw() would revert with FundMe__NotOwner.
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert (test)
        uint256 endingOwnerBalance = fundMe.getOwner().balance; // balance of the owner is now 0.1 ETH because of the withdrawn
        uint256 endingFundMeBalance = address(fundMe).balance; // Now 0

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange

        // We use uint160 (not uint256) because addresses in Solidity are 20 bytes = 160 bits,
        // so uint160 is the exact size that can be cast to an address without losing data.
        uint160 numberOfFunders = 10;
        // We start at index 1 (skipping 0) because address(0) is the zero address,
        // which is reserved and often rejected by contracts.
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // For each iteration we need a fresh funder: create an address, give it some ETH,
            // then prank as that address to call fund(). `hoax` is a forge-std shortcut that
            // does both vm.deal + vm.prank in one call.
            // address(i) casts the uint160 into an Ethereum address — that's why we used uint160 above.
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance; // balance of the owner, 0 ETH
        uint256 startingFundMeBalance = address(fundMe).balance; // balance of the contract, 0.1 ETH

        // Act

        // Alternative syntax to vm.prank.
        // vm.prank only affects the very next call, while vm.startPrank/stopPrank
        // makes every call in between appear to come from the given address.
        // Useful when you need multiple consecutive calls from the same impersonated sender.
        // It's the same idea as vm.startBroadcast/stopBroadcast, but for tests instead of scripts.
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
