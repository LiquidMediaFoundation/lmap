<div class="titleblock">

# LMAP — Liquid Media Access Protocol {.title}

#### A Peer-to-Peer Protocol for Media Distribution and Ownership {.subtitle}

Harrison Kavanaugh  ·  contact\@liquidmediafoundation.org

*Version 2.5 — July 2026*

</div>

## Abstract {-}

A purely peer-to-peer system for film distribution would allow digital
media ownership to exist independently of any single platform, studio,
or streaming service. The current model of centralized streaming
creates fundamental misalignments: platforms bear infrastructure costs
proportional to viewership, creators receive opaque compensation,
and consumers own nothing permanent. We propose a layered protocol in
which each film exists as fungible tokens within a unified registry
contract, with separate provision for copyright ownership. Token
quantity determines usage rights — from personal viewing to theatrical
exhibition — at thresholds configured per title. Encrypted content
is stored on a content-addressed network. Access to decryption
material is gated by current on-chain ownership, evaluated against
live chain state by a native access layer, so that access moves with
the token. At maturity the access layer is decentralized and no
single party can release a key to a wallet that does not hold it;
during bootstrap a single foundation issuer performs this function,
gating transfer and first-bind — never the playback of content a
holder already possesses. For content whose licensing
contractually requires endpoint protection, a *compliant tier* adds
hardware-attested per-device key wrapping; a legacy
deterministic-key construction survives only for public-domain
demonstration content. A
network of user-operated nodes — *Seeds* — distributes content,
inverting the conventional cost model: the network strengthens as
viewership grows. Smart contracts automate royalty distribution on
every transaction, including secondary sales where collectors can
sell exhibition rights directly. The protocol is governed by an
independent foundation, structurally distinct from any commercial
operator. We argue that *liquid media* — physical-grade ownership in
liquid digital form — is achievable without compromising the
sovereignty that makes the design worthwhile.

\vspace{1em}

## 1. Introduction {-}

The transition to streaming was marketed as disruption, but the
underlying economics reveal a fundamentally broken model. When a film
succeeds on a centralized platform, infrastructure costs increase
proportionally — the platform is economically punished for having
popular content. This creates incentives misaligned with the goal of
connecting audiences with compelling stories.

The consumer experience has equally degraded. Digital purchases are
platform-locked, creating fragmented collections scattered across
services. When platforms sunset or lose licensing rights, purchased
content disappears. Unlike physical media, there is no true
ownership — only temporary access privileges revocable at the
platform's discretion.

Creators face similar opacity. Residual payments flow through
accounting systems designed to obscure rather than illuminate. The
shift from theatrical and physical media sales to streaming has
compressed compensation without providing comparable transparency or
participation in secondary markets.

What is needed is a protocol-level solution addressing all
constituencies simultaneously — analogous to how DVD or USB function:
not as a platform a consumer signs up for, but as a *standard* that
many implementations interoperate through. We propose LMAP (the
Liquid Media Access Protocol): a protocol where digital media is
tokenized into standardized units granting
verifiable ownership and access rights; content is distributed
through a peer-to-peer network that scales positively with demand;
smart contracts ensure automatic royalty distribution on every
transaction; and ownership is structurally separable from any
particular platform that runs on the protocol.

What consumers experience is *liquid media* — a generic public term
for the category LMAP enables. Liquid media is to streaming
services what physical media was to broadcast television: a different
form of ownership, with different rights, that buyers can hold,
transfer, and pass on.

## 2. Token Architecture {-}

Each film exists as a unique token ID within a master ERC-1155 [^1]
registry contract. Unlike ERC-721 [^2] non-fungible tokens, where
each token is distinct, ERC-1155 allows millions of identical tokens
per film, enabling both mass distribution and liquidity. A single
contract scales to thousands of films, each identified by a unique
token ID, with configurable quantities per title.

The token's URI points to a content identifier on a distributed
storage network containing immutable metadata: title, synopsis,
credits, and references to media assets. This architecture ensures
that even if any particular implementation of the protocol ceases
operations, token holders retain permanent access through the
decentralized network and the open protocol specification.

*Implementation status:* shipped on Polygon mainnet as the
`WyllohRegistryProtocolV4_1` contract. Verified source available via
public block explorers.

## 3. Separation of Distribution and Copyright {-}

A critical distinction exists between distribution rights and
underlying copyright. The ERC-1155 registry manages distribution
tokens — fungible units representing viewing and exhibition rights.
A separate ERC-721 contract is specified to establish copyright
ownership: a single non-fungible token per film representing the
intellectual property itself.

The copyright token grants control over derivative works,
merchandising, and the ability to propose governance actions such as
token splits. Distribution token holders own rights to view, exhibit,
and trade — but not to create sequels or merchandise. Crucially, the
copyright holder cannot unilaterally mint additional distribution
tokens; supply modifications require token holder approval, protecting
holders from dilution. This mirrors traditional film finance, where
investors hold revenue participation without controlling the
underlying intellectual property, while adding protections absent in
conventional structures.

This separation enables powerful scenarios. A studio could acquire
the copyright token to produce a sequel while existing distribution
tokens continue trading. The original filmmaker benefits from the
sale; distribution token holders retain their viewing rights and
market participation. Rights flow to natural owners without forcing
all-or-nothing transactions.

*Implementation status:* design intent. The current V4.1 registry is
the ERC-1155 distribution layer; the ERC-721 copyright registry is
specified for a future protocol version (V6) and has not yet been
deployed. The current protocol's role-gated minting (see §15) serves
as a near-term substitute for the copyright registry's
supply-modification controls.

## 4. Modular Rights Through Stacking {-}

Token quantity determines usage rights through a threshold-based
licensing system. A single token grants personal viewing rights —
analogous to owning physical media. As tokens accumulate in a wallet,
additional rights unlock at thresholds the filmmaker configures at
tokenization time.

Thresholds are intentionally not fixed by the protocol; each
filmmaker sets thresholds appropriate to their content's economics.
A documentary might set low thresholds to encourage screenings; a
genre release might set high thresholds reflecting commercial value.
The protocol does not impose a universal price for theatrical rights
because no such universal price exists in reality. The market
discovers appropriate pricing through trading at the thresholds the
filmmaker has chosen.

For illustrative purposes only — not as protocol-level constants —
typical configurations might include:

- *1 token* — personal viewing rights
- *100 tokens* — small-venue exhibition
- *60,000 tokens* — theatrical exhibition rights with access to
  professional distribution formats

But these are choices, not specifications. Thresholds for any given
film are encoded in that film's metadata at minting and are immutable
thereafter for the life of that token's contract.

This mechanism creates natural price discovery for commercial rights.
Rather than negotiating complex licensing agreements, distributors
acquire sufficient tokens on the open market. Token supply is fixed
at initial minting; if market conditions warrant increased liquidity,
token holders may vote to approve a split, multiplying token
quantities while preserving proportional ownership. The copyright
holder may propose splits but cannot execute them unilaterally. New
creative works — sequels, adaptations, alternative cuts — are
tokenized as separate token IDs with independent supplies, leaving
original token markets undisturbed.

*Implementation status:* shipped. Stacking thresholds and on-chain
enforcement are operational in V4.1.

## 5. Layered Architecture {-}

The protocol decomposes into eight layers. Each layer has a defined
responsibility, a published interface to the layers above and below
it, and an implementation status. Different parties can build
different layers as long as the interfaces are honored. Conflating
layers — particularly the entitlement layer with the cryptographic
layer — is how comparable projects have failed.

| # | Layer | Responsibility |
|---|---|---|
| 0 | Trust Anchors | Cryptographic primitives; hardware roots; wallet identity; contract immutability |
| 1 | Storage | Content distribution substrate (IPFS, manifests) |
| 2 | Cryptography | Encryption, key hierarchy, threshold-mediated key release, dispersal, watermarking |
| 3 | Entitlement | Smart contracts: distribution + copyright registries, royalties, rights tiers |
| 4 | Network | Peer discovery, shard request/response, LAN streaming |
| 5 | Attestation | Compliant-tier hardware attestation (the open tier gates access at Layer 2) |
| 6 | Application | Storefronts, library UI, playback clients, integrator tooling |
| 7 | Governance | Foundation structure; federated certification; protocol governance |

