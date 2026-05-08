# LMAP — Integration Guide

A short, practical guide for developers integrating with LMAP.
For the canonical layered architecture, see
[`PROTOCOL_LAYERS.md`](./PROTOCOL_LAYERS.md).

---

## What's deployed

The V4.1 registry is the source of truth for the protocol on
Polygon mainnet:

| Item | Value |
|---|---|
| Network | Polygon mainnet (chain ID 137) |
| Registry contract | `0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D` |
| Payment token | USDC.e (`0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174`) |
| Standard | ERC-1155 (one token ID per film, balances = number of copies held) |
| Protocol fee | 2.5% (immutable, hardcoded in contract) |

Verified source code is on PolygonScan. The Solidity sources live in
[`../contracts/contracts/legacy/WyllohRegistryProtocolV4_1.sol`](../contracts/contracts/legacy/WyllohRegistryProtocolV4_1.sol).

---

## Reading from the protocol (no permission required)

Anyone can query the registry via any Polygon RPC. Example with
ethers.js:

```javascript
import { ethers } from 'ethers';

const REGISTRY = '0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D';
const ABI = [/* see contracts/contracts/legacy/WyllohRegistryProtocolV4_1.sol */];

const provider = new ethers.JsonRpcProvider('https://polygon-rpc.com');
const registry = new ethers.Contract(REGISTRY, ABI, provider);

// Read a film's metadata URI (points to IPFS-hosted JSON)
const tokenId = 1;
const uri = await registry.uri(tokenId);

// Read a wallet's balance for that film
const wallet = '0x1223...25d3';
const balance = await registry.balanceOf(wallet, tokenId);

// Read a film's price
const film = await registry.films(tokenId);
const pricePerToken = film.pricePerToken; // in USDC.e units (6 decimals)
```

---

## Writing to the protocol

**Purchases** are permissionless — any wallet with sufficient USDC.e
and MATIC can call `purchaseTokens()` after granting the registry an
allowance. The 2.5% protocol fee and royalty splits are enforced by
the contract automatically.

**Minting new films** is currently role-gated. The `FILM_CREATOR_ROLE`
is granted on a curated basis by the `ADMIN_ROLE` holder (the
founding team). This is a deliberate editorial gate during the
protocol's early life — see
[`PROTOCOL_POSITIONING.md`](./PROTOCOL_POSITIONING.md) §8 for the
posture and the path to decentralization.

To request `FILM_CREATOR_ROLE` for tokenizing a film:
contact [contact@wylloh.com](mailto:contact@wylloh.com).

---

## Decrypting content (open tier)

The IPFS-pinned content for each film is encrypted with AES-256-GCM
in a chunked format documented at
[`PROTOCOL_LAYERS.md`](./PROTOCOL_LAYERS.md) §4. A reference
implementation in TypeScript is maintained by Wylloh, the first
commercial implementation of LMAP — see the Wylloh source for the
working code.

The flow:

1. Verify the wallet holds at least one token: call `balanceOf(wallet, tokenId)`.
2. Request the encrypted master key from the storage service:
   `GET /content/download/{tokenId}?wallet={address}`. The storage
   service verifies ownership and returns:
   ```json
   {
     "cid": "Qm...",
     "encryptedMasterKey": "base64...",
     "encryption": "AES-256-GCM-chunked-v1",
     "chunkSize": 4194304,
     "contractAddress": "0x8e834c...",
     "tokenId": "1"
   }
   ```
3. Derive the decryption key for the encrypted master key:
   `SHA-256(contractAddress.toLowerCase() + ":" + tokenId + ":wylloh-v1")`
4. AES-GCM-decrypt the master key.
5. Stream the encrypted content from any IPFS gateway.
6. Decrypt each 4-MiB chunk in sequence using the master key (each
   chunk has its own IV and GCM tag).

The deterministic key-derivation step means an encrypted master key,
once received, can be decrypted forever with or without the storage
service. **This is intentional.** It is what makes the open tier
genuinely platform-independent — anyone with the public protocol docs
can write a 50-line CLI that downloads and decrypts an LMAP-tokenized film
without ever touching any Wylloh-operated server.

For studio-grade content, the certified attestation tier (Layer 5,
spec'd, not yet shipped) wraps content keys per-device using hardware
secure elements. Implementation details in
[`PROTOCOL_LAYERS.md`](./PROTOCOL_LAYERS.md) §7.

---

## Building an LMAP-compatible client

A client (web app, mobile app, TV app, etc.) needs to:

1. Read token holdings for a wallet from the registry contract
2. Optionally read additional metadata from IPFS (pointed at by
   `tokenURI()`)
3. Implement the chunked AES-256-GCM decryption flow above
4. Provide a way for users to play the resulting MP4 stream

Reference implementation: the Wylloh platform — the first commercial
implementation of LMAP — runs all of the above in production
(wylloh.com web client, storage/download API, IPFS pinning service).
The Wylloh source serves as a working example of an LMAP-compliant
client. A minimal Node.js reference implementation is also planned
for inclusion in this repository.

The protocol is open. Anyone can fork, adapt, and ship a competing
or complementary client without permission.

---

## Building an LMAP-compatible storefront

A storefront is a UI that lets users discover, purchase, and view
films registered on the protocol. The minimum:

1. Read film registry data via the registry contract
2. Implement the purchase flow (USDC.e approve + `purchaseTokens()`)
3. Provide download/playback (or defer to other clients)

Storefronts pay the same 2.5% protocol fee on sales as wylloh.com
does — there is no preferential rate. Storefronts can layer their
own commercial markup on top (discovery, curation, audience). See
[`PROTOCOL_POSITIONING.md`](./PROTOCOL_POSITIONING.md) §4 for the
peer-marketplace framing.

---

## Best practices

- **Verify contract addresses** before sending transactions. The
  V4.1 registry is `0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D` on
  Polygon mainnet (chain ID 137).
- **Use a public RPC** for reads (multiple are available; rotate to
  avoid rate limits). For writes, users supply their own RPC via
  their wallet.
- **Handle the USDC.e approval flow** explicitly. Polygon's USDC.e
  is `0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174`. Native USDC
  (`0x3c499...`) is *not* the contract the V4.1 registry accepts; users
  bridging from Coinbase must convert.
- **Do not assume any storage service is privileged.** The protocol
  is designed so that any party can run a storage/pinning service
  that delivers the same content. Code defensively against the
  Wylloh-operated service being unreachable.
- **Test on mainnet with small amounts before large operations.**
  There is no LMAP testnet today; Polygon's Mumbai testnet was
  deprecated by Polygon in 2024.

---

## Support

- Protocol questions: open an issue at
  [github.com/LiquidMediaFoundation/lmap](https://github.com/LiquidMediaFoundation/lmap)
- Tokenization requests / partnership: [contact@wylloh.com](mailto:contact@wylloh.com)
- Public protocol documentation: [`PROTOCOL_LAYERS.md`](./PROTOCOL_LAYERS.md)
