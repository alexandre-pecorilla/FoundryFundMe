# Install Dependencies

Remix automatically resolves and fetches imports like `AggregatorV3Interface.sol` from `@chainlink`:

```solidity
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
```

Foundry can't do this, so we need to install the package locally:

```bash
forge install smartcontractkit/chainlink-brownie-contracts
```

This clones the [smartcontractkit/chainlink-brownie-contracts](https://github.com/smartcontractkit/chainlink-brownie-contracts) repo (`owner/repo` shorthand) as a git submodule into `lib/chainlink-brownie-contracts/`. The package contains all of Chainlink's contracts and interfaces — originally designed for Brownie but compatible with Foundry.

After install, `AggregatorV3Interface.sol` is at:
`lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol`

Foundry still doesn't know that `@chainlink/contracts/` in our import maps to that local path. We need to add a remapping in `foundry.toml` under `[profile.default]`:

```toml
remappings = ["@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/"]
```

This tells Foundry: when you see `@chainlink/contracts/`, resolve it to `lib/chainlink-brownie-contracts/contracts/`. Now `forge build` can find the file.