A storefront (Layer 6) only needs to read entitlement (Layer 3); a
Seed manufacturer needs to implement Layers 1, 2, 4, and optionally
5; an academic auditor of the compliant tier only needs to engage
with Layer 5 and the cryptographic claims of Layer 2. Each layer
should be specifiable, testable, and replaceable independently of
the others. The protocol does not mandate that any single party
implement all eight layers.

The remaining sections of this paper traverse these layers from
storage upward.

## 6. Content Storage {-}

Media files are encrypted using AES-256-GCM before distribution on a
content-addressed storage network [^3]. The metadata structure nests
content identifiers: the token URI points to a metadata file
containing references to both unencrypted promotional assets (poster,
trailer) and encrypted media files. Each encrypted asset specifies a
threshold — the token quantity required for access — corresponding to
the rights tiers established at minting.

Encrypted content is stored in a chunked format
(`[Length(4 bytes)][IV(12 bytes)][Ciphertext+Tag(16 bytes)]` per
4-MiB chunk) which is self-authenticating per chunk and supports
streaming decryption with constant memory. The format is documented
in the protocol specification; any conformant client can implement
encryption and decryption against it.

A future enhancement at this layer is *threshold dispersal of
ciphertext shards* — distributing encrypted content shards across the
Seed network using Reed-Solomon erasure coding, with the option of
secret-share-based reconstruction [^9], such that reconstruction
requires a quorum of nodes. This is a resilience
property at the storage layer, not the load-bearing security
mechanism (see §7.4 for the precise scope of this claim).

*Implementation status:* chunked AES-256-GCM encryption and IPFS
storage are shipped. Threshold ciphertext dispersal is specified for
a future protocol version.

## 7. Cryptography and the Two-Tier Access Model {-}

The protocol gates access in two ways, for two kinds of content. For
permissive and indie content (the *open tier*), access is gated
cryptographically at Layer 2 by threshold-mediated key release —
honest access control that requires no special hardware on the
client side. For content whose licensing contractually requires
endpoint protection (the
*compliant tier*), the protocol adds hardware-attested per-device key
wrapping at Layer 5. Both tiers run the same protocol underneath;
they differ only in what stands between a holder and the plaintext.

### 7.1 Open Tier {-}

Any conformant Seed implementation serves content licensed under
permissive terms — public domain, Creative Commons, indie creators
who opt their content into open-tier distribution.

**The legacy deterministic key-derivation construction.** Earlier
versions of this whitepaper described the open tier's content key
as derivable from public on-chain data using the formula
`SHA-256(contract_address || ":" || token_id || ":wylloh-v1")`,
with the encrypted master key delivered to a buyer by a storage
service after that service verified on-chain ownership. This
construction was articulated as a deliberate design choice in
service of platform independence. Reviewed against the requirements
of any content of commercial value, it has been retired as a
production model: the derivable-key construction does not actually
gate decryption by ownership, because any party with the public
chain data can derive the wrapping key. The construction is
appropriate for *demonstrating the protocol's other mechanics on
public-domain content* — the role it played in the V4.1 deployment
of *The Cocoanuts* (1929, public domain) — and survives only for
that purpose. New commercial content does not tokenize under this
construction.

**Production access control: threshold-mediated key release.**
LMAP's production access-control mechanism is *threshold-mediated
key release*. A master key is generated as 32 random bytes at
content preparation, used to AES-256-GCM-encrypt the film in the
chunked wire format documented in §6, then encrypted to a Distributed
Key Generation public key held by a threshold cryptographic network.
The threshold-encrypted master key is stored alongside the film's
IPFS metadata. The film's metadata declares an Access Control
Condition — typically `balanceOf(:userAddress, :tokenId) > 0`
against the LMAP registry contract.

At decryption, the client signs a SIWE-style authentication message
proving control of the requesting wallet. The client submits the
authentication, the threshold-encrypted master key, and the Access
Control Condition to the threshold network. Threshold-network nodes
independently verify the wallet signature, query the chain for
current Access Control Condition state, and release decryption
shares only if the condition evaluates true. The client collects
*T* shares and reassembles the master key, then decrypts the film
using the standard chunked AES-GCM mechanism.

Transfer behavior emerges from the architecture. When a token moves
from one wallet to another, the Access Control Condition is
re-evaluated against current chain state at the next decryption
attempt. The seller's wallet no longer satisfies `balanceOf > 0`;
the buyer's now does. No re-wrapping, no foundation involvement,
no seller cooperation required.

The threshold-release primitive is substrate-independent: any
threshold-decryption network that can evaluate a Polygon Access
Control Condition and return decryption shares can serve it. LMAP's
production access layer is **native** — the same federated framework
that issues compliant-tier attestation credentials (§7.3) operates
and progressively decentralizes the threshold network, so no single
external service stands between a holder and content they own. Where
a mature external threshold network is used as an interim substrate
during bring-up, it is exactly that: a swappable bridge behind a
stable interface, never a dependency the protocol's guarantees rest
on. The protocol's rule is that the access layer must not be
rentable from, or revocable by, any party outside the federated
framework.

**What the open tier provides honestly.** Threshold-mediated key
release is *access control*: it gates which wallets can obtain a
decryption key. It cannot prevent a legitimate holder, once they
hold the key and the bytes, from saving plaintext to disk, capturing
the screen, recording the HDMI output, or otherwise creating an
unauthorized copy of content they legitimately decrypted. Defense
against that case rests on social incentive, the ease of legitimate
purchase, the alignment of buyers with creators, forensic
watermarking (§7.5), and — where licensing contracts demand it —
the compliant tier (§7.2). The open tier is approximately
DVD-level protection at the playback edge: cryptographic
enforcement of access; honest acknowledgment that the analog hole
and post-decryption copy are not prevented.

### 7.2 Compliant Tier {-}

Studios and rights holders who require contractual digital-rights
management cannot use the open tier as-is. The compliant tier
provides hardware-attested per-device key wrapping for content where
this is required.

In the compliant tier:

- Each compliant Seed holds a per-device keypair generated inside its
  hardware secure element. The private key is non-extractable.
- Content keys are wrapped to each compliant Seed's public key.
  Compromising one compliant Seed yields *that Seed's local content
  only* — a constant per-compromise bound with no catalog-scale
  master secret. (Precisely: per-compromise yield does not grow with
  network size; per-title leak probability does grow with holder
  count, bounded by watermark attribution and revocation, not
  cryptography — §7.4.)
- Wrapped keys are unwrapped only inside the secure element. The
  unwrapped key never appears in main memory or on persistent storage
  outside the secure perimeter.
- Issuance of a wrapped key requires the Seed to present a fresh
  *attestation report* signed by its secure element, containing
  current firmware measurements. The report is verified against the
  Seed's attestation credential before any wrapped key is issued.

Reference hardware for the compliant tier includes ARM
TrustZone [^12]-capable SoCs with discrete secure elements (e.g.,
NXP SE050 or equivalent), or platforms with TPM 2.0 [^4] support.
Remote attestation [^5] follows established patterns from
contemporary trusted-computing literature. The key hierarchy is precise: each title has an **independently
random** master key — there is no catalog-wide master (that would be
the class break §7.4 relies on not existing). Within a title, HKDF
with domain separation [^11] derives per-asset and per-rendition
subkeys, so keys are never reused across assets or titles. Where a
title carries multiple **rights tiers** (§4), each tier's asset is
keyed and protected *independently*, under its own access condition
(`balanceOf(:userAddress, :tokenId) ≥ threshold_T`), such that
obtaining a lower tier's key never derives a higher tier's; the exact
construction is fixed in the forthcoming technical specification.

**Hardware binding is a normative requirement of the compliant tier.**
A compliant compliant-tier implementation MUST use a hardware secure
element to (a) generate the per-device keypair, (b) hold the private
key in non-extractable form, (c) perform key unwrapping, and (d) sign
attestation reports. An implementation that performs any of these
operations outside a hardware secure element is not conformant with
LMAP V6 and MUST NOT be marketed as such. This is the protocol-level
guarantee studios rely on when authorizing content for the compliant
tier. Wire-level specifics of the attestation report format, the
attestation credential schema, and the issuer federation protocol are
committed to a separate LMAP V6 technical specification, forthcoming.

A clarifying distinction: only the *decryption* step requires
compliant hardware. Encrypted compliant-tier content is freely
distributable through the same content-addressed substrate as
open-tier content — any device can hold, pin, or serve it. Tokens
remain freely transferable across all wallets. The compliant tier
gates *playback*, not *carriage*. This preserves user sovereignty (a
buyer's ownership is unaffected by hardware availability; they can
transfer their token at any time) while satisfying the studio
requirement (decryption is impossible without an attested secure
element). The architectural model mirrors theatrical distribution
under DCI: the encrypted DCP is portable and freely distributable;
only certified projectors with KDM-bound keys can play.

