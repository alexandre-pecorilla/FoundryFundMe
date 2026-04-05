# Storage Optimizations

This link details the different EVM operations and their minimum gas cost => https://www.evm.codes/

Reading and writing from storage (`SLOAD` and `SSTORE`) are the most expensive operations.
Reading and writing for memory is much cheaper (`MLOAD` and `MSTORE`).

So whenever we can, we want to limit the reading and writing of storage and use memory reads/writes instead.

Take the function `withdraw` of `FundMe`:

```solidity
    function withdraw() public onlyOwner {
        // reset the mapping
        for (
            uint256 funderIndex;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addresssToAmountFunded[funder] = 0;
        }
...
```

At every iteration of the loop, we check the lenght of a storage variable with `funderIndex < s_funders.length;`. This leads to a lot of SLOAD operations which increases the gas cost of our functions.

It needs to be optimized. We can do this by storing the length in a variable, that way we only call from storage once.

```solidity
    function cheaperWithdraw public owner {
        uint256 fundersLength = s_funders.length;

        for (
            uint256 funderIndex;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addresssToAmountFunded[funder] = 0;
        }
    }
```

If we make a test for it and then run `forge snapshot` will see that `testWithdrawFromMultipleFundersCheaper` costs less gas than `testWithdrawFromMultipleFunders`.

