// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";

// creating a custom error to save gas
error FundMe__NotOwner();

contract FundMe {
    // allows us to call the functions of PriceConverter from uint256, like msg.value.getEthConversionRate()
    // the uint256 is passed as the first argument
    using PriceConverter for uint256;

    // the minimum amount in USD we want to require for calling the fund function
    // we have to add 18 zeros to it because solidity doesnt have floating numbers and speaks in wei, where 1 ETH = 1 * 1e18
    // so 5 dollars is represented as 5000000000000000000 which is equivalent to $5.000000000000000000, so 18 decimals
    // constants are variables that are assigned directly at compile time where they are declared and outside of functions
    // their value can't change, and they dont take storage space because the EVM hardcode the value in the contract bytecode
    // they lower gas costs when deploying and interacting with the contract
    // uppercases and underscores is the standard for constants
    uint256 public constant MINIMUM_USD = 5 * 1e18; // can also be 5e18

    // array of addresses that sent us money
    // We are just reserving a "parking spot" in the contract's permanent storage.
    // Because it's just a reservation, it defaults to an empty array (length 0).
    // We don't need the 'new' keyword or a size because we aren't physically
    // allocating a chunk of memory yet.
    address[] public funders;

    // key is an address, value is how much this address funded the contract (since the last withdrawal)
    mapping(address funder => uint256 amountFunded)
        public addresssToAmountFunded;

    // immutables are variables similar to constants but their value is assigned only once at deployment, usually in the constructor
    // so they aren't assigned where they're declared (in the state outside any function) like constants, but their value is assigned only once
    // just like constants, their values can't change and they don't take storage space either because like constants the EVM hardcode the value in the contract bytecode
    // they lower gas costs when deploying and interacting with the contract
    // the convention for immutable variables names is to start with i_
    address public immutable i_owner;

    // function immediately called when we deploy the contract
    // its called in the same transaction that deploys the contract
    constructor() {
        i_owner = msg.sender; // set the owner address to our address (since we are the ones deploying the contract, msg.sender will be our address)
    }

    // payable function
    // you can send eth to this function to fund the smart contract
    function fund() public payable {
        // require a minimum of <minimumUsd> to be sent
        // unlike in the previous commit where we required 1 ETH, here we require a dollar amount
        // Therefore we will need to call an oracle to get the spot price of ethereum in ETH
        // That way we can require a minimum amount of ETH that matches minimumUSD
        require(
            msg.value.getConversionRate() >= MINIMUM_USD,
            "You must sent at least $5."
        ); // This is allowd because we did using PriceConverter for uint256;
        funders.push(msg.sender); // store the address of the sender to the array
        addresssToAmountFunded[msg.sender] += msg.value; // store the amount sent by the sender
    }

    // withdraw funds and reset the funders array and mapping addresssToAmountFunded
    function withdraw() public onlyOwner {
        // reset the mapping
        for (uint256 funderIndex; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addresssToAmountFunded[funder] = 0;
        }

        // reset the array
        // To wipe the array clean, we build a brand new array and overwrite the old one.
        // The 'new' keyword tells Solidity: "Allocate a new chunk of memory right now."
        // THE RULE: When using 'new' to build an array in memory, Solidity absolutely
        // requires us to tell it the exact starting size.
        // So, '(0)' explicitly means "make this brand new array exactly zero items long."
        funders = new address[](0);

        // SENDING ETH FROM THE CONTRACT
        // 3 methods are possible: transfer, send and call

        // transfer
        // => deprecated soon
        // transfer is capped at 2300 gas and errors out if it has to spend more (and therefor reverses the transaction)
        // as a reminder, it costs roughly 2100 gas to send eth from one address to another
        // whoever calls this function will withdraw the funds (msg.sender)
        // we have to cast msg.sender into a payable address
        // then we call transfer
        // we pass the whole contract balance with address(this).balance

        // payable(msg.sender).transfer(address(this).balance);

        // send
        //  => deprecated
        // it also has the 2300 gas limit, but it wont error out. Instead it returns a boolean, true if transfer was successful, false otherwise
        // if it fails, the contract wouldnt revert the transaction and continue execution

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        // the one to use
        // no gas limit
        // returns bools for success/failure
        // call is very powerful, we can call any function on the blockchain with it
        // here we use it to send a transaction, so we use the value field of an eth transaction
        // and we give it the whole contract balance
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // function modifier (decorator) to only allow the owner to access a function
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Must be owner");

        // this is cheaper in gas than the above because we don't have to pull "Must be owner" into memory everytime the function is called
        if (msg.sender != i_owner) {
            revert NotOwner();
        }

        // the below must be at the end of the modifier if we want the modifier to execute FIRST before a function code is executed
        // if we put it at the beginning of the modifier (before the require) the modifier executes LAST after a function codei is executed
        // this _; basically means "do whatever that is in the function that is modified (decorated)
        _;
    }

    // What happens if someone sends eth to this contract without calling the fund function, directly with the contract address instead

    // receive()
    // this function is called if someone sends ETH directly using the contract address, without using our fund function
    // there can be only be one receive function, it has to be external, payable and takes no arguments
    // so receive() is the catcher, or the fallback for any monetary transaction
    // i.e. transaction with a value (msg.value) and no data (msg.data)
    // if there is data (msg.data) it goes to fallback() instead
    receive() external payable {
        fund(); // we make it call fund()
    }

    // fallback()
    // It's like receive(), but for transactions that have data
    // so if you receive a transaction that has data (msg.data) and doesn't call any know functions, it fallbacks here
    // note that even if it has value (msg.value), as long as it has data (msg.data) it falls back here
    fallback() external payable {
        fund(); // we also call fund here because we are greedy, so even if there is unexpected data in msg.data, if there is value (msg.value) we take it!
    }
}
