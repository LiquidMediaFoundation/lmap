# LMAP — Layered Architecture

> The canonical engineering reference for how LMAP
> decomposes. Each layer is independently specifiable, testable, and
> (where applicable) replaceable. Conflating layers — particularly
> the entitlement layer with the cryptographic layer — is how
> comparable projects have failed.
>
> **Audience:** developers building on the protocol, hardware
> integrators, security auditors, technical partners, future
> contributors.
>
> **Status:** Living document. The architecture is established; some
> layers are shipped, some are specified, some are future work. Status
> is tracked per-layer in §1.
>
> **Companion documents:**
> - `docs/PROTOCOL_POSITIONING.md` — the strategic and philosophical posture
> - `docs/seed-one/ARCHITECTURE.md` — what the reference Seed *does*
> - `docs/seed-one/INDUSTRIAL_DESIGN.md` — what the reference Seed *is*
> - `docs/seed-one/ORIGIN_SPEC.md` — *how to actually build* the reference Seed

---

## 1. Overview

LMAP is decomposed into eight layers. Each layer has a
defined responsibility, a published interface to the layers above and
below it, and an implementation status. Different parties can build
different layers as long as the interfaces are honored.

| # | Layer | Responsibility | Status |
|---|---|---|---|
| 0 | Trust Anchors | Cryptographic primitives; hardware roots; wallet identity; contract immutability | Partial |
| 1 | Storage | Content distribution substrate (IPFS, manifests) | Shipped (open tier) |
| 2 | Cryptography | Encryption, key hierarchy, dispersal, watermarking | Shipped (open tier); spec'd (certified tier) |
| 3 | Entitlement | Smart contracts: distribution + copyright registries, royalties, rights tiers | Shipped (V4.1 distribution); spec'd (V5 copyright) |
| 4 | Network | Peer discovery, shard request/response, LAN streaming | Future (V2 Seed architecture) |
| 5 | Attestation | Open tier / certified tier hardware attestation | Spec'd; not yet implemented |
| 6 | Application | Storefronts, library UI, playback clients, integrator tooling | Shipped (web client); future (TV/mobile) |
| 7 | Governance | Foundation structure; federated certification; protocol governance | Future |

**Definition of layer status:**
- *Shipped*: code is in the repo, deployed to mainnet (where applicable), used in production
- *Spec'd*: design is specified in this or a companion doc but not yet implemented
- *Future*: scope is identified but neither specified nor implemented; deliberate placeholder

**Definition of "open tier" vs "certified tier"** (foreshadowing §6
on Attestation): the protocol supports two distinct trust modes.
*Open tier* runs on any compliant Seed implementation, with permissive
content (public domain, indie, Creative Commons, opt-in creators).
*Certified tier* requires hardware attestation from an LMAP-trusted
certification authority and gates studio-grade content. Both tiers
run the same layered protocol; the gating is narrow and lives at
Layer 5.

---

## 2. Layer 0 — Trust Anchors

The cryptographic primitives everything above depends on.

**Components:**

- **Wallet identity** (shipped). User identity is rooted in
  EVM-compatible wallets. ECDSA secp256k1 keypairs control token
  ownership and downstream entitlement. The wallet is never held by
  Seed hardware; phone-based wallet (MetaMask, Rainbow, Coinbase
  Wallet, any WalletConnect-compatible) signs on behalf of the user.
- **Smart contract immutability** (shipped). Deployed entitlement
  logic on Polygon V4.1 cannot be retroactively modified. Future
  upgradeability uses deliberate proxy patterns with multisig
  governance, never unilateral admin keys.
