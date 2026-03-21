# Run Test

Create tests in `test/.
Add suffix `.t.sol`

Then to run the tests:

```bash
forge test
```

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

