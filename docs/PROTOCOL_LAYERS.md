# LMAP — Layered Architecture

> The canonical engineering reference for how LMAP (Liquid Media Access
> Protocol) decomposes. Each layer is independently specifiable, testable,
> and (where applicable) replaceable. Conflating layers — particularly
> the entitlement layer with the cryptographic layer — is how comparable
> projects have failed.
>
> **Note on stewardship (added 2026-06-02):** LMAP is stewarded by the
> Liquid Media Foundation (LMF), not by Wylloh. Wylloh is the first
> commercial implementation. The LMAP whitepaper v3 at
> `docs/whitepaper/WHITEPAPER_V3.md` is the canonical full specification;
> this document is the engineering reference for the layered decomposition.
> Where this document and the whitepaper diverge, the whitepaper is
> authoritative.
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
> - `docs/seed-one/README.md` — Seed SKU strategy (Seed One Y0; Origin Y1)
> - `docs/seed-one/ARCHITECTURE.md` — what a Seed *does* at the system level
> - `docs/seed-one/SEED_ONE_SPEC.md` — *how to build* the Y0 affordable SKU
> - `docs/seed-one/ORIGIN_SPEC.md` — *how to build* the Y1 brand-crown SKU
> - `docs/seed-one/INDUSTRIAL_DESIGN.md` — what the Origin Seed *is*

---

## 1. Overview

The Wylloh protocol is decomposed into eight layers. Each layer has a
defined responsibility, a published interface to the layers above and
below it, and an implementation status. Different parties can build
different layers as long as the interfaces are honored.

| # | Layer | Responsibility | Status |
|---|---|---|---|
| 0 | Trust Anchors | Cryptographic primitives; hardware roots; wallet identity; contract immutability | Partial |
| 1 | Storage | Content distribution substrate (IPFS, manifests, stake-incentivized pinning) | Shipped (centralized pinning); spec'd (LMA-incentivized) |
| 2 | Cryptography | Encryption, threshold-mediated key release, key hierarchy, watermarking | Shipped (chunked AES-GCM); in migration (threshold release via Lit Y0 → LMAP-native Y1+) |
| 3 | Entitlement | Smart contracts: distribution + copyright registries, royalties, PaymentSplitter | Shipped (V4.1 distribution); spec'd (V5 copyright) |
| 4 | Network | Peer discovery, shard request/response, LAN streaming | Future (depends on Seed reference implementation reaching v1) |
| 5 | Forward Compatibility | Optional hardware-attested key wrapping for legacy industry licensing frameworks | Spec'd; invoked per-content when contractually required |
| 6 | Application | Storefronts, library UI, playback clients, integrator tooling | Shipped (web client); future (TV/mobile) |
| 7 | Governance | Foundation structure; federated issuance for Layer 5; protocol governance | Future |

**Definition of layer status:**
- *Shipped*: code is in the repo, deployed to mainnet (where applicable), used in production
- *Spec'd*: design is specified in this or a companion doc but not yet implemented
- *Future*: scope is identified but neither specified nor implemented; deliberate placeholder

**The protocol's security model is threshold-mediated key release**
(Layer 2 §4.2). Access to a film's decryption material is gated by
current on-chain ownership at decryption time, evaluated by a
distributed network of stake-bonded nodes. The protocol claims, and
intends to demonstrate, security equivalent to or stronger than
legacy hardware-attested DRM.

**Layer 5 is forward-compatibility, not a co-equal "tier."** Some
licensing relationships — primarily those originating with major
studios — reference specific hardware-DRM technologies as
contractual conditions. The protocol's design includes forward-
compatible support for hardware-attested key wrapping so these
relationships can be honored. This support is invoked per-content
when content metadata signals it; it is not engaged for the
protocol's primary use cases. The relevance of Layer 5 decreases as
industry compliance frameworks evolve to recognize threshold
cryptography directly.

