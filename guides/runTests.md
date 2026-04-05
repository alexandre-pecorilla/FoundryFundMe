# Run Test

Create tests in `test/.
Add suffix `.t.sol`

Then to run the tests:

```bash
forge test
```

If no RPC URL is specified, forge will spawn anvil, and terminate it once the tests are done.

To see the console.log calls we need to increase verbosity:

```bash
forge test -vv
```

The -vv flag sets verbosity level 2. Foundry has 5 levels:

`-v`     (level 1): shows which tests pass/fail
`-vv`    (level 2): adds logs emitted during tests (including console.log output)
`-vvv`   (level 3): adds stack traces for failing tests
`-vvvv`  (level 4): adds traces for all tests plus setup
`-vvvvv` (level 5): adds storage/memory details


To run a single test:

```bash
forge test --mt testPriceFeedVersionIsAccurate
```

## Fork a chain

If we try to run the test `testPriceFeedVersionIsAccurate` it will fail, because anvil is a local chain, and the chainlink contract address is from sepolia. 
To be able to run the test, we must tell forge to tell anvil that it must fork the sepolia chain:

```bash
forge test --fork-url $SEPOLIA_RPC_URL
```

(here $SEPOLIA_RPC_URL contains the RPC URL of our alchemy node).
The test will succeed and this is what happens in the background:

1. Anvil starts a local chain configured to fork Sepolia (no data is fetched yet)
2. Our test deploys FundMe locally on this chain
3. getVersion() is called — FundMe calls the Chainlink aggregator at 0x694AA...
4. Anvil's local EVM needs to execute the aggregator's code, but it doesn't have it
5. Anvil makes free read-only API queries to our Sepolia node to fetch the raw bytecode and relevant storage slots at that address (this isn't Alchemy-specific — reads are free on any Ethereum node, no transaction is created, no gas is spent)
6. Anvil caches that bytecode and storage into its local state — the Chainlink contract now effectively exists on the local chain
7. Anvil's local EVM executes the version() function itself against that cached bytecode and storage — nothing is ever executed on Sepolia


The reason Anvil doesn't just ask Sepolia for the return value of version() directly is that the EVM executes bytecode as one continuous sequence of instructions. When FundMe's bytecode hits a CALL opcode to the Chainlink aggregator, the EVM doesn't pause and go "let me ask someone else to run this part" — it needs the aggregator's bytecode right there in local state so it can keep executing. It's one EVM, one execution context. On top of that, FundMe only exists locally, so Sepolia couldn't run this call chain anyway — it doesn't have FundMe's bytecode. Anvil also needs full control over the execution for things like assertions, cheatcodes, and state changes.

## Coverage

The commands below shows us how much of our code is covered by tests. 
This helps us spot blind spots of what isn't being tested

```bash
fork coverage 
```

Of course if we have call to contracts that aren't on our local anvil chain we must fork

```bash
forge coverage --fork-url $SEPOLIA_RPC_URL
```



