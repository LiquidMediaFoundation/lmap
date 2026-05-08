# LMAP — Deployed Contracts

A reference for the on-chain artifacts that compose the current
deployment of the LMAP protocol. All contracts are on Polygon
mainnet (chain ID 137), immutable, and verified on Polygonscan.

---

## Active reference contract

| Property | Value |
|---|---|
| Contract | `WyllohRegistryProtocolV4_1` |
| Address | `0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D` |
| Standard | ERC-1155 (one token ID per film, balances = number of copies) |
| Payment | USDC.e (`0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174`) |
| Protocol fee | 2.5% (immutable, hardcoded) |
| Deployed | 2025-09-22 |
| LMAP compatibility | LMAP 1.0 — open tier only (legacy deployment) |

This contract serves as the canonical entitlement registry under
LMAP 1.0 at the open-tier level. It does not implement certified-tier
hardware attestation; that capability is specified for inclusion in
`LMAPRegistryV5` (drafting). Existing tokens minted on V4.1 remain
fully functional and operate under LMAP 1.0 open-tier semantics.

The Solidity source is preserved verbatim at
[`contracts/legacy/WyllohRegistryProtocolV4_1.sol`](contracts/legacy/WyllohRegistryProtocolV4_1.sol)
for verification continuity. The contract name in source and bytecode
remains `WyllohRegistryProtocolV4_1` — the original deployer was the
team operating Wylloh, the first commercial implementation of LMAP.

---

## Deprecated registry versions

Earlier registry versions were deployed during the protocol's
development. They are not active and should not be integrated against.

| Version | Address | Status |
|---|---|---|
| V1 | `0x624c5C6395EB28b9952FE9ae0d87B12520b55Bfc` | Deprecated (Token #1 initialization issue) |
| V2 | `0xfBC8E2b67901B3150b7c50F9Ff0102977CcE5005` | Deprecated (replaced by V4.1 superset) |

---

## Auxiliary contracts

The following contracts were deployed alongside the primary registry
to support the reference implementation operated by Wylloh. They are
not part of the LMAP protocol surface and integrators are not
required to interact with them.

| Contract | Address | Purpose |
|---|---|---|
| `WyllohSecondaryMarket` | `0xE171E9db4f2f64d3Fc80AA6E2bdF2770Bb006EC8` | Royalty-aware secondary marketplace; companion to V4.1 registry |
| `WyllohToken` (ERC-20) | `0xaD36BE606F3c97a61E46b272979A92c33ffB04ED` | Reference-implementation utility token |
| `RoyaltyDistributor` | `0x23735B20dED41014a03a3ad1EBCb4623B8aDd52d` | Multi-recipient royalty splitter |
| `StoragePool` | `0x849760495E12529b43e1BA53da6B156ffcE8120A` | IPFS storage funding contract |

The `WyllohSecondaryMarket` source is also preserved verbatim at
[`contracts/legacy/WyllohSecondaryMarket.sol`](contracts/legacy/WyllohSecondaryMarket.sol).

---

## Network reference

- **Network:** Polygon mainnet (chain ID 137)
- **Block explorer:** [polygonscan.com](https://polygonscan.com/)
- **Public RPC examples:** `https://polygon-rpc.com`,
  `https://polygon-mainnet.public.blastapi.io`
- **Native USDC** (`0x3c499...`) is **not** the payment token
  accepted by V4.1. The contract accepts only USDC.e (bridged USDC,
  address listed above). Wallets bridging from Coinbase or other
  custodial sources must convert before purchase.

---

## Roadmap

`LMAPRegistryV5` is in development as the reference contract for
LMAP 1.0 with full open + certified tier support. V5 introduces:

- Hardware-attested per-device key wrapping (certified tier)
- ERC-4337 paymaster integration for gas abstraction
- Updateable `platformTreasury` via multi-sig + timelock
- Formalized rights-tier metadata schema with media-type extensibility
- Paired ERC-721 copyright registry (`LMAPCopyrightRegistryV1`)

V5 will be deployed under Liquid Media Foundation governance once
incorporation completes and the contracts have been audited. V4.1
remains active and continues to serve all currently-tokenized films.
