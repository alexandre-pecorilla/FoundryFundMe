// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// Import the AggregatorV3Interface from Chainlink.
// This acts as a 'Solidity-native ABI': it provides the compiler with the function signatures
// and return types necessary to interact with the external Chainlink Price Feed contract.
// Without this definition, our contract wouldn't know how to format the call to the
// external address or how to decode the data sent back.
// The Interface is to the EVM compiler what the ABI is to the frontend application
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// Our own library
library PriceConverter {
    // function to fetch the live price of ethereum from the Chainlink Sepolia reference contract
    // Chainlink returns the value with 8 decimals precision
    // e.g. 197338954554 => $1973.38954554
    function getEthPrice() internal view returns (uint256) {
        // Wrap the sepolia contract address in the Interface so we can make calls
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );

        // Call for the latest price
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getConversionRate(
        uint256 ethAmount
    ) internal view returns (uint256) {
        // remember it has only 8 decimals so we need to add 10 zeros
        // so 197338954554 becomes 1973389545540000000000 which is $1973.389545540000000000 (remember solidity has no floating numbers so this is just mental representation)
        uint256 ethPrice = getEthPrice() * 1e10; // so now we have the current eth price in the proper format with 18 decimal precision

        // now we can multiply the ethPrice with the ethAmount, which comes from msg.value passed as an argument which is in wei with 18 decimal precision so its perfect
        // so both have a precision of 18 decimals
        uint256 ethAmountUSD = ethPrice * ethAmount;

        // we return the amount in USD divided by 1e18 to go back to 18 decimal precision
        // because multiplying two numbers with 18 decimals precision give us 36 decimal precision
        return ethAmountUSD / 1e18;
    }
}