Earlier versions of this document described a *two-tier* model
(open tier + certified tier as parallel security modes). That
framing has been retired; threshold-mediated release at Layer 2 is
*the* security model, and Layer 5 hardware attestation exists at
the periphery as forward-compatibility for legacy frameworks.

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

  Reference Seed implementations target ARM TrustZone in combination with a
  discrete or integrated secure element. **Seed One** (`docs/seed-one/SEED_ONE_SPEC.md`
  §4.3) uses TPM 2.0 (Infineon SLB9670) over SPI on the Pi 5. **Origin Seed**
  (`docs/seed-one/ORIGIN_SPEC.md` §5.2) uses a discrete secure element on the
  custom carrier PCB (NXP SE050 candidate) plus TPM 2.0 plus TrustZone. Both
  SKUs run the same firmware with the same hardware-attestation
  capability available for Layer 5 forward-compatibility when content
  invokes it.

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
  pins all registered film CIDs by default during bootstrap. As the
  Seed network grows (Layer 4) and the LMA-incentivized
  proof-of-retrievability mechanism (whitepaper §7) ships in Year 1,
  pinning becomes distributed and self-strengthening. Centralized
  pinning sunsets by end of Year 2.
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
load-bearing security layer. Whitepaper v3 §7 and §8 are the canonical
specification; this section gives the engineering view.

### 4.1 Symmetric encryption (shipped)

- **AES-256-GCM** for content at rest and in transit
- **Chunked format**: `[Len(4b BE)][IV(12b)][Ciphertext+Tag(16b)]`
  per 4 MiB chunk. Self-authenticating per chunk; supports streaming
  decryption with constant memory.
- **Per-title content keys** derived via HKDF with domain separation;
  no key reuse across titles.

Specified in `client-v2/src/services/encryption.ts` and ported to
Seed firmware. Spec is open; any compliant client can implement.

### 4.2 Access to decryption keys — threshold-mediated release (the production model)

LMAP's cryptographic security rests on a single principle: **access to
a film's decryption material is gated by current on-chain ownership
of the corresponding token, evaluated at decryption time by a
threshold cryptographic network**. No party — not the foundation,
not a storefront, not a hardware vendor, not the protocol's own
contracts — can release decryption material to a wallet that does
not currently satisfy the access condition.

**Mechanism.** Master keys are random (32 bytes) at content
preparation. The publisher encrypts the film with the master key
using chunked AES-256-GCM, then submits the master key to the
threshold network for encryption against a Distributed Key
Generation public key. The threshold-encrypted master key is stored
alongside the metadata; the film's metadata declares an Access
Control Condition (typically `balanceOf(:userAddress, :tokenId) > 0`
against the LMAP registry).

At decryption, the client signs a SIWE-style authentication message,
submits the threshold-encrypted master key and ACC to the threshold
network, and threshold-network nodes independently verify the wallet
signature and query current chain state. Decryption shares are
released only if the ACC evaluates true; the client reassembles the
master key and decrypts using the standard chunked-AES-GCM path.

**Transfer behavior emerges from the architecture.** When a token
moves from one wallet to another, the ACC is re-evaluated at the
next decryption attempt. The seller no longer satisfies the
condition; the buyer now does. No re-wrapping, no foundation
involvement, no seller cooperation required.

**Bootstrap substrate (Year 0):** Lit Protocol's Naga mainnet provides
the threshold-decryption network during bootstrap. Production-grade,
operating against Polygon as an ACC chain, multi-year operational
maturity. Year-0 commercial content is tokenized against Lit.

**Native substrate (Year 1+):** The Liquid Media Foundation deploys
an LMAP-native threshold network on the Liquid Media Chain (Layer 0;
see whitepaper v3 §6). Nodes stake LMA, perform threshold operations,
earn emission, are slashed for misbehavior. By end of Year 2 all
production content has migrated; the Lit Protocol dependency is
retired.

### 4.3 Legacy: the deterministic key derivation construction