**One active copy: binding, release, and free exchange.** Per-device
wrapping gives the compliant tier a property the open tier does not
have — enforceable scarcity, furnished as a *tool* rather than imposed
as a lock. A wrapped key is *bound* to one secure element at a time.
Because the entitling token is a *fungible* ERC-1155 unit, there is no
distinguishable "the token" to flag; binding is tracked instead as a
**count per `(wallet, tokenId)`** — `boundCount` — under the invariant
`boundCount ≤ balance`, so a wallet's transferable units are
`balance − boundCount`. This count lives in an **on-chain binding
registry from launch**: a separate, world-readable accounting
contract, so any platform, wallet, or prospective buyer can verify a
unit's released status without trusting a private ledger. **Only a
compliant player can set the flag.** A bind or release is recorded
only when it carries a valid, non-revoked compliant-device
attestation authorizing that specific operation, together with the
owner's wallet signature; the registry contract enforces
`boundCount ≤ balance` at write time by reading the token's on-chain
balance. No central issuer writes the flag — the attested fleet does,
from launch — so no single party can withhold a release. The only
non-device writer is the wallet owner, who may force a recovery-release
after the report window (wallet-authoritative; a device can never veto
its owner). The issuer's remaining role is confined to *key
wrapping* — enabling decryption at first bind — which is separate from
flag state and decentralizes on its own path (§7.3). The entitling
token remains a plain ERC-1155 throughout, and the registry is a
distinct contract that never touches the token's transfers, so tokens
minted at launch carry forward unchanged.

**The registry informs; it never gates.** The entitling token
transfers freely on-chain at all times — a gift, an inheritance, or a
direct peer sale needs no one's permission — and the protocol does not
let the issuer, or any party, block the exchange of an owned token.
That is the boundary the protocol will not cross. Safe trade is then
built on the tool by choice: to sell without residual a holder
*releases* a unit (the bound device deletes its wrapped key and
attests it; `boundCount` decrements); an escrow contract can settle a
sale atomically against the registry, so a buyer transacting through
it never pays for a still-bound unit; and a platform may list only
released units, or surface a `bound` warning on the rest. These are
platform policies resting on a protocol-furnished flag — where the
protocol sets down and platforms pick up (§15). The protocol supplies
the tools for coordination and honest disclosure; it lets the market
decide where to use them.

A bound copy plays indefinitely offline; the binding is recorded,
never re-verified, so playback never contacts the network. If a
bound device is lost, sold, or destroyed, playback
of its already-bound content is unaffected (it fails open) and the
token's transferability is recovered by an owner-signed **report**
that releases the titles after a 30-day window — **no heartbeat or
presence beacon**; the device verifiably erases the released titles
as a precondition of its next transaction, and a refusing device is
revoked. This yields one-copy-per-token scarcity *for trade conducted
through honest platforms and escrow*, with no continuous ownership
check — enforcement only at the discrete moments of binding and
release. Two residuals remain, both bounded, forensically watermarked
(§7.5), and harmless to a buyer's guarantee of a working title: a
compromised device that reports `released` while retaining its copy;
and — because raw transfer always works — a still-bound unit moved
outside an escrowed sale, which the registry surfaces as
`boundCount > balance` for that wallet. These are the physical-media-
tier cost of preserving free exchange, priced in rather than designed
out.

### 7.3 Attestation Issuers and the Federated Framework {-}

Attestation credentials in the compliant tier are signed by
independent *attestation issuers*. An issuer is a party that verifies
a Seed's hardware integrity and signs a credential binding the
device's public key to a manifest of approved firmware measurements.
Issuers in turn operate under a federated *attestation framework*
governed by the Liquid Media Foundation (see §15).

No single issuer can unilaterally approve or deny attestation; the
framework's governance can revoke any issuer whose practices fail
audit. Studios negotiate with the framework, not with a single
platform operator. The model is structurally analogous to the
federation of certificate authorities that underpins the public web's
TLS infrastructure: independent issuers, audited practices, root
trust managed by a body distinct from any commercial participant.

The framework launches with a single issuer (the Liquid Media Foundation
itself) and a public commitment to federate at a defined milestone
of network maturity. Federation is therefore a visible commitment,
not an indefinite promise.

### 7.4 What Each Tier Provides — Access Control vs. Endpoint Protection {-}

A precise statement of what each tier achieves, kept honest because
the two tiers solve different problems and should not be confused
on the same axis.

**Open tier (threshold-mediated key release).** This is *access
control*. Threshold release correctly enforces that a wallet can
obtain a decryption key only while that wallet currently holds the
relevant token. Transfers cause access to move with the token; the
seller's next decryption attempt fails the on-chain check; the
buyer's succeeds. The protocol's rule is that no single party — not
the foundation, not Wylloh, not the protocol's own contracts — may
release a key to a wallet that does not currently satisfy the access
condition. At maturity this rule is enforced directly by a distributed
substrate of cryptographic nodes native to the protocol, with no
single party able to break it; during bootstrap a single Foundation
issuer performs the release under that same rule, a temporary
centralization the decentralization roadmap (§7.3) dissolves. In
neither case does issuer or network liveness gate the *playback* of
content a holder already possesses (§8) — only first release and
transfer. **What threshold release does not do:**
it does not, and no software-only mechanism can, prevent a legitimate
holder from capturing or copying the plaintext stream once they
have legitimately decrypted it. That is the analog hole and the
post-decryption copy. Threshold release does not address those
threats — and we do not claim that it does.

**Compliant tier (attested per-device key wrapping — the binding
model).** This adds *endpoint protection* on top of ownership-gated
access, and is the mechanism the flagship launch is built on (§7.2).
Both are provided together by binding: the issuer verifies current
ownership and the device's attestation, then wraps the master key to
the device's secure element. Crucially, the compliant player is a
**sealed direct player** that renders and outputs video itself
(§9) — the decrypted stream is confined to a protected media path to
the player's *own* HDCP-protected output and is never streamed in the
clear to a separate device. Key custody and attestation live in a
hardware secure element; the bulk media decrypt runs in a protected
media pipeline (a TEE) inside the same sealed perimeter, so the raw
key and decoded frames never leave that perimeter. This constrains
what the device does with the stream *against the device's own
owner* — what licensing contracts for premium content require.

**On parity with commercial DRM — stated carefully.** Hardware-
attested endpoint protection is the category that also includes
Widevine L1, PlayReady, and FairPlay. LMAP's compliant tier belongs
to that category by construction, but the protocol does **not** claim
measured robustness *parity* with those specific systems, which rest
on SoC-integrated secure-video paths, protected memory, and certified
provisioning refined over many years. Parity is a property to be
*earned* through a published robustness specification and independent
review (a forthcoming LMAP V6 deliverable, §7.2), not asserted. Until
then the honest claim is narrower and still substantial: a sealed
direct player with a hardware secure element, a protected media path,
and attested output — materially stronger than software-only access
control, and scoped to the independent and boutique premium content
the launch serves.

**These are not equivalent [access vs. endpoint].** They solve
different threat models: threshold release gates *who gets the key*;
the compliant tier's sealed player additionally gates *what the
device does with the key*. They are not substitutes. Threshold
release at the open tier is honest and sufficient for indie,
public-domain, Creative Commons, and creator-opt-in content, where
extraction at the playback edge is acceptable defense resting on
social incentive plus watermarking. For content whose licensing
demands endpoint protection, the compliant tier — a sealed direct
player — provides it.

**A modest supplementary claim — threshold dispersal of ciphertext
(storage layer).** Sharding ciphertext across Seeds raises the
per-shard extraction cost. An attacker compromising one Seed
obtains a fraction of the ciphertext for any given film;
reconstruction requires reaching the quorum threshold. This is
real but bounded: a sufficiently motivated attacker can target
enough Seeds to reach quorum. Threshold dispersal provides
resilience and modestly raises extraction cost; it is not a
load-bearing security claim.

### 7.5 Watermarking {-}

Forensic watermarking binds a leak to a specific wallet, raising the
cost of unauthorized distribution beyond the bare cryptographic
extraction cost. Where it is used, the insertion locus differs by
tier, and robustness is not yet established — so claims elsewhere in
this paper that lean on watermark attribution ("bounded,"
"traceable," "attributable") are **conditional** on integrating a
scheme with independently measured robustness, not asserted as already
delivered.

