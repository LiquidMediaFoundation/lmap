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
| 2 | Cryptography | Encryption, key hierarchy, dispersal, watermarking | Shipped (open tier); spec'd (compliant tier) |
| 3 | Entitlement | Smart contracts: distribution + copyright registries, royalties, rights tiers | Shipped (V4.1 distribution); spec'd (V6 copyright) |
| 4 | Network | Peer discovery, shard request/response, LAN streaming | Partial: reference daemon serves open-tier LAN (HTTP byte-range + mDNS) today; peer protocol + HLS transport spec'd/future |
| 5 | Attestation | Compliant-tier hardware attestation (the open tier requires none) | Spec'd; not yet implemented |
| 6 | Application | Storefronts, library UI, playback clients, integrator tooling | Shipped (web client); future (TV/mobile) |
| 7 | Governance | Foundation structure; federated certification; protocol governance | Future |

**Definition of layer status:**
- *Shipped*: code is in the repo, deployed to mainnet (where applicable), used in production
- *Spec'd*: design is specified in this or a companion doc but not yet implemented
- *Future*: scope is identified but neither specified nor implemented; deliberate placeholder

**Definition of "open tier" vs "compliant tier"** (foreshadowing §6
on Attestation): the protocol supports two distinct trust modes.
*Open tier* runs on any conformant Seed implementation, with permissive
content (public domain, indie, Creative Commons, opt-in creators).
*Compliant tier* requires hardware attestation from an LMAP-trusted
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
- **Hardware roots of trust** (spec'd, not yet implemented). Compliant
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
- A compliant Seed's identity and firmware integrity are
  cryptographically verifiable to a remote party (once Layer 5 ships)

**Interfaces above:**
- Layers 2 and 3 read wallet identity and contract state via standard
  EVM/RPC calls
- Layer 5 issues attestation challenges to compliant Seed secure
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
- **Per-title master keys are independently random** (no catalog-wide
  master); per-asset and per-rendition subkeys are HKDF-derived from
  the title master with domain separation. No key reuse across titles
  or assets. Multi-tier titles key each rights tier independently,
  released under that tier's access condition (`balanceOf ≥
  threshold_T`), so a lower tier never derives a higher one.

Specified in `client-v2/src/services/encryption.ts` and ported to
Seed firmware. Spec is open; any conformant client can implement.

### 4.2 Open-tier key release (v2.4)

**Legacy deterministic key-derivation construction (retired as a
production model; scoped to public-domain demonstration content):**
the V4.1 deployment derives a master content key from public
on-chain data using
`SHA-256(contractAddress.toLowerCase() + ":" + tokenId + ":wylloh-v1")`.
The encrypted master key was returned by a storage API after an
on-chain `balanceOf()` check, but once any holder received the
encrypted master key, decryption proceeded entirely from public
inputs. This construction was originally articulated as platform
independence. It is appropriate for *demonstrating the protocol's
mechanics on public-domain content* — the role it served for the
V4.1 deployment of *The Cocoanuts* — and is not appropriate for
content of commercial value, because any party with the public
chain data can derive the wrapping key. The V4.1 deployment
continues to serve its existing public-domain tokens under this
construction.

**Production access control (v2.6): native threshold-mediated key
release.** Master keys are random (32 bytes) at content preparation;
the encrypted master key is wrapped to a Distributed Key Generation
public key held by a threshold network; release is gated by an Access
Control Condition evaluated against current chain state (typically
`balanceOf(:userAddress, :tokenId) > 0`). No party can release a key
to a wallet that does not currently satisfy the condition; transfers
flow access to the new holder against current chain state. The
threshold-release primitive is **substrate-independent** and the
access layer is **native**: the Foundation's federated framework
(Layer 5) operates and progressively decentralizes it, and the layer
must not be rentable from, or revocable by, any party outside that
framework. A mature external threshold network may serve only as a
swappable interim bridge behind a stable interface, never as a
dependency the protocol's guarantees rest on. This mechanism serves
**open-tier** (no-hardware) content — including *paid* indie titles
that need no endpoint protection; **premium / endpoint-protection-required**
titles, and the flagship Seed-gated launch, use the **compliant
tier's** per-device wrapping and binding model (§4.3). ("Commercial"
= sold for money and spans both tiers; it is not a synonym for the
compliant tier — whitepaper §7.)

For the canonical specification of both, see whitepaper v2.6 §7.

### 4.3 Compliant-tier key wrapping and binding (the day-1 premium mechanism)

For **premium / endpoint-protection-required** titles — the tier the
flagship Seed-gated launch is built on — and any content where endpoint
protection or forensic-grade attribution is required:

- **Per-device wrapping.** Content keys are wrapped to each compliant
  Seed's public key, derived from its secure element. Each Seed gets
  a uniquely-wrapped instance of the key.
- **Unwrap inside secure element.** Wrapped keys are decrypted only
  inside the Seed's secure element; the unwrapped key never appears
  in main memory or on disk.
- **Issuance gate.** Wrapped keys are issued by the **key issuer**
  (§glossary) only after the Seed presents a valid attestation report
  that the **credential issuer** has certified (Layer 5).
- **Revocation.** Compromised compliant devices can be added to a
  revocation registry (Layer 3); subsequent key issuance refuses
  the revoked device's attestation.
- **Binding — one active copy.** A wrapped key is bound to one secure
  element at a time. The entitling token is a *fungible* ERC-1155
  unit, so binding is a **count per `(wallet, tokenId)`** — `boundCount`,
  under `boundCount ≤ balance` (transferable = `balance − boundCount`) —
  *not* a per-token flag. The count lives in an **on-chain,
  world-readable binding registry from launch** — a separate accounting
  contract. **Writes follow a blinded-commitment rule.** A **bind**
  requires a valid, non-revoked compliant-device credential *and* the
  owner's wallet signature, records a **blinded commitment**
  `C = hash(secret)` (never device identity), and the contract enforces
  `boundCount ≤ balance` against `balanceOf`. A **release** is
  authorized by *opening* that commitment (revealing the secret),
  proving the writer bound this unit — so it needs no wallet signature
  and exposes no device identity, and the **device self-audit** can
  release a sold copy on its own (the departed wallet cannot co-sign).
  The on-chain check is an enrolled device-key signature plus
  non-revocation (not a fresh attestation report); the reference secure
  elements sign P-256, verifiable cheaply via Polygon's **RIP-7212**
  precompile — an implementation item. No central issuer writes the
  flag — the attested fleet does, from launch. The one
  wallet-authoritative write is **recovery**: after the report window
  the owner force-releases their own `(wallet, tokenId)` units directly
  (owner-enumerated; no device→title map). A single party can *delay* a
  release by revoking a device (pushing the holder onto recovery), not
  *withhold* it — recovery is wallet-authoritative. The key issuer
  (§glossary) is confined to *key wrapping*, separate from flag state.
  The token stays a plain ERC-1155 throughout, and the registry is a
  distinct contract that never touches transfers.
  **The registry informs; it never gates:** the token transfers freely
  on-chain at all times and no party — issuer included — can block the
  exchange of an owned token. A bound copy plays offline indefinitely
  (recorded, never re-verified). To trade without residual the holder
  *releases* (opens the commitment; `boundCount` decrements); an escrow
  contract can settle a sale atomically against the registry so a buyer
  never acquires a bound unit, and a platform may list only released
  units or warn on the rest — coordination built on the flag, not
  enforced by fiat. A lost/sold/broken device is recovered by the
  owner-enumerated report + 30-day release (no heartbeat or beacon);
  the device verifiably erases recovered titles as a precondition of
  its next capability-acquiring transaction, and a refusing device is
  revoked. Playback of already-bound content fails open. This yields
  one-copy-per-token scarcity with no continuous ownership check —
  enforcement only at bind and release. **Two residuals** remain, both
  physical-media-tier and (for attribution) conditional on a measured
  watermark scheme (§4.4): a compromised device that opens `released`
  while retaining its copy, and a raw out-of-escrow transfer that
  momentarily leaves `boundCount > balance`.

### 4.4 Watermarking (scheme and provider open — dependent claims are conditional)

Forensic watermarking is the designated backstop for several residual
claims elsewhere (the compliant tier's post-decryption leak; the
recovery residual, §4.3). Its locus differs by tier and its robustness
is not yet established, so **claims that lean on watermark attribution
("bounded", "traceable") are conditional on integrating a scheme with
measured robustness — not asserted as already delivered.**

- **Compliant tier:** watermarking inserts in the **protected media
  path** (the TEE media pipeline, whitepaper §7.2), at decode time,
  before any frame reaches an output — *not* in the discrete secure
  element, which holds keys and cannot bus or decode video. Each
  playback binds the holder's identity to the frames within the sealed
  perimeter. Transcoding-robust marking requires commercial IP
  (Verimatrix, NAGRA, Irdeto); until such a scheme is integrated and
  independently measured, the attribution claim is *conditional*.
- **Open tier:** per-user marking collides with content addressing —
  per-wallet bytes mean per-wallet CIDs, which breaks Layer 1's
  byte-identical-CID guarantee and the shared-swarm distribution
  thesis, and reintroduces a per-download central serving path;
  client-side insertion is unenforceable in a tier that welcomes
  arbitrary third-party clients. The open tier therefore does **not**
  rest its defense on watermarking: it accepts playback-edge
  permeability by design (§4.5, whitepaper §7.4) and relies on social
  incentive, easy legitimate purchase, and creator alignment. A
  content-addressing-compatible open-tier mark (e.g. segment-level
  side-channel marks) is an open research item, not a v1 dependency.
- **Insertion-point invariant (where marking is used):** the holder's
  identity is bound to the content before any plaintext bit reaches a
  copy-able surface.

### 4.5 The "security scales with N" thesis — what's actually claimed

This thesis appears in technical communications and deserves precise
articulation.

**Two distinct sub-claims, with different defensibility:**

1. **Per-device key wrapping (compliant tier) — strong claim.**
   Compromising one compliant Seed yields *that Seed's local content
   only* — a constant per-compromise bound, with no master secret
   whose theft unlocks the catalog. Stated precisely: the
   *per-compromise yield* does not grow with network size; the
   probability that *some* holder of a given title is compromised does
   grow with holder count, and that residual is bounded by watermark
   attribution and revocation, not by cryptography.
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

The honest summary: *per-device key wrapping at the compliant tier
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
- **Royalty splits** (shipped for V4.1; extended in V5). The **2.5%
  protocol fee is the constant** — hardcoded, identical on every sale
  through any marketplace. In the shipped **V4.1 two-way** split the
  author receives the whole remaining 97.5%. **V5** adds a **variable
  publisher fee (0–25%), set by the minting platform at mint**
  (whitepaper §10.1): it comes *out of* the 97.5%, so the author
  receives the remainder (72.5%–97.5%), and a self-minting author keeps
  the full 97.5%. Either way the protocol's cut stays a flat 2.5%; the
  platform's cut is the variable. Splits are payable on every primary
  and secondary-market transaction routed through the protocol
  contract.
- **ERC-721 copyright registry** (spec'd, not deployed). Future **V6**
  contract for representing copyright ownership (ERC-721) separately
  from distribution rights (ERC-1155). Mirrors how rights actually
  work in entertainment law: copyright is owned, distribution rights
  are licensed. Required for full studio engagement; not blocking
  for indie launch.
- **Binding registry** (spec'd; a launch deliverable — §4.3). A
  separate, world-readable accounting contract holding `boundCount` per
  `(wallet, tokenId)` and blinded binding commitments; written by the
  attested fleet, enforcing `boundCount ≤ balance` against the token's
  `balanceOf`; never touches token transfers. The newest and most novel
  Layer-3 contract, and the one the compliant-tier buyer guarantee
  reads against.
- **Escrow / binding-aware settlement** (spec'd; a launch deliverable).
  Settles a sale atomically against the registry's released state so a
  buyer never pays for a still-bound unit — whether this is a V5
  marketplace function or a standalone contract is an open interface
  question (§12). *(The V5 reference contract's feature list predates
  the binding model and does not yet enumerate the registry read or the
  escrow path; both are launch-deliverable interfaces still to be
  specified, alongside the attestation flow.)*
- **Staking contracts** (spec'd, not deployed). For commercial
  exhibition windows where time-bounded rights are staked rather
  than transferred (the exhibition regime — mechanism TBD with the DCI
  community, device doc §2.1).
- **Revocation registry** (spec'd, not deployed). For invalidating
  attestation credentials of compromised compliant Seeds (Layer 5);
  also the recognized-roots / revocation source the binding registry
  checks device-key writes against (§4.3).

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
apps. Mixed status: the **Seed-to-Seed peer protocol** is future work
(depends on the V2 Seed reference implementation), while **open-tier
LAN streaming already ships** in the reference daemon — see the
transport note below.

**Peer-protocol components (spec'd, not yet implemented):**

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

**LAN streaming protocol** (spec'd, open tier). Compliant-tier content
plays on the sealed direct player itself (Layer 5); LAN streaming to
companion apps and personal devices is an **open-tier** capability
that trades endpoint protection for reach:

- **Transport, shipped vs. target.** The reference daemon today serves
  open-tier LAN over **HTTP byte-range** with mDNS discovery — the
  demonstrated, canonical reference behavior (whitepaper §9). **HLS over
  HTTPS** is the *specified target* transport for broad companion-client
  support (Roku, Apple TV, iOS/iPadOS, browsers all natively support
  HLS); it is not yet implemented in the reference. Until it is, HTTP
  byte-range is the normative shipped behavior and HLS is the roadmap
  target — an implementer should build to byte-range today and track
  the HLS transition.
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
- **Carriage is open for both tiers.** *Any* device — attested or
  not — can hold, pin, and serve the encrypted bytes of open- *and*
  compliant-tier content across the swarm; attestation gates only
  *decryption/playback*, never *carriage* (whitepaper §7.2, mirroring
  DCI: the encrypted DCP is freely distributable; only certified
  players decrypt it). Gating carriage would shrink the premium-title
  swarm to the attested-player fleet and defeat the member-owned-CDN
  property (§10.1, whitepaper §9).
- LAN *playback delivery* differs by tier: a Seed streams *open-tier*
  content to companion client apps over the LAN as standard HLS, while
  compliant-tier playback stays on the sealed direct player
- Compromised peers can be deprioritized without protocol-level
  coordination

**Interfaces above:**
- Layer 5 (attestation) gates which devices can *decrypt and play*
  compliant-tier content — not which Seeds may carry or serve its
  encrypted bytes (carriage is open to any device)
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

### 7.2 Compliant tier

Seeds carrying hardware attestations from a federated certification
authority. Required for studio-licensed content. Revocable. Audited.

**Certification credential, technically:**
- Each compliant Seed holds a per-device keypair generated inside
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
- Federation milestone: at a network-size or maturity threshold
  (**to be published; not yet set**), the CA opens to additional
  signers (independent auditors, integrator-channel certifiers,
  academic partners)
- Federation is a *commitment*, not an indefinite promise — but until
  the trigger number/date is published it is not yet a *defined*
  milestone; fixing that number is a near-term deliverable

### 7.3 Both tiers run the same protocol

A user's library may contain both open-tier and compliant-tier
titles. The client app sees a unified library; the only difference is
that compliant-tier titles will refuse to play on a non-compliant
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
  deployment of compliant Seeds.

**What this layer doesn't dictate:** UI/UX choices, branding,
business model, monetization. Those are commercial choices made by
each application implementer.

---

## 9. Layer 7 — Governance

How the protocol evolves over time. Future work.

**Components (all future):**

- **Foundation entity.** Holds the protocol IP, governs upgrades,
  stewards the certification authority, and operates as the
  protocol-neutral standards body. Legal structure: a **US 501(c)(6)
  trade association** (modeled on the Wi-Fi Alliance, USB-IF, and HDMI
  Forum), consistent with the whitepaper §15 and the README. (An
  earlier draft floated a Cayman Foundation Company; that arrived with
  the retired v3.0 token design and was discarded with it — see the
  v2.4 changelog.)
- **Federated certification.** Layer 5 attestation authorities
  beyond the Foundation, federated under a public governance process.
- **Token holder voting (per title), bounded by immutability.** The
  one per-title vote that operates on a *live* token is the **supply
  split** (§4): the copyright holder proposes, ERC-1155 holders
  approve, token quantities multiply, and each holder's proportional
  ownership is preserved. It does **not** leave the rights tiers
  untouched, by design: with thresholds fixed in absolute token counts,
  a split lowers every tier's cost as a fraction of supply *uniformly*,
  so the ratios between tiers are preserved while the whole ladder
  becomes more accessible — the mechanism that lets authentic supply
  expand to meet demand (whitepaper §4). Relative *ownership* is
  preserved; tier *pricing* is intentionally lowered. A
  title's **thresholds and fee split are immutable for the life of the
  token**, and a royalty share already granted to a collaborator is
  **irrevocable** (whitepaper §4, §10.1, §10.3 — additions to the
  author's shareholder set are allowed, reductions of an existing grant
  are not); changing the immutable terms is not a vote on the existing
  title but a **new mint** (a new version / token ID, §4), leaving the
  original market undisturbed. **Distribution
  rights are never withdrawable** — not by the Foundation, not by
  vote: permanence (whitepaper §8) is a hard guarantee, and a holder's
  ability to play and trade what they own cannot be revoked by any
  governance process. Protocol-level governance lives in the
  Foundation.
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
- Layer 5 ties compliant-tier content key wrapping to user's wallet
- Layer 6 displays library based on wallet's token holdings

This is intentional. The wallet is the single source of identity
across the protocol. The wallet is never held by Seed hardware; phone-
based wallets sign on the user's behalf.

### 10.2 Open tier vs. compliant tier separation runs through every layer

| Layer | Open tier | Compliant tier |
|---|---|---|
| 0 | Wallet only | Wallet + secure-element-attested device |
| 1 | Standard IPFS pinning | Same, plus per-device wrapped manifest |
| 2 | Threshold-released keys (legacy public-data derivation retired to public-domain demo; §4.2) | Per-device-wrapped keys, hardware-bound (per-N security) |
| 3 | Same registries | Same registries plus revocation list |
| 4 | Any Seed can carry & serve | Any Seed can carry & serve the encrypted bytes; only an attested device can decrypt & play |
| 5 | No attestation required | Hardware attestation required |
| 6 | Any client app | LMAP-conformant clients (or compatible ones) |
| 7 | Foundation governs spec | Foundation + CAs govern certification |

A useful frame: *the open tier is the protocol's permissionless
default; the compliant tier is the optional add-on that enables
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
Layer 5 — Attestation     ↑ (open tier / compliant tier split)
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
3. **Foundation legal structure.** Decision: **US 501(c)(6) trade
   association** (Wi-Fi Alliance / USB-IF / HDMI Forum model),
   consistent with whitepaper §15 and README. The earlier Cayman
   Foundation Company recommendation was retired with the v3.0 token
   design (v2.4 changelog).
4. **Initial certification authority.** Recommendation:
   Foundation-only at v1, with a public commitment to federate at a
   network-maturity threshold that is *itself a near-term deliverable
   to define and publish* (not yet set).
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

## Glossary (disambiguating overloaded terms)

The 2026 "certified → compliant" rename introduced two collisions; this
glossary is the source of truth, and a follow-up pass will apply it
throughout (prefer *conformant* for the generic sense).

- **Conformant** — *any* implementation that follows the LMAP spec: a
  conformant Seed, client, or marketplace. This is the generic sense
  ("any implementation may participate"). Prefer this word over the
  generic use of "compliant."
- **Compliant tier** — the specific access tier requiring hardware-
  attested per-device binding on a sealed direct player. A "compliant
  device" is a device that meets *this tier's* hardware conformance
  spec (§3 of the device doc), not merely a spec-following device.
- **Credential issuer (attestation authority)** — verifies a device's
  hardware integrity and signs its attestation credential (a CA-like
  role; whitepaper §7.3).
- **Key issuer (key service)** — wraps content keys to attested,
  currently-entitled devices. It does **not** maintain `boundCount`:
  binding state lives in the on-chain binding registry, written by the
  attested fleet under the blinded-commitment rule (§4.3). Distinct
  role from the credential issuer, though the Foundation may operate
  both during bootstrap. Where older text says keys are "issued by
  certification authorities," read *key issuer*.
- **Direct player** — a sealed compliant device with its own video
  output; the launch playback device. **Companion client** — an
  open-tier app on a third-party platform (Roku/Apple TV/iOS), for LAN
  streaming and phone-as-remote, outside the compliant-tier perimeter.
- **Bind / release / `boundCount` / `transferable`** — a copy *binds*
  to one device (increments the wallet's `boundCount` for that
  tokenId); *release* deletes it and decrements; `transferable =
  balance − boundCount`. See the device doc §2.

---

*Last updated: 2026-07-05 (aligning to whitepaper v2.6: native access layer, compliant-tier rename, direct-player, binding model — rework in progress). Living document. Expect refinement as
each layer matures from spec to implementation.*