Earlier protocol versions described an "open tier" in which the
content-decryption wrapping key was deterministically derivable from
public on-chain data using a documented formula:

```
wrappingKey = SHA-256(contractAddress.toLowerCase() + ":" + tokenId + ":wylloh-v1")
```

The encrypted master key was returned by a storage API after an
on-chain `balanceOf()` check, but once any holder received the
encrypted master key, decryption could proceed entirely from public
inputs.

This construction was articulated as a deliberate design choice in
service of platform independence. Reviewed against the requirements
of a production protocol for film distribution — independent or
otherwise — it has been retired. The derivable-key construction does
not gate decryption by current ownership: any party with the public
chain data and the published metadata can derive the wrapping key,
retrieve the encrypted master key, and decrypt the film without
holding the token. The construction is appropriate for *demonstrating
the protocol's other mechanics on public-domain content* (the role
it played in the V4.1 deployment with *The Cocoanuts*) and is not
appropriate for new commercial content.

The V4.1 deployment continues to serve already-tokenized
public-domain content under the legacy construction; new content is
tokenized against the threshold-mediated mechanism (§4.2).

### 4.4 Hardware-attested mode (optional, for studio content)

A subset of content — primarily content licensed from major studios —
is governed by contractual digital-rights management requirements
that threshold release does not satisfy on its own, not because of
cryptographic deficiency but because studio compliance frameworks
predate threshold cryptography and reference specific hardware-DRM
technologies. For these content classes the protocol provides a
*hardware-attested mode* layered on top of threshold release.

In hardware-attested mode:

- **Per-device wrapping.** Each compliant Seed holds a per-device
  keypair generated inside its hardware secure element. For attested
  content, the threshold-released master key is additionally wrapped
  to the Seed's per-device public key. Unwrapping occurs only inside
  the secure element; the unwrapped key never appears in main memory.
- **Attestation report at issuance.** Wrapped-key issuance requires
  the Seed to present a fresh attestation report signed by its
  secure element, containing current firmware measurements. The
  report is verified against the Seed's attestation credential.
- **Federated issuers.** Attestation credentials are issued by
  federated authorities under the Liquid Media Foundation's framework
  (see Layer 5, §7). No single issuer can unilaterally approve or
  deny attestation; the framework's governance can revoke any issuer
  whose practices fail audit.
- **Revocation.** Compromised attested devices can be added to a
  revocation registry; subsequent wrapped-key issuance refuses
  revoked-device attestation.

**Hardware binding is a normative requirement.** A compliant
hardware-attested implementation MUST use a hardware secure element
for keypair generation, key custody, key unwrapping, and attestation
signing. An implementation that performs any of these operations
outside a hardware secure element is not conformant.

**Carriage versus playback.** Hardware-attested mode gates
*decryption*, not *carriage*. Encrypted attested-mode content is
freely distributable through the same content-addressed substrate.
Tokens remain freely transferable across all wallets. Hardware
attestation gates playback only.

### 4.5 Watermarking

Forensic watermarking binds a leak to a specific wallet, raising the
cost of unauthorized distribution beyond the bare cryptographic
extraction cost. Watermarks may be inserted server-side at
content-preparation time (per-purchase variants delivered to specific
wallets) or, for attested-mode content, Seed-side at decryption time
inside the secure element, before plaintext leaves the secure
perimeter.

Robust watermarking against transcoding and adversarial filtering
requires commercial watermarking implementations — engagement with
Verimatrix, NAGRA, or Irdeto is the path to studio-grade robustness.

### 4.6 Security claims — precise statements

Three claims about how protocol security relates to network size,
with different defensibility:

1. **Threshold-mediated release with stake-based sybil resistance —
   strong claim.** Compromising the threshold network requires either
   compromising more than the slashing-tolerance threshold of
   independently-staked nodes (economically irrational at scale) or
   extracting cryptographic material from those nodes (each holds
   only a share). The network's aggregate exposure does not grow
   with network size.