**Compliant tier.** Watermarking inserts in the **protected media
path** — the TEE media pipeline (§7.4), at decode time, before any
frame reaches an output — *not* in the discrete secure element, which
holds keys and can neither bus nor decode video. Each playback binds
the holder's identity to the frames within the sealed perimeter.
Transcoding-robust marking requires commercial watermarking IP (e.g.,
Verimatrix, NAGRA, Irdeto); until such a scheme is integrated and
independently measured, the attribution-based residual bounds of
§7.2 remain conditional.

**Open tier.** The open tier does **not** rest its defense on
watermarking. Per-user marking collides with content addressing —
per-wallet bytes mean per-wallet CIDs, which breaks the
byte-identical-CID guarantee and the shared-swarm distribution model
and reintroduces a per-download central serving path; client-side
insertion is in any case unenforceable in a tier that welcomes
arbitrary third-party clients. The open tier instead accepts
playback-edge permeability by design (§7.4) and relies on social
incentive, easy legitimate purchase, and creator alignment. A
content-addressing-compatible open-tier mark (e.g., segment-level
side-channel marks) is an open research item, not a v1 dependency.

The protocol specifies watermark *insertion points* but mandates no
particular scheme; commercial implementations with established studio
relationships exist, and robustness against transcoding and
adversarial filtering remains an ongoing research area.

*Implementation status:* chunked AES-256-GCM encryption and IPFS
storage are shipped on Polygon mainnet via the V4.1 registry.
*The Cocoanuts* (1929, public domain) was tokenized and decrypted
end-to-end across two independent architectures (macOS arm64,
Raspberry Pi aarch64) using the legacy deterministic key-derivation
construction. The **compliant tier** — attested per-device binding on the sealed
direct player (§7.2) — is the launch access-control mechanism for
commercial content, consistent with a Seed-gated first release. Its
wire-level attestation specification, conformance suite, and the
Foundation's first (single) issuer are the highest-priority near-term
deliverables of the launch build; hardware binding is declared
normative (§7.2). **Native threshold-mediated key release** serves the
open (no-hardware) tier and is in active migration off the retired
deterministic construction in the Wylloh reference implementation; the
native, fully-decentralized threshold network — and the
decentralization of the compliant-tier issuer from single → federated
→ threshold — is the longer-horizon endgame (§7.3).

## 8. Permanence Guarantees {-}

The protocol commits to a permanence guarantee in both tiers: a
Seed that has legitimately acquired a license to a film at any
point in time retains the ability to play that film indefinitely,
regardless of subsequent network availability, attestation revocation,
or platform fate.

In the open tier, this guarantee is engineered through three
mechanisms operating in combination. First, after a client has
successfully decrypted a film once via threshold-mediated key
release, the master key is cached locally — in the browser's
persistent storage, the Seed daemon's encrypted local storage, or
any conformant client implementation's local persistence. Subsequent
playback of the same film does not contact the threshold network;
the client decrypts directly from local state. Second, holders may
export their master keys as user-encrypted backups — wrapped with
a passphrase the holder chooses, written to any storage the holder
controls. A backup file plus the downloaded encrypted bytes plus
the user's passphrase enables playback in perpetuity, even if all
foundation and threshold-network infrastructure ceases to exist.
Third, the ownership record on the chain remains the durable source
of truth; a holder who has lost both local cache and backup can
re-acquire access through any conformant implementation of the
protocol that still operates against the chain, because the
wallet's holdings are recoverable from public data.

For the legacy V4.1 deployment of public-domain content under the
deterministic key-derivation construction (§7.1), permanence is
even more direct: the decryption key for any owned film is
derivable from public on-chain data using the documented formula.
A Seed unplugged for twenty years and plugged back in can play any
*Cocoanuts*-era token it previously legitimately acquired, with
zero network connectivity, using a reference client a third party
authored from the public protocol specification. This property is
the one the original deterministic construction was articulated to
preserve; we keep it for the public-domain tokens that depend on
it, while threshold release supersedes the construction for new
content.

The canonical claim, stated precisely: *downloaded films play
forever offline; only re-download, first-bind, and transfer require
the access layer to be live — at maturity with no single-company
point of failure, and during bootstrap gated by a single foundation
issuer whose liveness affects transfer and acquisition, never
playback of what a holder already possesses.*

In the compliant tier, this guarantee is engineered. Attestation
gates the *issuance* of wrapped keys, not the *playback* of content
already keyed. A Seed whose attestation credential is later revoked
retains the wrapped keys it previously received and continues to
play the corresponding films. Revocation prevents the Seed from
acquiring further content through the compliant tier; it does not
retroactively disable the Seed's existing library. This is the
architectural answer to the rugpull pattern that has characterized
streaming services and digital media stores.

The hardware itself remains a single point of failure: a Seed whose
secure element fails physically loses access to its locally-wrapped
keys. The protocol mitigates this by treating the on-chain ownership
record as the durable source of truth. A user whose Seed has died
can re-acquire wrapped keys for their owned films onto a new
compliant Seed, because the wallet's holdings are recoverable from
the blockchain. **The blockchain remembers; the hardware is
replaceable.** This is a stronger guarantee than physical media,
which has no equivalent recovery path when a disc fails.

## 9. The Seed Network {-}

Content distribution operates through *Seeds* — user-operated nodes
that combine encrypted-content storage, peer-to-peer participation,
and playback. Seeds run on commodity hardware following published
reference designs.

