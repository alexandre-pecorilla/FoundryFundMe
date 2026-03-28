# Questions & Answers

## 1. What goes on-chain vs off-chain when running a deploy script?

**Q:** When I call `run()` on `DeployFundMe.s.sol`, only what's between `vm.startBroadcast()` and `vm.stopBroadcast()` goes in a transaction that's broadcasted to the blockchain. All the rest (tests, HelperConfig, etc.) stays off-chain. But how is that code executed?

**A:** Everything outside the broadcast markers runs locally in Foundry's built-in EVM. When you run `forge script`, Foundry compiles the Solidity, spins up its local EVM, and executes the code. Only when it hits `startBroadcast` does it start recording transactions to send to the real blockchain (if `--broadcast` is passed). Tests work the same way — entirely in Foundry's local EVM. The `vm` cheatcodes only exist in Foundry's EVM, not on a real blockchain.

---

## 2. Is it one transaction or multiple?

**Q:** You said "recorded transactions" but isn't it sent as 1 transaction only?

**A:** In `DeployFundMe`, yes — there's only one operation (deploying `FundMe`) so it's one transaction. But if you had multiple state-changing operations between the broadcast markers, each would be its own transaction. `startBroadcast/stopBroadcast` defines a window during which transactions are recorded, not a single transaction wrapper.

---

## 3. Multiple transactions means multiple signatures and gas fees?

**Q:** That would mean to deploy I would need to sign and pay gas fees for 3 different transactions?

**A:** Yes, exactly. Each transaction requires its own signature and gas fee. That's why some projects use factory contracts or initializer patterns to bundle operations into a single transaction.

---

## 4. Is the variable assignment sent in the transaction?

**Q:** In `DeployFundMe`, I don't only create a new `FundMe` contract, I also store it in a variable. Isn't this sent in the transaction?

**A:** No. The variable `fundMe` is just a local reference in Foundry's local EVM — useful for the script (like returning it so tests can use it). On-chain, the only thing that happens is the deployment of the `FundMe` bytecode. The blockchain doesn't have script-level variables. What comes back from the network is the deployed contract's address, which Foundry stores locally in that variable.

---

## 5. How does HelperConfig know the chain ID if it runs off-chain?

**Q:** In the constructor of `HelperConfig`, it checks `block.chainid`. But since it's not between `startBroadcast/stopBroadcast`, how does it know the chain ID if it's just Solidity code executed in the local EVM?

**A:** `block.chainid` is a native Solidity global, not a cheatcode. When you run `forge script` with an `--rpc-url` (e.g. pointing to Sepolia), Foundry configures its local EVM to match that chain's context, including the chain ID. Without an `--rpc-url`, it defaults to Anvil's chain ID (`31337`).

---

## 6. Why is there a `vm.startBroadcast/stopBroadcast` in `getAnvilEthConfig()`?

**Q:** Why does `getAnvilEthConfig()` in `HelperConfig` use `vm.startBroadcast()` and `vm.stopBroadcast()`?

**A:** Because on Anvil there's no Chainlink price feed already deployed, so you need to deploy a mock one yourself. Deploying a contract is a transaction, so it needs broadcast markers. On Sepolia, the Chainlink price feed already exists at a known address, so `getSepoliaEthConfig` just returns it — no transaction needed. This means deploying on Anvil actually produces 2 transactions: one for the mock price feed and one for `FundMe`.

---

## 7. Confirming the two transactions after deploying on Anvil

**Q:** After deploying on Anvil, the output showed two transactions. The mock Chainlink price feed was block 1 at `0x5FbDB2315678afecb367f032d93F642f64180aa3`, and `FundMe` was block 2 at `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`. Correct?

**A:** Yes, exactly. This confirms the two-transaction behavior discussed in question 6. The mock deploys first (block 1), then `FundMe` (block 2). The return value shown at the top of the output matches the `FundMe` address, which is what the `run()` function returns.

---

## 8. What does the `address(0)` check do in `getAnvilEthConfig()`?

**Q:** Explain `if (activeNetworkConfig.priceFeed != address(0)) { return activeNetworkConfig; }` in `getAnvilEthConfig`.

**A:** It's a guard to avoid deploying the mock more than once. `address(0)` (`0x000...000`) is the default value for an address in Solidity. On the first call, `priceFeed` is still `address(0)`, so the check fails and the mock gets deployed. On any subsequent call, `priceFeed` is already set to a real address, so the check passes and it returns the existing config without deploying another mock.

---

## 9. How does `priceFeed` stay set if it's not on-chain?

**Q:** We said only what's between `vm.startBroadcast/stopBroadcast` gets sent to the chain. So how does `priceFeed` remain set with a value?

**A:** Everything in a Foundry script runs in the local EVM. `startBroadcast/stopBroadcast` doesn't change where code executes — it just **flags** certain operations to also be replicated on-chain. So after a run, on-chain you only have the mock and FundMe deployments, but locally everything existed (including `HelperConfig` and its state).

The key insight: on-chain state persists across script runs, but Foundry's local EVM is ephemeral — it starts fresh every time. So on a second run, `priceFeed` is back to `address(0)` and a new mock gets deployed.

The `address(0)` guard only protects within a **single script execution** — if `getAnvilEthConfig()` is called multiple times in the same run, it ensures the mock is deployed only once so all callers get the same price feed address.

---

## 10. Why does `testOwnerIsMsgSender` pass?

**Q:** Why is `testOwnerIsMsgSender` passing when asserting `fundMe.i_owner() == msg.sender`?

**A:** Because `setUp()` uses `DeployFundMe.run()`, which deploys `FundMe` inside `vm.startBroadcast()`. `startBroadcast` makes transactions appear as if they come from the original caller, not from the `DeployFundMe` contract.

When running `forge test`, you don't specify an address — Foundry assigns a **default hardcoded address** as the caller automatically. So:
- `msg.sender` inside `FundMeTest` is that default Foundry address
- `vm.startBroadcast()` makes the `FundMe` deployment come from that same default address
- So `i_owner` and `msg.sender` match

Without the deploy script (using `new FundMe(...)` directly in setUp), the owner would have been `address(FundMeTest)` instead, and the assertion against `msg.sender` would fail.