2. **Per-device key wrapping (attested mode) — strong claim.**
   Compromising one attested Seed yields *that Seed's local content
   only*. The network's aggregate exposure does not grow with
   network size, because each attested device is its own isolated
   vault.

3. **Threshold dispersal of ciphertext (storage layer, future) —
   modest claim.** Sharding ciphertext across Seeds raises the
   per-shard extraction cost. An attacker compromising one Seed
   gets 1/n of the ciphertext; reconstructing the asset requires
   reaching the threshold k. This is real but bounded — a motivated
   attacker can target enough Seeds to reach k. The combinatorial
   cost argument applies but does not produce asymptotic security.

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
apps. Future work — depends on the Seed reference implementation (Seed One
and/or Origin) shipping at sufficient density.

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
- A Wylloh-native protocol is a future option for higher-fidelity or
  lower-latency requirements but not necessary for v1

**What this layer guarantees:**
- Seeds can find content available on the network without central
  coordination
- A Seed serves content to client apps over the LAN as standard HLS
- Compromised peers can be deprioritized without protocol-level
  coordination

**Interfaces above:**
- Layer 5 (forward compatibility) gates which Seeds can decrypt
  content invoking the hardware-attested capability; carriage of
  encrypted bytes is unrestricted
- Layer 6 (application) consumes the LAN streaming protocol

**Interfaces below:**
- Layer 1 (storage) is the source of bytes
- Layer 2 (cryptography) wraps bytes in transit and at rest

---

## 7. Layer 5 — Forward Compatibility for Legacy Industry Frameworks

Threshold-mediated key release (Layer 2 §4.2) is the protocol's
security model. LMAP claims, and intends to demonstrate, security
equivalent to or stronger than legacy hardware-attested DRM through
threshold cryptography with stake-based sybil resistance.

Layer 5 exists not as a feature of the protocol's security model but
as **forward-compatibility for legacy industry licensing frameworks**
— specifically, frameworks originating with major studios that
reference specific hardware-DRM technologies (Widevine L1, PlayReady,
FairPlay) as contractual conditions of licensing. These frameworks
predate threshold cryptography's deployment maturity. We expect them
to evolve to recognize threshold cryptography directly; the
hardware-attested capability at this layer exists so that licensing
relationships predicated on the current frameworks can be honored
without compromising the protocol's open-protocol participation
properties.

The protocol's center of gravity is threshold release at Layer 2.
This layer's relevance decreases as industry compliance frameworks
evolve to recognize threshold cryptography. Until they do, the
protocol provides forward-compatibility; the framing is honest about
what this is.

### 7.1 What the protocol does not require

The bulk of LMAP content — indie productions, public domain,
Creative Commons, festival distributions, creator-direct releases —
does not require this layer. Threshold-mediated release with
stake-based sybil resistance provides their security model in full.
Layer 5 has no operational role for the protocol's primary use
cases.

### 7.2 The hardware-attested capability, when invoked

When a licensing counterparty's contract references hardware
attestation as a condition, the capability operates as follows.
Participating Seeds hold per-device keypairs generated inside their
hardware secure elements (Layer 0). An attestation issuer verifies a
Seed's hardware integrity (firmware measurements, supply-chain
provenance, key custody) and signs a credential binding the Seed's
device public key to a manifest of approved firmware measurements.

When a Seed requests a wrapped content key for content under this
capability, it includes a fresh attestation report signed by its
secure element, containing current firmware measurements. The
issuance authority verifies the report against the Seed's
attestation credential and issues the wrapped content key only on a
clean match. The wrapped key is decrypted only inside the Seed's
secure element; the unwrapped key never appears in main memory or
persistent storage.

**Reference hardware capability** (Wylloh Seed reference
implementations include the necessary hardware as forward-
compatibility; whether the capability is invoked depends on the
content):

- **Seed One:** TPM 2.0 (Infineon SLB9670) over SPI on the Raspberry
  Pi 5; ARM TrustZone in the BCM2712 SoC.