A Seed is a **sealed direct player**: it connects to the television
and renders and outputs video itself, so that compliant-tier content
is decrypted and displayed entirely within one sealed device — the
only place endpoint protection (§7.4) is coherent. Decryption happens
inside the player's secure element and protected media path, and
plaintext never crosses the network. The reference design is a
fanless, small-form-factor player with a custom case and CEC so the
television's own remote drives it. Earlier designs explored a
*headless* Seed that served decrypted video to thin clients (Roku,
Apple TV, iOS) on the home network; that model reaches devices users
already own but forfeits endpoint protection at the client hop, so it
is retained only as a **secondary mode for open-tier content** —
never the path for compliant-tier premium content, which plays on the
sealed player alone. (Streaming to a personal device from one's
*own* Seed is a convenience feature layered on the same footing:
available for open-tier content, out of scope for the compliant
tier's guarantees.)

Each Seed stores content its operator owns, plus optionally
contributes overflow capacity to the network. Popular films
accumulate across more Seeds as more users own tokens; niche content
maintains availability proportional to its audience. No central
coordination determines what Seeds store; ownership patterns drive
distribution.

This architecture inverts conventional streaming economics.
Centralized platforms bear infrastructure costs proportional to
viewership: success is expensive. In the Seed network, increased
viewership means more Seeds joining, distributing load across more
nodes. Per-stream costs approach zero as the network grows. The
system becomes more efficient at scale rather than more costly.
Seeds participate by default because their primary value to the
operator is local — the films they own, accessible to
LMAP-compatible playback clients on their local network — so
network participation is a beneficial side effect rather than the
purchase rationale. This is precisely the property that
distinguishes a Seed from the token-incentivized storage networks
whose hardware had no standalone value (§16).

A reference Seed device — the *Origin* — is specified separately
from this paper as a buildable open-hardware design. The protocol
does not require the Origin or any particular Seed implementation;
any conformant device can participate.

*Implementation status:* an open-source reference Seed daemon is
operational. It verifies wallet ownership directly against the
on-chain registry, fetches encrypted content from IPFS (preferring a
co-resident Kubo node where present, falling back to public
gateways), decrypts streaming with constant memory, automatically
pins the source CID to make the Seed a provider for the content it
holds, and exposes a long-running HTTP service with mDNS
auto-discovery and HTTP byte-range streaming for LAN client
applications. End-to-end operation has been demonstrated on
independent ARM64 hardware (Raspberry Pi 4), with byte-identical
decrypted output across architectures and with no dependency on any
centralized service. The reference *Origin* device is in
pre-production. The web client at wylloh.com serves as the first
reference application.

## 10. Marketplace Mechanics {-}

The protocol includes integrated marketplace functionality. Primary
sales occur through minting at prices set by the title's author.
Secondary sales enable peer-to-peer trading with automatic royalty
distribution on each transaction.

### 10.1 Three-Way Revenue Split {-}

Every primary sale routed through the protocol distributes payment
across three parties, with proportions set per title at mint time:

- **Protocol fee: 2.5%** (immutable, hardcoded at the contract level).
  Flows to the Liquid Media Foundation treasury for shared
  infrastructure: IPFS pinning redundancy, contract auditing,
  security work, open-source maintenance.

- **Publisher fee: 0–25%** (set per title, immutable for that title).
  Flows to the publisher — the wallet that minted the title.
  Publishers are entities that bring works to market: established
  storefronts, indie collectives, or self-publishing authors. Their
  cut compensates curation, marketing, audience development, and
  brand value.

- **Author share: remainder.** Flows to the author — the credited
  creator(s). Distributed via an optional royalty shareholders
  configuration (§10.3) supporting up to 50 collaborators per title.

For a typical configuration — 10% publisher fee — the split is
2.5% / 10% / 87.5%. Authors receive dramatically better economics
than traditional publishers (where author shares of 10–20% are
common). The protocol's 25% publisher cap is the only opinionated
stance: *publishing on LMAP shall not become as extractive as the
systems it replaces*.

### 10.2 Publisher and Author as Distinct Roles {-}

The protocol records two distinct identities per title:

- **Publisher** is set automatically from the wallet that calls the
  mint function. Cryptographically authentic — cannot be impersonated.
  Establishes the brand identity associated with the title and
  receives the publisher fee on primary sales.

- **Author** is provided at mint and identifies the credited creator
  of the work. Receives the author share of every primary and
  secondary sale.

The two roles are often the same wallet (an author who self-publishes)
but can differ (a publisher mints under their brand and routes the
author share to a separate creator wallet). This mirrors the
publishing-house / author distinction familiar from books, films,
and music.

### 10.3 Royalty Shareholders {-}

Authors can configure up to 50 royalty shareholders per title, each
receiving a configurable percentage of the author's share. This
supports the realistic case where a tokenized work has multiple
contributors deserving compensation: a film with director, lead
actors, composer, screenwriter; a video game with developers,
artists, and key team members; an album with songwriter, performers,
and producer.

Shareholders are mutable by the author, allowing collaborators to be
added or adjusted as the work evolves. Sum of shares can be ≤ 100%
of the author's share; any remainder flows to the author wallet,
preserving the author as the residual recipient. For projects with
more than 50 beneficiaries, shareholders compose with external
splitter contracts (e.g., 0xSplits): one shareholder slot can route
to a splitter address that distributes further.

Distribution happens automatically on every protocol-routed sale —
both primary and secondary. No manual royalty disbursement, no
escrow, no off-chain ledger reconciliation.

### 10.4 Royalty Enforcement Boundary {-}

The protocol enforces royalties cryptographically for sales routed
through its marketplace functions. External marketplaces honoring
the ERC-2981 royalty standard will respect the configured royalty
when displaying and processing sales. Direct wallet-to-wallet
transfers (the gift, inheritance, and personal-give use cases) do
not trigger royalties — this is a property of the underlying
ERC-1155 standard and a deliberate preservation of token-as-property
semantics.

Off-chain payment with on-chain gift is theoretically possible and
unenforceable cryptographically, as with every royalty-bearing
token system. The protocol's mitigation is structural: the low
2.5% protocol fee minimizes the savings from circumvention; the
integrated marketplace makes legitimate sales easier than
coordination; on-chain transparency makes wash-trade patterns
visible and reputationally costly.

### 10.5 Bulk Acquisition for Rights Stacking {-}

The marketplace supports atomic batch purchases (`batchBuyListings`),
enabling a single transaction to acquire tokens from many sellers
simultaneously. This is essential for the rights-stacking use case
(§11): a buyer assembling tokens to meet a theatrical-exhibition
threshold may need to acquire thousands of tokens from hundreds of
sellers in a single coordinated purchase. The atomic semantics
guarantee all-or-nothing: if any listing in the batch fails, the
entire transaction reverts, preventing the partial-fill case where
a buyer pays fees but doesn't reach their target threshold.

Platform UIs aggregate, sort, and present available listings; the
protocol provides the batch-execution primitive.

### 10.6 The Protocol Fee Is Not a Platform Fee {-}

The 2.5% protocol fee supports shared infrastructure all
implementations depend on, identical across every LMAP-compatible
marketplace. Third-party marketplaces may layer their own commercial
markup on top, competing on user experience, curation, and discovery
rather than by undercutting the protocol fee. This places third-party
marketplaces and the reference web client at wylloh.com in a peer
relationship with one another, not a competitive one.

### 10.7 Settlement and Gas Abstraction {-}

Transactions settle in stablecoin to insulate buyers from
cryptocurrency volatility. The current implementation uses USDC.e
(bridged USDC) on Polygon. Settlement on Polygon means that buyers
must currently hold both USDC.e and a small amount of POL to
cover network gas — friction the protocol acknowledges as a
near-term limitation rather than an intended feature. The
architectural answer is account abstraction via ERC-4337 [^6]
*paymaster contracts*: a paymaster pays POL gas on the user's
behalf, recovering the cost via a small USDC surcharge bundled into
the transaction. The reference contract V5 exposes paymaster hooks
allowing a paymaster contract to be wired in by foundation
governance. Paymasters are deployed and funded at the marketplace
layer; each marketplace can choose whether and how to subsidize gas
as part of its commercial offering.

*Implementation status:* primary sales with three-way distribution,
secondary sales with royalty enforcement, royalty shareholder
distribution, batch acquisition, and the protocol fee are
specified in the V5 reference contract. The V5 contract is in
active development; deployment under foundation governance is a
2026 milestone. The legacy V4.1 registry remains in operation for
existing tokens (open-tier only, two-way author/protocol split)
during the transition.

## 11. Commercial Rights Discovery {-}

The stacking mechanism enables a novel form of commercial rights
acquisition. Consider a film that achieves cult status: tokens are
distributed across thousands of fans who purchased during initial
release. A theater chain wishes to conduct a theatrical run, requiring
tokens above the exhibition threshold the filmmaker configured for
that title.

Rather than negotiating with the original filmmaker, the theater
acquires tokens directly from fans through open market purchases.
As buy pressure increases, token prices rise, rewarding early
believers who funded the film's success. Royalties trigger on each
transfer, flowing to the copyright holder regardless of who sells.
The market determines that theatrical rights to this particular film,
at this particular moment, command a specific price — no negotiation
required.

Commercial exhibition requires tokens to be staked for the exhibition
period. The professional distribution system verifies on-chain that
staked tokens meet the exhibition threshold before enabling playback.
This prevents the exploitation pattern of acquiring tokens, screening
content, and immediately selling. Staking creates commitment aligned
with legitimate commercial use.

*Implementation status:* design intent. Stacking thresholds are
operational at the contract level today; the staking mechanism for
commercial-exhibition windows is specified for a future protocol
version.

## 12. Production Funding {-}

The token architecture enables presale-based production financing.
Rather than relying on studio executives or platform algorithms to
greenlight projects, creators can presell tokens directly to
audiences. This validates market demand before production begins
while distributing ownership of the work directly to its audience.

Presale tokens grant the same ownership rights as post-release tokens
but are purchased at a discount, rewarding early supporters. Smart
contracts can structure milestone-based fund
releases with multi-signature approval from stakeholder
representatives. If production fails to meet milestones, remaining
funds return to presale participants.

This model removes centralized gatekeepers from greenlighting
decisions. A film need not fit a platform's content strategy. If
sufficient audience interest exists to fund production, the project
proceeds. The presale serves simultaneously as market research,
financing mechanism, and community-building exercise.

*Implementation status:* design intent. The token architecture
supports presales architecturally; the milestone-based escrow
contracts and the corresponding presale-tokenization workflow are
specified for a future protocol version.

## 13. Privacy {-}

Contemporary streaming platforms extract extensive personal data to
drive recommendation algorithms and advertising. The protocol
operates on a different principle: *movies should not watch their
viewers*. Analytics derive exclusively from public blockchain
data — transaction patterns, token distribution, market activity —
rather than viewing behavior or personal information.

The conventional streaming model links user identity to viewing
history to platform to advertisers, forming a chain of surveillance
maintained primarily for monetization through inferred consumer
preferences. The protocol model maintains pseudonymous wallets
executing public transactions on a transparent ledger, with no link
to real-world identity, no telemetry from playback events, and no
viewing patterns aggregated by any party. This holds in the compliant
tier as well: a bound player contacts the network only at
owner-initiated transactions (register, bind, release, report),
never with an ambient presence signal, so recovery is
report-triggered rather than surveillance-detected. The issuer learns
*acquisition* events — which on-chain ownership already largely
reveals — but never *when* or *how often* a holder watches;
oblivious issuance, in which the issuer does not learn the title, is
a specified future privacy enhancement. Creators receive
aggregate insights — token distribution by region inferred from
public data, secondary-market activity, holder concentration —
without compromising individual privacy.

## 14. Security Philosophy {-}

The protocol does not attempt perfect copy protection. History
demonstrates that technological restrictions on digital media
inevitably fail while degrading legitimate user experience. Instead,
the system aligns incentives such that ownership provides value
beyond mere access — liquidity, permanence, community membership —
making legitimate acquisition the rational choice.

The analog hole — capture of content via camera or screen recording
during legitimate playback — remains possible. Watermarking is the
only mitigation, and watermark robustness against transcoding is an
ongoing arms race. The protocol does not claim immunity from this
class of attack; it claims that legitimate purchase confers economic
benefits that bare ciphertext extraction does not.

When content is owned not by a distant corporation but by potentially
many individual token holders, piracy dynamics shift. Unauthorized
distribution harms not an abstract studio but a community of fellow
enthusiasts. Token holders own copies of the work itself, aligning
their interest with its integrity rather than its piracy.
Social contracts, properly constructed, provide stronger protection
than technological locks against the casual case; threshold-mediated
key release provides honest cryptographic access control against the
non-holder case; and the compliant tier provides hardware-attested
endpoint protection against the case where licensing contracts
require it. These mechanisms address different threat models, and
the whitepaper is precise about the distinction: threshold release
gates *who gets the key*; hardware attestation in the compliant tier
gates *what the device does with the key during playback*. The two
are complementary in the compliant tier; threshold release alone is
sufficient and honest for the open tier.

Physical media operated on similar principles. Copy protection on
optical discs was trivially circumvented, yet the market thrived
for decades. Convenience, quality assurance, and social norms around
ownership provided sufficient protection. The protocol adds
financial incentives physical media lacked: ownership appreciates
in genuinely successful work, and secondary markets reward early
adoption.

A specific guidance for technical readers: when evaluating the
protocol's claims, separate three distinct claims that should not
be conflated. (1) The *access-control claim*: threshold-mediated
key release correctly gates decryption by current on-chain
ownership. At maturity it is evaluated by a distributed network of
cryptographic nodes with no single party able to release a key to a
non-holder; during bootstrap a single Foundation issuer performs the
release under that same rule (§7.3), its liveness affecting transfer
and first release, never playback of content already held. (2) The *endpoint-protection claim*: hardware-attested
per-device key wrapping at the compliant tier constrains what the
playback device can do with the decrypted stream, addressing the
legitimate-viewer-attempting-capture threat that no software-only
mechanism can address. (3) The *operational claim*: legitimate
purchase is more economically rational than extraction for
participants aligned with creators. Each claim holds at its own
layer under its own threat model. The whitepaper is precise about
this because the audiences this document serves — investors,
developers, studio business affairs — read the same words and need
to extract the same meaning. The protocol does not claim that
threshold-mediated release is equivalent to or stronger than
hardware-attested DRM; the two solve different problems. The
protocol claims that threshold release is honest access control,
that hardware attestation is the right capability where endpoint
protection is contractually required, and that the combination of
ownership, transferability, permanence, and platform independence
delivered to collectors is a categorically different — and, for
this audience, better — set of properties than streaming or
account-locked stores provide.

## 15. Governance and the Liquid Media Foundation {-}

The protocol is governed by an independent foundation, structurally
distinct from any commercial operator. The foundation holds the
protocol's intellectual property under a permissive open-source
license, stewards the compliant-tier attestation framework,
publishes the protocol specification, and operates as a
protocol-neutral standards body.

Commercial entities that build on the protocol — storefronts,
hardware manufacturers, marketplace operators — are participants in
the LMAP ecosystem rather than its operators. This structural
separation mirrors precedents in adjacent ecosystems: the Filecoin
protocol governed by the Filecoin Foundation, structurally distinct
from Protocol Labs; the Ethereum protocol governed independently
from any single Ethereum company. The pattern preserves
credible-neutrality: filmmakers, third-party storefronts, hardware
manufacturers, and eventually studios can build on the protocol
without fearing that the protocol's stewards are also their
commercial competitors.

The foundation, at its mature governance, will steward:

- **Specification governance.** Protocol upgrades, EIP-equivalent
  proposals, and version transitions.
- **The attestation framework.** Maintaining the federation of
  attestation issuers, audit standards, and revocation governance for
  the compliant tier (§7.3).
- **Treasury.** Custody of the protocol fee revenue, application to
  shared infrastructure costs, and grants to ecosystem development.
- **Token-holder governance.** Per-title decisions (royalty splits,
  rights-tier amendments, supply changes) where applicable.

A pragmatic note about the present: the foundation does not yet
exist as a formal legal entity. The current governance posture is
that of a stewarded bootstrap, in which the founding team operates
the protocol on the implicit promise of formalizing the foundation
and transitioning to community governance over a multi-year arc.
This is a commitment, not a fact, and the protocol's roadmap
includes the foundation's formal establishment, the attestation
framework's first audit milestones, and the public sunset of any
admin keys held by the founding team.

**Curation: gateless, not absent.** The protocol layer is
permissionless — any wallet can mint a title (V5 onward). Curation
happens at the application and registry layers, not at the protocol.
Three signals work together:

1. **Cryptographic identity at mint.** The wallet that mints a
   title is recorded as the publisher, on-chain, immutably. Brand
   identity is wallet-bound and cannot be impersonated.

2. **Foundation-maintained verified publishers registry.** The
   Liquid Media Foundation publishes a curated list of verified
   publishers at `lmap.org/publishers.json`. Verification signals
   quality and accountability without restricting the protocol;
   unverified publishers can still mint, but won't appear in
   verified-only application views.

3. **Application-layer editorial choice.** Each platform built on
   LMAP applies its own filter: the Wylloh storefront shows titles
   from Wylloh and other respected publishers; an indie aggregator
   might show all unverified content; a music-focused platform
   filters by `mediaType: music` and music-publisher wallets. The
   protocol exposes the truth (who minted what); applications
   shape the experience.

This model — *permissionless protocol, curated applications* —
mirrors how DNS works: anyone can register a domain, but
resolvers, browsers, and search engines each apply their own
filters. Quality emerges economically rather than by gatekeeping.
A publisher with poor taste mints work nobody buys; a publisher
with good taste accumulates verified status and earns the
publisher fee from real demand.

The legacy V4.1 registry retains its `FILM_CREATOR_ROLE` gate as
the editorial mechanism for the open-tier-only deployment serving
already-minted titles. New tokenizations under V5 land in the
permissionless model.

*Implementation status:* the foundation is in formation
(incorporation as a 501(c)(6) trade association is a funded
milestone of the upcoming raise); V5's permissionless minting is
specified and implemented in the reference contract scaffold;
deployment under foundation governance is a 2026 milestone; the
verified publishers registry will launch concurrently with V5
deployment.

## 16. Comparison with Prior Work {-}

LMAP inherits ideas from several adjacent ecosystems and addresses
limitations specific to each.

**Centralized streaming services** (Netflix, Disney+, et al.) own
the relationship with audiences and bear infrastructure costs
proportional to viewership. They cannot offer durable digital
ownership because durable ownership conflicts with subscription
economics. LMAP inverts this by routing ownership through a
public ledger and distribution through a peer-to-peer network.

**Kaleidescape** ships hardware-backed ownership for theatrical-
quality content, but operates within a closed ecosystem at luxury
price points and serves a narrow demographic. LMAP shares the
philosophical commitment to genuine ownership but extends the
addressable audience by separating the protocol from any particular
hardware vendor and accepting standard 4K HDR streaming quality
rather than requiring lossless masters.

**Plex** demonstrates local, home-owned media at scale (over 25
million users), but with primarily user-ripped content of unclear
provenance, no rights or royalty flow, no curatorial focus, and a
closed-source business model. The Seed shares Plex's core virtue —
your library lives at home, not in a rented cloud — while differing
in form (a sealed direct player, not a headless server feeding
third-party clients) and in substance: on-chain provenance,
automatic royalties, and an open protocol anyone can implement.

**Filecoin** [^7] **and Helium** demonstrate decentralized-network
plays with token-incentive mechanisms. Both attracted speculative
participants more than utility-driven users, primarily because the
hardware in each case had no standalone consumer value. The
purchase rationale collapsed if the token economics did not deliver
expected returns. The reference Seed device — the Origin, built by
Wylloh as the first commercial implementation of LMAP — has a
primary consumer utility: the operator's film library, accessible
to LMAP-compatible playback clients on their local network. This
utility does not depend on any token-incentive mechanism.
Network participation is a beneficial side effect of a device that
operators would buy regardless. This sidesteps the chicken-and-egg
adoption problem that has limited prior decentralized-CDN plays.

**Bitcoin** [^10] **and Ethereum** [^8] establish the cryptographic
and economic primitives this protocol relies upon. The protocol's
contributions specific to film distribution are the dual-contract
architecture (§3), the modular rights-stacking mechanism (§4), the
two-tier access model (§7), the permanence guarantee (§8), and
the Seed-network distribution model (§9).

## 17. Conclusion {-}

We have proposed a protocol for film distribution addressing
fundamental misalignments in centralized streaming. By tokenizing
films into standardized units with embedded licensing rights, we
create genuine digital ownership. By distributing content through a
peer-to-peer network growing stronger with demand, we invert
economics that punish platforms for success. By automating royalty
distribution including on secondary sales, we ensure transparent
creator compensation through markets that never existed for physical
media.

The two-tier access model resolves the perceived conflict
between open-protocol architecture and contractual studio trust
requirements. The open tier gates access cryptographically through
threshold-mediated key release — honest access control that moves
with the token and depends on no single party — while accepting that
endpoint extraction is not prevented, the same posture physical media
took for decades. The compliant tier provides hardware-attested
per-device key wrapping for content where contractual DRM is required,
governed by a federated attestation framework structurally independent
from any commercial operator.

The separation of distribution tokens from copyright ownership
enables fluid rights markets while preserving creator control over
intellectual property. Commercial exhibitors can acquire rights
directly from collectors. Studios can acquire copyright for
derivative works without disrupting existing token markets. Rights
flow to natural owners through market mechanisms rather than
negotiated deals.

The protocol requires no permission from existing gatekeepers.
Public-domain content bootstraps the network, demonstrating
capabilities before commercial titles join. As the network grows,
established platforms face a choice: implement the protocol and
benefit from its efficiencies, or cede ground to peer marketplaces
and competitors that do.

LMAP represents not disruption but recoherence — using
peer-to-peer technology once deployed to undermine the industry to
instead restore fair compensation and sustainable economics. The
same distributed networks that enabled unauthorized copying can now
enable legitimate, liquid, permanent ownership. *In the venom, the
antidote.*

## Implementation Status Summary {-}

A precise summary of the protocol's components by their status as
of this paper's publication:

- **Shipped (legacy V4.1 deployment, scoped to public-domain
  content):** ERC-1155 distribution registry on Polygon mainnet at
  `0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D`; role-gated minting;
  modular rights stacking; chunked AES-256-GCM encryption; legacy
  deterministic key-derivation construction (§7.1) — retired as a
  production model and now scoped to public-domain demonstration
  content only; self-contained manifest reading from on-chain
  metadata + IPFS, with storage-service fallback; open-source
  reference Seed daemon (verify ownership, fetch + decrypt,
  auto-pin, LAN-stream over HTTP/mDNS); web client at wylloh.com;
  first tokenized film (*The Cocoanuts*, 1929, public domain) sold
  and downloaded end-to-end across two independent architectures
  (macOS arm64, Raspberry Pi aarch64) with byte-identical output.
  The V4.1 contract continues to serve existing tokens under the
  legacy construction.
- **In active migration (blocking commercial-content
  onboarding):** migration of the Wylloh reference web client and
  Seed daemon from the legacy derivable-key construction to
  native threshold-mediated key release.
  Completion of this migration is a prerequisite for tokenizing
  any commercial content; the V4.1 deployment continues to serve
  already-tokenized public-domain content under the legacy
  construction during and after the migration. The Wylloh
  reference implementation scopes the open-tier framing
  described in §7.1 as a deliberate brand position rather than as
  a tolerated limit — DRM-free post-decryption is disclosed as a
  field in standard listing terms and marketed as vinyl-grade
  ownership, with the social and economic incentives of legitimate
  acquisition treated as load-bearing product logic. That framing
  is implementation-level, not protocol-level; other compliant
  implementations may scope the open tier differently.
- **Specified, in active implementation (V5):** the LMAPRegistryV5
  reference contract for deployment on Polygon mainnet — adds the
  three-way revenue split (§10.1), publisher/author distinction
  (§10.2), royalty shareholder distribution (§10.3), atomic batch
  acquisition for rights stacking (§10.5), `mediaType` field for
  media-agnostic operation, updateable platform treasury via
  multi-sig timelock, ERC-4337 paymaster hooks, and permissionless
  minting (§15). Compatibility with threshold-mediated key release
  is the production access-control mechanism. Scaffold with
  passing tests; full marketplace implementation, comprehensive
  test coverage, and deployment under foundation governance are
  2026 milestones.
- **Specified, in implementation (hardware, clients, and the
  compliant tier):** the reference Seed device (the *Origin*), a
  sealed direct player; its native client applications for open-tier
  LAN streaming (Roku, Apple TV, iOS); and the **compliant-tier launch
  mechanism** — attested per-device binding (§7.2) with a single
  Foundation issuer. The wire-level attestation specification (report
  format, credential schema, revocation flow), the conformance suite,
  and the binding and marketplace-settlement flow are launch
  deliverables in active specification.
- **Specified, future protocol versions (V6+):** ERC-721 copyright
  registry; on-chain staking for commercial-exhibition windows;
  presale-funding milestone-escrow contracts; threshold dispersal of
  ciphertext shards; **federation of the attestation issuer and
  decentralization of the compliant-tier key service from single →
  federated → threshold** (§7.3). The on-chain binding registry (§7.2)
  is itself a launch component, written by the attested player fleet
  (no central flag-writer); the protocol adds no transfer-veto —
  exchange stays free by design.
- **Long-horizon (operational maturity required):** studio-grade
  compliant-tier engagement with major rights holders.

This paper is a working specification. Components shipped today
behave as described; components specified are commitments the
protocol is engineered toward. The Liquid Media Foundation, when
formally established, will maintain this status summary as a
living public artifact.

\vspace{1em}

## Changelog {-}

**Version 2.5 (July 2026).** Forward-ports the access-control
refinements settled after v2.4. (1) **The access layer is native.**
The threshold-release primitive is stated as substrate-independent
(§7.1); no specific external threshold network is named as the
production substrate. The protocol's rule is that the access layer
must not be rentable from, or revocable by, any party outside the
Foundation's federated framework; an external network may serve only
as a swappable interim bridge behind a stable interface. (2) **The
"certified tier" is renamed the "compliant tier"** throughout, naming
the tier by the open conformance standard a device meets rather than
by an authority's grant. (3) **A binding model is added to the
compliant tier (§7.2).** Per-device wrapping now tracks binding as a
`boundCount` per `(wallet, tokenId)`, recorded in an **on-chain,
world-readable binding registry from launch** — a separate accounting
contract written by the attested compliant-player fleet (only a
compliant device, authorized by the owner's wallet, can set the flag;
no central issuer writes it; the token stays a plain ERC-1155): a copy
binds to one secure element at a time, plays offline indefinitely, and
is *released* — the device deletes its wrapped key — before a unit
trades without residual. The registry *informs* rather than *gates*:
the token transfers freely on-chain at all times, the protocol lets no
party block exchange, and scarcity for safe trade comes from platforms
honoring the flag plus opt-in escrow that settles atomically against
it. An owner-signed
report releases a lost device's titles after a 30-day window (no
presence beacon), with transaction-gated erasure. This restores
one-copy-per-token scarcity for honest trade, and with it collectible
and resale value, without any continuous ownership check — resolving
the sovereignty-versus-scarcity tension in favor of both. Companion
documents (`PROTOCOL_LAYERS.md`, `PROTOCOL_POSITIONING.md`) are being
brought into alignment (a multi-pass rework in progress).

