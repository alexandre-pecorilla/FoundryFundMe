# Gas Optimizations

## Gas units vs gas cost (the key distinction)

Before measuring anything, you need to understand that **gas units** and **gas cost** are two different things.

### Gas units
An abstract measure of computational work. Every EVM operation has a fixed gas-unit cost:
- `ADD` → 3 gas units
- `SSTORE` (write to storage) → 20,000 gas units for a fresh slot
- etc.

Gas units tell you **how much work** an operation performs. Optimizing gas units means making your code do less work.

### Gas cost (in ETH/wei)
The actual money spent on a transaction. Computed as:

```
gasCost = gasUnitsUsed * tx.gasprice
```

### `tx.gasprice`
A field on the transaction itself — how much the sender is willing to pay **per unit of gas**, in wei. On real chains it varies with network congestion: when demand is high, users bid higher gas prices to get included in a block faster.

### The car analogy
- **gas units** = liters of fuel consumed
- **`tx.gasprice`** = price per liter
- **gas cost** = liters × price per liter

Two transactions with identical `gasUsed` can cost very different amounts of ETH depending on `tx.gasprice` at the time they were sent.

---

## Measuring gas in forge tests

### `forge snapshot`

```bash
forge snapshot
forge snapshot --mt <testName>   # filter by test name
forge snapshot --check           # fail if any test's gas usage has changed
```

Runs the matching tests and writes the **gas used** for each test into a `.gas-snapshot` file at the project root.

Notes:
- The number reported is the gas consumed by the **entire test function** — modifiers, loops, cheatcodes, assertions, etc. It is **not** per-transaction.
- `setUp()` is **not** included in the snapshot.
- Cheatcodes like `vm.prank`, `hoax`, `vm.deal`, `vm.txGasPrice` don't count toward gas.
- Main use: track gas changes across commits. Commit `.gas-snapshot`, then later `forge snapshot --check` will detect any test whose gas usage has changed.

### Measuring gas for a specific call with `gasleft()`

`gasleft()` is a Solidity built-in that returns **how much gas is still available** for the current transaction — **not** how much has been used. Think of it as a fuel gauge reading.

To benchmark a single call, take two readings — one before and one after — and compute the delta:

```solidity
uint256 gasStart = gasleft();
vm.prank(fundMe.getOwner());
fundMe.withdraw();
uint256 gasEnd = gasleft();

uint256 gasUsed = gasStart - gasEnd;              // gas units consumed (unitless count)
uint256 gasCost = gasUsed * tx.gasprice;          // cost in WEI
console.log("Gas used:", gasUsed);
console.log("Gas cost (wei):", gasCost);
```

**Important**: the absolute value of `gasStart` or `gasEnd` is meaningless on its own — only the delta matters. In forge tests, the default gas budget is very large, so these values will be big numbers.

**Naming matters**: some tutorials name the multiplied value `gasUsed`, but that's misleading — `gasUsed` should be the raw delta (work units), while `gasCost` is the value in wei after multiplying by `tx.gasprice`. Keep them separate.

### Why `gasCost` is in wei (units breakdown)

- `gasUsed` → unitless count of work units
- `tx.gasprice` → wei per gas unit
- `gasUsed × tx.gasprice` → wei

So the cost is always in wei. To *display* it in ETH you'd divide by `1e18`, but Solidity has no floating-point numbers, so the division would lose precision. Just keep the value in wei for assertions.

### Printing with `console.log`

Solidity does NOT support string concatenation with `+`. But forge-std's `console.log` accepts multiple comma-separated arguments:

```solidity
console.log("Gas Used:", gasUsed);
console.log("Gas Cost (wei):", gasCost);
```

It has overloads for combinations like `(string, uint)`, `(string, address)`, `(string, string)`, up to 4 arguments.

### Using ether/gwei suffixes

Solidity has built-in unit suffixes to make wei values readable:

```solidity
uint256 constant GAS_PRICE = 20 gwei;  // = 20 * 1e9 wei
uint256 constant STARTING_BALANCE = 10 ether; // = 10 * 1e18 wei
```

Use them when setting gas prices or balances — they make intent obvious and avoid counting zeros.

### `vm.txGasPrice`

By default in forge tests, `tx.gasprice` is `0`. That means any calculation like `gasUsed * tx.gasprice` would also return `0`, making it impossible to see real cost differences.

Fix: set a non-zero gas price in the test.

```solidity
uint256 constant GAS_PRICE = 1;

function testSomething() public {
    vm.txGasPrice(GAS_PRICE);
    // ... benchmarking code using gasleft() and tx.gasprice ...
}
```

**Scope**: unlike `vm.prank` (which only affects the next call), `vm.txGasPrice` applies to **all subsequent transactions in the test**. It persists until the test ends or until you call `vm.txGasPrice` again with a different value. Each test starts fresh with `tx.gasprice = 0`, so if you put it in one test it does **not** carry over to others — put it in `setUp()` if you want it applied to every test.

Only needed when you're multiplying gas units by `tx.gasprice` to get a cost in wei. If you only care about raw gas units (which is usually enough for optimization work), you don't need this.

---

## Notes on forge test gas semantics

- **Gas is calculated but NOT deducted from sender balance.** In forge tests, you can `vm.prank` as an address with 0 ETH and still successfully call functions — forge doesn't enforce the "sender must have enough ETH to pay for gas" rule that real chains do. Gas is tracked for reporting (so `gasleft()` works), but never actually charged. This is why the `fundMe.getOwner()` address in our withdraw test can call `withdraw()` despite having 0 ETH.
- **`msg.value` IS still enforced** — if you want a call to send non-zero ETH, the sender needs a balance. That's why we use `vm.deal` / `hoax` for funders.
- **Coverage ≠ testing.** High coverage on a file just means its lines were executed (possibly indirectly through other contracts' tests), not that its behavior was specifically asserted. `PriceConverter` shows 100% coverage in this project purely because `FundMe.fund()` calls it.