- **Origin Seed:** TPM 2.0 plus a discrete secure element (NXP SE050
  candidate) on the custom carrier PCB; ARM TrustZone in the CM5
  SoC.

Both Seed reference implementations are forward-compatible with the
hardware-attested capability when content requires it. The hardware
is included in the reference designs so the protocol can honor
legacy licensing frameworks during the transition period; it is not
the basis of the protocol's primary security guarantee.

### 7.3 The federated issuance framework

When the hardware-attested capability is invoked, attestation
credentials are signed by independent *attestation issuers*. An
issuer is a party that verifies a Seed's hardware integrity and
signs the credential. Issuers operate under a federated framework
governed by the Liquid Media Foundation (whitepaper v3 §8.5, §16.2).

No single issuer can unilaterally approve or deny attestation. The
framework's governance can revoke any issuer whose practices fail
audit. Counterparties negotiate with the framework, not with a
single platform operator. The model is structurally analogous to the
federation of certificate authorities that underpins the public
web's TLS infrastructure: independent issuers, audited practices,
root trust managed by a body distinct from any commercial
participant.

The framework launches with a single issuer (the Liquid Media
Foundation itself) and a public commitment to federate at a defined
milestone of network maturity. Federation is a visible commitment,
not an indefinite promise. We note that the framework's relevance
itself depends on the persistence of the legacy industry
requirements that necessitated it; over time, both the issuer
federation and the hardware-attested capability decrease in
significance relative to threshold-mediated release.

### 7.4 Carriage versus playback

When invoked, the hardware-attested capability gates *decryption*,
not *carriage*. Encrypted content under this capability is freely
distributable through the same content-addressed substrate as all
other LMAP content. Tokens remain freely transferable across all
wallets. Hardware attestation, when invoked, gates playback only.
This preserves user sovereignty (a buyer's ownership is unaffected
by hardware availability) while honoring the legacy contractual
requirement (decryption is impossible without an attested secure
element).

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
- **Storefront SDK.** Future. Lets third parties build Wylloh-
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

**Current state:** Foundation does not yet exist. Wylloh's founding
team operates in a stewardship role. This is the current bootstrap
reality; the path to formal foundation governance is a documented
3-5 year arc.

---

## 10. Cross-layer concerns

A few properties span multiple layers and deserve explicit treatment.

### 10.1 Wallet identity is shared infrastructure

Wallet identity (Layer 0) flows through every layer above it:
- Layer 3 reads wallet for entitlement
- Layer 4 reads wallet to gate Seed-to-Seed shard exchange (potentially)
- Layer 5 binds the hardware-attested capability (when invoked) to
  the user's wallet via per-device key wrapping
- Layer 6 displays library based on wallet's token holdings

This is intentional. The wallet is the single source of identity
across the protocol. The wallet is never held by Seed hardware; phone-
based wallets sign on the user's behalf.

### 10.2 The protocol's security model, plus forward-compatibility for legacy frameworks

The protocol's security model is threshold-mediated key release at
Layer 2 §4.2. Every production deployment runs through this model.
The hardware-attested capability (Layer 2 §4.4, Layer 5) exists as
forward-compatibility for legacy industry licensing frameworks that
have not yet evolved to recognize threshold cryptography; it is
invoked per-content when a licensing contract requires it.

| Layer | LMAP protocol (all production content) | Forward-compat capability (when invoked by legacy licensing contracts) |
|---|---|---|
| 0 | Wallet | Wallet + secure-element-attested device |
| 1 | IPFS + stake-incentivized pinning | Same |
| 2 | Threshold-mediated key release (Lit Y0; LMAP-native Y1+) | Same, plus per-device key wrapping at the secure element |
| 3 | Liquid Media Chain registries | Same, plus revocation registry |
| 4 | Any compliant Seed can serve | Same encrypted bytes can be served by any Seed; only attested Seeds can decrypt |
| 5 | Not engaged | Hardware attestation engaged |
| 6 | Any client app | Forward-compat-capable clients |
| 7 | Foundation stewards spec | Foundation + federated issuers manage the forward-compat capability |