- **Hardware roots of trust** (spec'd, not yet implemented). Certified
  Seeds will carry secure elements with non-extractable key custody
  and remote-attestation capability. Reference candidates:
  - **NXP SE050** — mature, well-tooled, $5-8/unit, supports remote
    attestation
  - **Microchip ATECC608B** — lower cost, simpler attestation
  - **ARM TrustZone** — built into the SoC of higher-end SBCs (Pi 5
    has it); TEE-based rather than discrete secure element
  - **TPM 2.0** — an alternative or supplement; commonly available
    on modern SBCs

  The reference Seed (`docs/seed-one/ORIGIN_SPEC.md` §5.2) targets
  ARM TrustZone + a discrete secure element on the custom carrier PCB.

**What this layer guarantees:**
- A wallet's signature is unforgeable except by holding its private key
- A deployed contract's bytecode cannot change
- A certified Seed's identity and firmware integrity are
  cryptographically verifiable to a remote party (once Layer 5 ships)

**Interfaces above:**
- Layers 2 and 3 read wallet identity and contract state via standard
  EVM/RPC calls
- Layer 5 issues attestation challenges to certified Seed secure
  elements; receives signed reports

---

## 3. Layer 1 — Storage

The substrate by which content (always encrypted) is distributed
across the network.

**Components:**

- **IPFS-addressed ciphertext** (shipped). Encrypted film chunks are
  pinned to IPFS by their content-addressed CID. Anyone running an
  IPFS gateway or node can fetch the bytes; only entitled parties can
  decrypt them.
- **Content manifests** (shipped). A token's `metadataURI` points to
  an IPFS-hosted JSON manifest containing: poster image CID,
  encrypted-film-chunks CID, encryption metadata (chunk size, IV
  scheme, version tag), rights tier definitions.
- **Pinning policy** (shipped, partial). Wylloh's storage service
  pins all registered film CIDs by default. As the Seed network
  grows (Layer 4), pinning becomes distributed and self-strengthening
  per the edge-CDN thesis (`docs/drafts/EDGE_CDN_THESIS.md`).
- **Threshold dispersal of shards** (spec'd, not implemented). Future
  enhancement: ciphertext sharded via Reed-Solomon erasure coding
  across Seeds, requiring quorum reconstruction. Provides resilience
  and modestly raises extraction cost. See §4.5 for the load-bearing
  scope of this claim.

**What this layer guarantees:**
- A given CID resolves to a stable byte-identical encrypted asset
- Anyone with the CID can fetch the ciphertext from any IPFS gateway
- Wylloh's central pinning is replicable; the protocol does not
  depend on Wylloh-operated storage

**Interfaces above:**
- Layer 2 fetches ciphertext by CID and applies decryption
- Layer 3 stores `metadataURI` (pointing to manifest CID) on-chain
- Layer 6 (storefronts) reads manifests to display title information

---

## 4. Layer 2 — Cryptography

Encryption, key hierarchy, content-key custody, and watermarking. The
load-bearing security layer.

### 4.1 Symmetric encryption (shipped, open tier)

- **AES-256-GCM** for content at rest and in transit
- **Chunked format** (open tier v1): `[Len(4b BE)][IV(12b)][Ciphertext+Tag(16b)]`
  per 4 MiB chunk. Self-authenticating per chunk; supports streaming
  decryption with constant memory.
- **Per-title content keys** derived via HKDF with domain separation;
  no key reuse across titles.

Specified in `client-v2/src/services/encryption.ts` and ported to
Seed firmware. Spec is open; any compliant client can implement.

### 4.2 Open-tier key derivation (shipped)

- Master content key derivable from public on-chain data:
  `SHA-256(contractAddress.toLowerCase() + ":" + tokenId + ":wylloh-v1")`
- Encrypted master key stored in API response, returned after the
  storage service verifies wallet ownership via on-chain
  `balanceOf()` check
- Once a holder has the encrypted master key, they can decrypt
  forever, with or without the API. **This is intentional.** It is
  what makes the open tier genuinely platform-independent — a
  developer with the protocol docs can write a 50-line CLI that
  downloads and decrypts an LMAP-tokenized film without ever touching any
  Wylloh-operated server.

### 4.3 Certified-tier key wrapping (spec'd, not implemented)

For studio-licensed content and any title where forensic-grade
attribution is required:

- **Per-device wrapping.** Content keys are wrapped to each certified
  Seed's public key, derived from its secure element. Each Seed gets
  a uniquely-wrapped instance of the key.
- **Unwrap inside secure element.** Wrapped keys are decrypted only
  inside the Seed's secure element; the unwrapped key never appears
  in main memory or on disk.
- **Issuance gate.** Wrapped keys are issued by certification
  authorities only after the Seed presents a valid attestation
  report (Layer 5).
- **Revocation.** Compromised certified devices can be added to a
  revocation registry (Layer 3); subsequent key issuance refuses
  the revoked device's attestation.

### 4.4 Watermarking (spec'd; provider TBD)

- **Open tier:** server-side watermarking before download fulfillment.
  The storage API embeds a per-wallet watermark when serving the
  encrypted master key. Simple to implement; works for the trust
  model where the open-tier API is part of the trust boundary.
- **Certified tier:** Seed-side watermarking inside the secure
  element at decryption time. Each playback inserts a per-wallet
  forensic watermark before the plaintext leaves the secure
  perimeter. Robust against transcoding requires commercial
  watermarking IP — engagement with Verimatrix, NAGRA, or Irdeto is
  the path to studio-grade implementation.
- **Insertion-point invariant:** wherever watermarking happens, the
  wallet identity is bound to the content before any plaintext bit
  reaches a copy-able surface.

### 4.5 The "security scales with N" thesis — what's actually claimed

This thesis appears in technical communications and deserves precise
articulation.

**Two distinct sub-claims, with different defensibility:**

1. **Per-device key wrapping (certified tier) — strong claim.**
   Compromising one certified Seed yields *that Seed's local content
   only*. The network's aggregate exposure does not grow with network
   size, because each certified device is its own isolated vault.
   This is the load-bearing security claim, and it scales positively
   with N.

2. **Threshold dispersal of ciphertext (storage layer) — modest
   claim.** Sharding ciphertext across Seeds raises the per-shard
   extraction cost. An attacker compromising one Seed gets 1/n of
   the ciphertext; reconstructing the asset requires reaching the
   reconstruction threshold k. This is real but bounded — a
   motivated attacker can target enough Seeds to reach k. The
   combinatorial-cost argument applies but does not produce
   asymptotic security.

The honest summary: *per-device key wrapping at the certified tier
provides security that does not degrade with scale; threshold
dispersal provides resilience and modestly raises extraction cost.*
Both are valuable; only the first is the load-bearing claim.

The open tier explicitly accepts permeability. See
`docs/PROTOCOL_POSITIONING.md` §2 for the philosophical commitment
that frames the open tier's design.

**What this layer cannot do** (acknowledged honestly):
- Eliminate the analog hole. Camera-pointed-at-screen capture remains
  possible. Watermarking is the only mitigation; watermark robustness
  is an ongoing arms race.
- Provide bit-perfect copy protection. No system does. The protocol
  provides *cryptographically aligned* and *economically aligned*
  protection.

---

## 5. Layer 3 — Entitlement (Smart Contracts)

The on-chain truth of who owns what. All contracts are deployed to
Polygon mainnet, immutable, and verified.

**Components:**

- **ERC-1155 distribution registry** (shipped, V4.1):
  `WyllohRegistryProtocolV4_1.sol` at
  `0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D`. Tracks tokenized
  films, balances per wallet, total supply, royalty rate, the
  hardcoded USDC.e payment token, and the role-gated minting
  function (see §11).
- **Stacking thresholds for rights tiers** (shipped). Per-token
  metadata defines stacking thresholds for personal viewing, small
  venue, theatrical exhibition. Enforcement is on-chain.
- **Royalty splits** (shipped). 2.5% protocol fee hardcoded;
  filmmaker receives 97.5%. Splits payable on every primary and
  secondary-market transaction routed through the protocol contract.
- **ERC-721 copyright registry** (spec'd, not deployed). Future V5
  contract for representing copyright ownership (ERC-721) separately
  from distribution rights (ERC-1155). Mirrors how rights actually
  work in entertainment law: copyright is owned, distribution rights
  are licensed. Required for full studio engagement; not blocking
  for indie launch.
- **Staking contracts** (spec'd, not deployed). For commercial
  exhibition windows where time-bounded rights are staked rather
  than transferred.
- **Revocation registry** (spec'd, not deployed). For invalidating
  attestation credentials of compromised certified Seeds (Layer 5).

**Permissioning today (current V4.1 reality):**

- `FILM_CREATOR_ROLE` gate on the tokenization function. Founding
  team holds `ADMIN_ROLE` and grants creator rights on a curated basis.
- This is deliberate, not a rollout artifact. It is the small
  editorial gate that prevents the protocol from becoming an AI-slop
  marketplace before a decentralized curation mechanism is designed.
- Path to decentralization (V5+): replace role-based minting with
  staking-backed minting, reputation-weighted onboarding, or a
  multi-layer filtration design. See `docs/PROTOCOL_POSITIONING.md`
  §7 for the curation framing.

**Interfaces above:**
- Layer 4 (network) reads token balances to gate Seed shard
  serving
- Layer 5 (attestation) reads revocation registry
- Layer 6 (application) reads token data for storefront and library
  display

**Interfaces below:**
- Layer 0 (trust anchors) provides wallet keys for all signatures

---

## 6. Layer 4 — Network

Peer-to-peer protocol between Seeds, plus LAN streaming to playback
apps. Future work — depends on the V2 Seed reference implementation
shipping.

**Components (all spec'd, not yet implemented):**

- **Seed peer discovery and gossip protocol.** Seeds announce their
  presence on a public registry (DHT-based) for shard exchange.
- **Shard request/response with QoS hints.** Seeds request specific
  CIDs from the network; nearby Seeds with the requested CIDs serve
  them. QoS hints prefer same-region peers and reciprocating peers.
- **Proof-of-storage challenges.** Seeds verifying that their peers
  actually hold the shards they claim, via cryptographic challenges
  over random byte ranges.
- **Reputation scoring for shard providers.** Seeds that reliably
  serve high-quality shards earn higher discovery priority. Seeds
  that serve corrupted or partial shards are deprioritized.

**LAN streaming protocol** (spec'd):

- **HLS over HTTPS** as the primary client-Seed protocol
- mDNS / Bonjour for Seed discovery on the LAN
- TLS with self-signed cert pinned at pairing time
- Roku, Apple TV, iOS/iPadOS, and web browsers all natively support
  HLS
- DLNA explicitly not supported in v1 (legacy baggage outweighs
  compatibility benefit)
- A LMAP-native protocol is a future option for higher-fidelity or
  lower-latency requirements but not necessary for v1

**What this layer guarantees:**
- Seeds can find content available on the network without central
  coordination
- A Seed serves content to client apps over the LAN as standard HLS
- Compromised peers can be deprioritized without protocol-level
  coordination

**Interfaces above:**
- Layer 5 (attestation) gates which Seeds can serve certified-tier
  content
- Layer 6 (application) consumes the LAN streaming protocol

**Interfaces below:**
- Layer 1 (storage) is the source of bytes
- Layer 2 (cryptography) wraps bytes in transit and at rest

---

## 7. Layer 5 — Attestation (the keystone)

The architectural answer to the open-protocol-vs-studio-trust tension.
Two tiers, both running the same layered protocol underneath; the
gating is narrow and lives at this layer.

### 7.1 Open tier

Any Seed implementation that follows the spec serves content licensed
under permissive terms:
- Public domain
- Creative Commons
- Indie creators who opt their content into open-tier distribution

Permissive encryption (Layer 2 §4.2) is sufficient. No hardware
attestation required. Anyone can implement an open-tier Seed and
serve open-tier content. Third-party clients (community VLC plugin,
custom mobile app, etc.) are welcome.

### 7.2 Certified tier

Seeds carrying hardware attestations from a federated certification
authority. Required for studio-licensed content. Revocable. Audited.

**Certification credential, technically:**
- Each certified Seed holds a per-device keypair generated inside
  its secure element (Layer 0)
- The certification authority signs a credential binding the device
  public key to a manifest of approved firmware measurements
- A content-key issuance request includes a fresh attestation report
  signed by the secure element, containing current firmware
  measurements
- The CA verifies the report against the device's credential and
  issues a wrapped content key (Layer 2 §4.3) only on a clean match

**Reference attestation stack** for the Origin reference Seed:
- Discrete secure element on the custom carrier PCB (NXP SE050 or
  equivalent)
- ARM TrustZone (Pi 5 supports it) for measured-boot verification
- Per-device attestation key generated at first boot, never extractable

**Certification authority structure:**
- Foundation-only at v1 launch (single CA — Liquid Media Foundation)
- Federation milestone: at a defined network size or maturity
  threshold, the CA opens to additional signers (independent
  auditors, integrator-channel certifiers, academic partners)
- Federation is a *visible commitment*, not an indefinite
  promise — a public sunset milestone for the LMF-only
  phase

### 7.3 Both tiers run the same protocol

A user's library may contain both open-tier and certified-tier
titles. The client app sees a unified library; the only difference is
that certified-tier titles will refuse to play on a non-certified
Seed.

Storefronts can sell into either tier. The protocol does not
discriminate at the application layer — only at content-key issuance
(Layer 2) and Seed eligibility (Layer 5).

This is the architectural mechanism that lets LMAP stay genuinely
open (anyone can implement, anyone can sell, anyone can build clients)
while preserving a credible path to studio-licensed content (where
contractual hardware attestation requirements live).

---

## 8. Layer 6 — Application

Everything end users and operators interact with. The protocol is
permissionless at this layer: anyone can implement.

**Components (current and planned):**

- **Storefronts.** Permissionless. Any party can sell tokens for
  content they hold rights to. Wylloh.com is one storefront; others
  may emerge. All storefronts pay the same 2.5% protocol fee.
- **Library aggregation UI.** Canonical cross-storefront view of a
  user's holdings. The library is the union of all tokens the user's
  wallet holds, regardless of which storefront sold them.
- **Playback clients** (per `docs/seed-one/ARCHITECTURE.md` V2
  architecture):
  - Roku (priority 1)
  - Apple TV (priority 2)
  - iOS / iPadOS (priority 3)
  - Web (already shipped at wylloh.com)
- **Storefront SDK.** Future. Lets third parties build LMAP-
  compatible storefronts without re-implementing protocol primitives.
- **Integrator deployment tooling** (future). Provisioning,
  attestation enrollment, multi-room configuration, residential AV
  integration (Crestron, Control4, Savant) — relevant to CEDIA-channel
  deployment of certified Seeds.

**What this layer doesn't dictate:** UI/UX choices, branding,
business model, monetization. Those are commercial choices made by
each application implementer.

---

## 9. Layer 7 — Governance

How the protocol evolves over time. Future work.

**Components (all future):**

- **Foundation entity.** Holds the protocol IP, governs upgrades,
  stewards the certification authority, and operates as the
  protocol-neutral standards body. Legal structure under evaluation
  (Cayman Foundation Company is the leading candidate; alternatives
  include Swiss Stiftung and US 501(c)(3)).
- **Federated certification.** Layer 5 attestation authorities
  beyond the Foundation, federated under a public governance process.
- **Token holder voting (per title).** ERC-1155 holders of a given
  film vote on per-title decisions: royalty split adjustments,
  rights tier amendments, withdrawal of distribution rights. Only
  applies to per-title decisions; protocol-level governance lives
  in the Foundation.
- **Multisig stewardship of upgradeable components.** During the
  bootstrap phase, upgradeable contracts are governed by a multisig
  of identifiable stewards. Public sunset milestones commit the
  Foundation to transitioning these to broader governance.

**Current state:** The Liquid Media Foundation is in formation —
incorporation as a 501(c)(6) trade association is a funded milestone
of the upcoming raise. Until incorporation completes, Wylloh's
founding team operates in a stewardship role. This is the current
bootstrap reality; the path to formal foundation governance is a
documented 3-5 year arc.

---

## 10. Cross-layer concerns

A few properties span multiple layers and deserve explicit treatment.

### 10.1 Wallet identity is shared infrastructure

Wallet identity (Layer 0) flows through every layer above it:
- Layer 3 reads wallet for entitlement
- Layer 4 reads wallet to gate Seed-to-Seed shard exchange (potentially)
- Layer 5 ties certified-tier content key wrapping to user's wallet
- Layer 6 displays library based on wallet's token holdings

This is intentional. The wallet is the single source of identity
across the protocol. The wallet is never held by Seed hardware; phone-
based wallets sign on the user's behalf.

### 10.2 Open tier vs. certified tier separation runs through every layer

| Layer | Open tier | Certified tier |
|---|---|---|
| 0 | Wallet only | Wallet + secure-element-attested device |
| 1 | Standard IPFS pinning | Same, plus per-device wrapped manifest |
| 2 | Public-data-derived keys (permeable by design) | Per-device-wrapped keys, hardware-bound (per-N security) |
| 3 | Same registries | Same registries plus revocation list |
| 4 | Any Seed can serve | Only certified Seeds can serve |
| 5 | No attestation required | Hardware attestation required |
| 6 | Any client app | LMAP-certified clients (or compatible ones) |
| 7 | Foundation governs spec | Foundation + CAs govern certification |

A useful frame: *the open tier is the protocol's permissionless
default; the certified tier is the optional add-on that enables
studio relationships without compromising the default.*

### 10.3 Layer ownership is not vertical

The protocol does not mandate that one party implement all eight
layers. Different parties can build different layers and compose them:
- A storefront (Layer 6) only needs to read entitlement (Layer 3)
- A Seed manufacturer only needs to implement Layers 1, 2, 4, and
  optionally 5
- An academic auditor of the certification authority only needs to
  understand Layer 5 and the cryptographic claims of Layer 2

Each layer should have a named owner, a written spec, and a test
harness independent of the layer above. This is the discipline that
prevents the layered abstraction from collapsing into a monolith.

---

## 11. Quick reference layer map

```
Layer 7 — Governance      ↑ (foundation, federation, voting)
Layer 6 — Application     ↑ (storefronts, library UI, playback apps, integrator tools)
Layer 5 — Attestation     ↑ (open tier / certified tier split)
Layer 4 — Network         ↑ (Seed peer protocol, LAN streaming via HLS+mDNS)
Layer 3 — Entitlement     ↑ (ERC-1155 distribution, ERC-721 copyright, royalties, staking)
Layer 2 — Cryptography    ↑ (AES-256-GCM, two-tier keys, threshold dispersal, watermarking)
Layer 1 — Storage         ↑ (IPFS, manifests, future shard dispersal)
Layer 0 — Trust Anchors   ↑ (secure element, wallet keys, contract immutability)
```

---

## 12. Open architectural questions (next 30-90 days)

Decisions worth converging on:

1. **Secure element family for the reference Seed.** Recommendation:
   NXP SE050. Mature, attestable, $5-8/unit, well-supported tooling.
2. **LAN streaming protocol.** Recommendation: HLS over HTTPS with
   mDNS discovery. No DLNA in v1.
3. **Foundation legal structure.** Recommendation: Cayman Foundation
   Company. Less expensive than Swiss Stiftung, well-established for
   crypto-adjacent protocols.
4. **Initial certification authority.** Recommendation:
   Foundation-only at v1, with a public commitment to federate at a
   defined milestone.
5. **Watermarking provider engagement.** Initiate conversations with
   Verimatrix, NAGRA, Irdeto. Not blocking for v1; required for
   studio engagement.
6. **Threshold dispersal scheme.** Reed-Solomon erasure coding over
   Shamir's secret sharing for ciphertext shards. Implementation
   complexity vs. resilience benefit needs design tradeoff analysis.
7. **DKG ceremony for early threshold key generation.** Centralized
   at v1 (single trusted setup) vs. distributed from day one (more
   complex, more credible).

---

*Last updated: 2026-04-28. Living document. Expect refinement as
each layer matures from spec to implementation.*
