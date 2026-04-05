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

As we can see we have only 2 variables in storage, `s_funders` and `s_addressToAmountFunded`.