A useful frame: *threshold-mediated release IS the protocol's
security model. The hardware-attested capability is forward-
compatibility for legacy industry frameworks; we expect those
frameworks to evolve to recognize threshold cryptography directly,
at which point the capability's relevance decreases.*

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
Layer 7 — Governance      ↑ (LMF stewardship, federation, token-holder voting)
Layer 6 — Application     ↑ (storefronts, library UI, playback apps, integrator tools)
Layer 5 — Attestation     ↑ (optional, content-specific, federated)
Layer 4 — Network         ↑ (Seed peer protocol, LAN streaming via HLS+mDNS)
Layer 3 — Entitlement     ↑ (ERC-1155 distribution, ERC-721 copyright, royalties, PaymentSplitter, on Liquid Media Chain)
Layer 2 — Cryptography    ↑ (AES-256-GCM, threshold-mediated release, optional attested wrapping, watermarking)
Layer 1 — Storage         ↑ (IPFS, manifests, stake-incentivized pinning, future shard dispersal)
Layer 0 — Trust Anchors   ↑ (secure element, wallet keys, contract immutability, Liquid Media Chain settlement)
```

---

## 12. Decisions ratified in whitepaper v3 (formerly "open architectural questions")

The architectural questions that lived at the end of earlier versions
of this document have been answered in whitepaper v3:

1. **Secure element family for the reference Seed.** NXP SE050 for
   Origin Seed; TPM 2.0 (Infineon SLB9670) for Seed One. Both
   hardware-attestation-capable.
2. **LAN streaming protocol.** HLS over HTTPS with mDNS discovery.
   No DLNA.
3. **Foundation legal structure.** Cayman Foundation Company (working
   commitment in whitepaper v3 §16.1; ratification pending
   securities-counsel review attendant to LMA token issuance).
4. **Initial attestation authority.** Foundation-only at launch with
   public commitment to federate at a defined milestone of network
   maturity. See whitepaper v3 §7.3 and §8.5.
5. **Watermarking provider engagement.** Server-side watermarking
   for standard content; secure-element-side watermarking for
   attested-mode content. Commercial-provider engagement (Verimatrix,
   NAGRA, Irdeto) is a 2026 milestone.
6. **Threshold dispersal scheme.** Reed-Solomon erasure coding for
   ciphertext shards is specified for a future protocol version;
   not blocking for v1 launch.
7. **DKG ceremony for threshold key generation.** Decentralized DKG
   among stake-bonded threshold-network nodes; the Lit Protocol
   bootstrap substrate provides the production-grade implementation
   during Y0; LMAP-native DKG ceremony for the Y1+ native network.

Decisions not yet ratified in whitepaper v3:

- Final emission-curve parameters for LMA (specified in companion
  token-economics document published with the Foundation's
  incorporation)
- Final stake minimums for storage-provider and threshold-network
  participation (specified in companion documents)
- Sequencer-decentralization consensus algorithm for the Liquid Media
  Chain (specified in chain-architecture document published alongside
  Y1 deployment)

---

*Last updated: 2026-06-02. Layer 2 (Cryptography) substantially
rewritten to retire the legacy "open tier with deterministic key
derivation" framing and to specify threshold-mediated key release as
the production access-control mechanism (with hardware-attested mode
as the optional layer for studio-content requirements). Layer 5
(Attestation) updated correspondingly — no longer framed as a
"two-tier" gate but as a per-content optional mode. Cross-layer
table (§10.2) updated. Open architectural questions (§12) updated
to reflect the decisions ratified in whitepaper v3. The eight-layer
decomposition itself is unchanged; the changes are within Layer 2
and Layer 5. Whitepaper v3 at `docs/whitepaper/WHITEPAPER_V3.md`
remains the canonical full specification.*