**Version 2.4 (June 2026).** Supersedes v3.0 (also June 2026)
following external architectural review. v3.0 attempted to add an
LMA protocol token, a dedicated Liquid Media Chain (Polygon CDK
zero-knowledge rollup), token-incentivized storage and threshold
networks, an offshore Cayman Foundation Company structured to issue
the token, and a three-year dependency-sunset roadmap. External
review identified this scope as disproportionate to the protocol's
actual use case: the protocol's value does not require a token
economy; Lit Protocol already provides the threshold-release
primitive without LMAP needing to build its own; the
Filecoin/Helium chicken-and-egg risks v3.0's §17 itself cited as
cautionary would have applied to LMAP's own token; and the
resulting securities exposure was premature overhead for a token
the architecture did not require. v3.0 also contained a category
error: claims that threshold cryptography provides security
"equivalent to or stronger than hardware-attested DRM." That claim
conflated access control (which threshold release provides —
gating who gets the key) with endpoint protection (which hardware
DRM provides — what the device does with the decrypted stream
during playback, against the device's own owner). The two solve
different threat models and are not directly comparable. v3.0 is
archived as superseded
(`whitepaper/archive/whitepaper-v3.0-superseded.{md,pdf}`).

v2.4 returns to the v2.3 baseline and forward-ports the substantive
cryptographic improvements that survive the review: (1) **§7.1
Open Tier rewritten** — the legacy deterministic key-derivation
construction is retired as a production model and scoped to
public-domain demonstration content (*The Cocoanuts*); threshold-
mediated key release via Lit Protocol's Naga mainnet becomes the
production access-control mechanism. (2) **§7.4 rewritten** as
"What Each Tier Provides — Access Control vs. Endpoint Protection";
the prior "Security That Scales with Network Size" framing is
retired in favor of an explicit statement that threshold release
and hardware DRM solve different threat models. (3) **§8
Permanence Guarantees expanded** with the local key cache,
self-wrapped backup export, and on-chain ownership recovery
mechanisms; the canonical claim *"downloaded films play forever
offline; re-download and transfer require the access network
(Lit) to be live; no single-company point of failure"* is now
stated explicitly. (4) **§14 Security Philosophy sharpened** to
distinguish the access-control claim, the endpoint-protection
claim, and the operational claim — three distinct claims that
should not be conflated. **The Implementation Status Summary** is
updated to reflect the Lit migration as the blocking near-term
engineering milestone and the legacy derivable-key construction
as retired-to-public-domain-scope. **The §16 comparison with prior
work** is unchanged; we explicitly do not build a Filecoin/Helium-
shaped token-incentive layer atop the same cautionary analysis.

A consistency pass harmonized the framing sections that the v2.3
baseline had carried forward unchanged — the abstract, the §5
layered-architecture table, the §7 section opener and title (now
"the Two-Tier Access Model"), the §9 Seed-incentive description, and
the §17 conclusion — with the threshold-release production model
described in §7.1 and §7.4. Those sections previously described the
retired derivable-key open tier as the protocol's production
mechanism and omitted threshold-mediated key release. Stale gas-token
naming (MATIC → POL) was corrected in §10.7.

The Wylloh Seed product line referenced in this document evolved
during May 2026 implementation work into two reference SKUs (Seed
One and Origin Seed); the conceptual reference Seed described in
§9 is unchanged in protocol terms, but readers should be aware
that the implementation now ships in two form factors. The
protocol/implementation distinction (LMAP as Apache-2.0 spec,
Wylloh as the first implementation) is unchanged.

**Version 2.3 (May 2026).** Reference Seed daemon promoted from
"specified" to "shipped" in the Implementation Status. §9
(Seed Network) updated to reflect end-to-end operation of the
open-source reference daemon on independent ARM64 hardware (Raspberry
Pi 4) with byte-identical decrypted output across architectures and
no dependency on any centralized service. The daemon's operating
behavior — IPFS fetch with local Kubo preference, automatic
content pinning to make the Seed a provider, LAN-streaming via
HTTP/mDNS with byte-range support — is documented as the
canonical reference behavior for compliant Seeds. §7.2 (Compliant
Tier) gains a normative statement: hardware binding (SE-resident
keypair generation, non-extractable private keys, in-SE key
unwrapping, in-SE attestation signing) is a MUST for V6
conformance, and an implementation omitting any of these operations
is not LMAP-V6-conformant and MUST NOT be marketed as such. A
clarifying paragraph distinguishes *playback* (which requires
compliant hardware) from *carriage* (which does not — tokens,
encrypted content, and pinning remain freely accessible across all
hardware), mirroring DCI theatrical distribution. Wire-level
attestation specifics (report format, credential schema, issuer
federation protocol, revocation flow) are deferred to a separate
LMAP V6 technical specification, forthcoming.

**Version 2.2 (May 2026).** V5 reference contract specification
additions. §10 (Marketplace Mechanics) substantially expanded to
specify the V5 economic model: three-way revenue split
(protocol 2.5% / publisher 0–25% / author remainder), distinct
publisher/author identities (publisher cryptographically authentic
via mint-time `msg.sender`), royalty shareholder distribution
supporting up to 50 collaborators per title, atomic batch
acquisition for rights stacking, and an honest articulation of
the royalty enforcement boundary (V5-marketplace sales enforce
cryptographically; direct ERC-1155 transfers preserve the gift /
inheritance use case). §15 (Governance) updated to reflect V5's
permissionless minting model — curation moves from a protocol-level
role gate to a three-signal application-layer model: cryptographic
publisher identity, a foundation-maintained verified publishers
registry at `lmap.org/publishers.json`, and individual platforms'
editorial choice. Implementation Status restructured to reflect
V4.1 (legacy, in operation) and V5 (in active implementation).

**Version 2.1 (May 2026).** Rebrand pass under Liquid Media
Foundation stewardship. The protocol — previously referred to
internally as "Wylloh" — is renamed *LMAP* (Liquid Media Access
Protocol) to formalize the separation between the open standard
(LMAP, stewarded by the foundation) and the first commercial
implementation (Wylloh, the company building the reference
hardware and storefront). Substantive technical content of v2.0 is
preserved unchanged. References to commercial-platform UX details
that exceed protocol scope have been generalized. A more
substantive v3.0 with deepened §15 (foundation governance) and
expanded §16 (comparison with prior work) is forthcoming.

**Version 2.0 (April 2026).** Comprehensive revision following the
April 2026 mainnet launch and the architectural pivot to the
headless-Seed network. Key additions: §5 (layered architecture),
§7 (two-tier attestation model with attestation issuers and the
federated framework), §8 (permanence guarantees), §15 (governance
and the foundation), §16 (comparison with prior work). The
cryptographic claims of v1's §6 have been rewritten in v2's §7 to
reflect the actual two-tier model rather than the
threshold-key-sharing scheme v1 described aspirationally. The
original V1 PDF is preserved in the project archive.

**Version 1.0 (April 2026).** Initial publication.

\vspace{1em}

## References {-}

[^1]: W. Radomski et al., "EIP-1155: Multi Token Standard,"
  Ethereum Improvement Proposals, 2018.

[^2]: W. Entriken et al., "EIP-721: Non-Fungible Token Standard,"
  Ethereum Improvement Proposals, 2018.

[^3]: J. Benet, "IPFS — Content Addressed, Versioned, P2P File
  System," arXiv:1407.3561, 2014.

[^4]: Trusted Computing Group, "TPM 2.0 Library Specification,"
  trustedcomputinggroup.org, current edition.

[^5]: H. Birkholz et al., "Remote ATtestation procedureS (RATS)
  Architecture," IETF RFC 9334, January 2023.

[^6]: V. Buterin et al., "ERC-4337: Account Abstraction Using
  Alt Mempool," Ethereum Improvement Proposals, 2021.

[^7]: Protocol Labs, "Filecoin: A Decentralized Storage Network,"
  filecoin.io technical specification.

[^8]: V. Buterin, "Ethereum: A Next-Generation Smart Contract and
  Decentralized Application Platform," 2014.

[^9]: A. Shamir, "How to Share a Secret," *Communications of the
  ACM*, vol. 22, no. 11, pp. 612–613, 1979.

[^10]: S. Nakamoto, "Bitcoin: A Peer-to-Peer Electronic Cash
  System," 2008.

[^11]: H. Krawczyk and P. Eronen, "HKDF: HMAC-based Extract-and-
  Expand Key Derivation Function," IETF RFC 5869, May 2010.

[^12]: ARM Limited, "ARM TrustZone Technology," developer.arm.com,
  current edition.
