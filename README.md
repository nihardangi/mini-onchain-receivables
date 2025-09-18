# Mini Onchain Receivables

This repo demonstrates a toy implementation of turning business receivables into programmable collateral. Each invoice is an ERC-721 Receivable NFT (amount, due date, issuer, payer, token uri etc). Merchants deposit NFTs into a ReceivableVault that issues them payment (Invoice amount - borrower fee) in MockUSDC. When an invoice payment is settled, the vault receives MockUSDC and shareholders can redeem pro-rata. The goal: a small prototype that maps 1:1 to Credit Coop’s core thesis (cash flows → tokenized collateral → onchain settlement).

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
