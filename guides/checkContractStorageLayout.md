# Check a contract storage layout

## Method 1

To check the storage layout of FundMe, you can do:

```bash
forge inspect FundMe storageLayout
```

or for a more detailed json output:

```bash
forge inspect FundMe storageLayout --json | jq .
```

Example output

```json
{
  "storage": [
    {
      "astId": 64,
      "contract": "src/FundMe.sol:FundMe",
      "label": "s_funders",
      "offset": 0,
      "slot": "0",
      "type": "t_array(t_address)dyn_storage"
    },
    {
      "astId": 68,
      "contract": "src/FundMe.sol:FundMe",
      "label": "s_addresssToAmountFunded",
      "offset": 0,
      "slot": "1",
      "type": "t_mapping(t_address,t_uint256)"
    }
  ],
  "types": {
    "t_address": {
      "encoding": "inplace",
      "label": "address",
      "numberOfBytes": "20"
    },
    "t_array(t_address)dyn_storage": {
      "encoding": "dynamic_array",
      "label": "address[]",
      "numberOfBytes": "32",
      "base": "t_address"
    },
    "t_mapping(t_address,t_uint256)": {
      "encoding": "mapping",
      "key": "t_address",
      "label": "mapping(address => uint256)",
      "numberOfBytes": "32",
      "value": "t_uint256"
    },
    "t_uint256": {
      "encoding": "inplace",
      "label": "uint256",
      "numberOfBytes": "32"
    }
  }
}
```

As we can see we have only 2 variables in storage, `s_funders` in slot 0 and `s_addressToAmountFunded` in slot 1.

## Method 2

First we deploy FundMe

```bash
forge script script/DeployFundMe.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Then we can check what data is in a certain storage slot. For example this returns what stored in slot 1.

```bash
cast storage 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 1
```

