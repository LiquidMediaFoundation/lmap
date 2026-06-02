<div class="titleblock">

# LMAP — Liquid Media Access Protocol {.title}

#### A Peer-to-Peer Protocol for Media Distribution and Ownership {.subtitle}

Harrison Kavanaugh  ·  contact\@liquidmediafoundation.org

*Version 3.0 — June 2026*

</div>

## Abstract {-}

A purely peer-to-peer protocol for film distribution would allow digital
media ownership to exist independently of any single platform, studio, or
streaming service. The current model of centralized streaming creates
fundamental misalignments: platforms bear infrastructure costs
proportional to viewership, creators receive opaque compensation, and
consumers own nothing permanent. We propose a layered protocol in which
each film exists as fungible tokens within a unified registry contract,
with separate provision for copyright ownership. Token quantity
determines usage rights — from personal viewing to theatrical exhibition
— at thresholds configured per title. Encrypted content is stored on a
content-addressed network and incentivized via an economic substrate
operated on a dedicated Layer-2 chain. Access to decryption material is
gated by current on-chain ownership at decryption time, evaluated by a
threshold cryptographic network with stake-based sybil resistance rather
than by any single party. We claim, and intend to demonstrate, that this
model provides security equivalent to or stronger than legacy
hardware-attested digital-rights management, on an open-protocol
substrate that the latter structurally cannot match. Forward-compatible
support for hardware-attested key wrapping exists in the protocol's
design for licensing relationships predicated on legacy industry
compliance frameworks; we expect those frameworks to evolve to recognize
threshold cryptography as equivalent or stronger security over time, and
the protocol's center of gravity is positioned accordingly. A network of
user-operated nodes — *Seeds* — distributes content, inverting the
conventional cost model: the network strengthens as viewership grows.
Smart contracts automate royalty distribution on every transaction,
including secondary sales where collectors can sell exhibition rights
directly. A single protocol token — *LMA* — coordinates storage
incentives, threshold-network participation, and protocol value capture
via emission to network operators and burn from protocol fees. The
protocol is governed by an independent foundation, structurally distinct
from any commercial operator. We argue that *liquid media* —
physical-grade ownership in liquid digital form — is achievable without
compromising the sovereignty that makes the design worthwhile.

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
content disappears. Unlike physical media, there is no true ownership —
only temporary access privileges revocable at the platform's discretion.

Creators face similar opacity. Residual payments flow through accounting
systems designed to obscure rather than illuminate. The shift from
theatrical and physical media sales to streaming has compressed
compensation without providing comparable transparency or participation
in secondary markets.

What is needed is a protocol-level solution addressing all
constituencies simultaneously — analogous to how DVD or USB function:
not as a platform a consumer signs up for, but as a *standard* that many
implementations interoperate through. We propose LMAP (the Liquid Media
Access Protocol): a protocol where digital media is tokenized into
standardized units granting verifiable ownership and access rights;
content is distributed through a peer-to-peer network that scales
positively with demand; smart contracts ensure automatic royalty
distribution on every transaction; and ownership is structurally
separable from any particular platform that runs on the protocol.

What consumers experience is *liquid media* — a generic public term for
the category LMAP enables. Liquid media is to streaming services what
physical media was to broadcast television: a different form of
ownership, with different rights, that buyers can hold, transfer, and
pass on.

## 2. Token Architecture {-}

Each film exists as a unique token ID within a master ERC-1155 [^1]
registry contract. Unlike ERC-721 [^2] non-fungible tokens, where each
token is distinct, ERC-1155 allows millions of identical tokens per
film, enabling both mass distribution and liquidity. A single contract
scales to thousands of films, each identified by a unique token ID, with
configurable quantities per title.

The token's URI points to a content identifier on a distributed storage
network containing immutable metadata: title, synopsis, credits, and
references to media assets. This architecture ensures that even if any
particular implementation of the protocol ceases operations, token
holders retain permanent access through the decentralized network and
the open protocol specification.

*Implementation status:* shipped on Polygon mainnet as the
`WyllohRegistryProtocolV4_1` contract at
`0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D`. Verified source available
via public block explorers. The V5 reference contract scaffold is under
active development; deployment under foundation governance on the
forthcoming Liquid Media Chain (§6) is a 2026 milestone.

## 3. Separation of Distribution and Copyright {-}

A critical distinction exists between distribution rights and underlying
copyright. The ERC-1155 registry manages distribution tokens — fungible
units representing viewing and exhibition rights. A separate ERC-721
contract is specified to establish copyright ownership: a single
non-fungible token per film representing the intellectual property
itself.

The copyright token grants control over derivative works, merchandising,
and the ability to propose governance actions such as token splits.
Distribution token holders own rights to view, exhibit, and trade — but
not to create sequels or merchandise. Crucially, the copyright holder
cannot unilaterally mint additional distribution tokens; supply
modifications require token holder approval, protecting holders from
dilution. This mirrors traditional film finance, where investors hold
revenue participation without controlling the underlying intellectual
property, while adding protections absent in conventional structures.

This separation enables powerful scenarios. A studio could acquire the
copyright token to produce a sequel while existing distribution tokens
continue trading. The original filmmaker benefits from the sale;
distribution token holders retain their viewing rights and market
participation. Rights flow to natural owners without forcing
all-or-nothing transactions.

*Implementation status:* design intent. The current V4.1 registry is the
ERC-1155 distribution layer; the ERC-721 copyright registry is specified
for a future protocol version (V5+) and has not yet been deployed.

## 4. Modular Rights Through Stacking {-}

Token quantity determines usage rights through a threshold-based
licensing system. A single token grants personal viewing rights —
analogous to owning physical media. As tokens accumulate in a wallet,
additional rights unlock at thresholds the filmmaker configures at
tokenization time.

Thresholds are intentionally not fixed by the protocol; each filmmaker
sets thresholds appropriate to their content's economics. A documentary
might set low thresholds to encourage screenings; a genre release might
set high thresholds reflecting commercial value. The protocol does not
impose a universal price for theatrical rights because no such universal
price exists in reality. The market discovers appropriate pricing
through trading at the thresholds the filmmaker has chosen.

For illustrative purposes only — not as protocol-level constants —
typical configurations might include:

- *1 token* — personal viewing rights
- *100 tokens* — small-venue exhibition
- *60,000 tokens* — theatrical exhibition rights with access to
  professional distribution formats

But these are choices, not specifications. Thresholds for any given film
are encoded in that film's metadata at minting and are immutable
thereafter for the life of that token's contract.

This mechanism creates natural price discovery for commercial rights.
Rather than negotiating complex licensing agreements, distributors
acquire sufficient tokens on the open market. Token supply is fixed at
initial minting; if market conditions warrant increased liquidity, token
holders may vote to approve a split, multiplying token quantities while
preserving proportional ownership. The copyright holder may propose
splits but cannot execute them unilaterally. New creative works —
sequels, adaptations, alternative cuts — are tokenized as separate token
IDs with independent supplies, leaving original token markets
undisturbed.

*Implementation status:* shipped. Stacking thresholds and on-chain
enforcement are operational in V4.1.

## 5. Layered Architecture {-}

The protocol decomposes into eight layers. Each layer has a defined
responsibility, a published interface to the layers above and below it,
and an implementation status. Different parties can build different
layers as long as the interfaces are honored. Conflating layers —
particularly the entitlement layer with the cryptographic layer — is how
comparable projects have failed.

| # | Layer | Responsibility |
|---|---|---|
| 0 | Trust Anchors | Cryptographic primitives; hardware roots; wallet identity; contract immutability |
| 1 | Storage | Content distribution substrate (IPFS, manifests, incentivized pinning) |
| 2 | Cryptography | Encryption, key hierarchy, threshold release, watermarking |
| 3 | Entitlement | Smart contracts: distribution + copyright registries, royalties, rights tiers, payment splitters |
| 4 | Network | Peer discovery, shard request/response, LAN streaming |
| 5 | Forward Compatibility | Optional hardware-attested key wrapping for legacy industry licensing frameworks |
| 6 | Application | Storefronts, library UI, playback clients, integrator tooling |
| 7 | Governance | Foundation structure; federated certification; protocol governance |

A storefront (Layer 6) only needs to read entitlement (Layer 3); a Seed
manufacturer needs to implement Layers 1, 2, 4, and optionally 5; an
academic auditor of the hardware-attestation framework only needs to
engage with Layer 5 and the cryptographic claims of Layer 2. Each layer
should be specifiable, testable, and replaceable independently of the
others. The protocol does not mandate that any single party implement
all eight layers.

The remaining sections of this paper traverse these layers from the
chain upward, beginning with the chain that serves as the operational
substrate.

## 6. The Liquid Media Chain {-}

LMAP operates on a dedicated Layer-2 chain — the *Liquid Media Chain* —
stewarded by the Liquid Media Foundation (§16). The chain provides the
execution substrate for LMAP smart contracts (Layer 3), the economic
substrate for the LMA token (§16), and the operational substrate for
sequencer infrastructure that the protocol's contracts settle through.

The chain is constructed as a zero-knowledge rollup [^13] built on the
Polygon CDK framework, settling to Polygon mainnet as its Layer-1
security anchor. Polygon CDK was selected over alternative rollup
frameworks for three reasons: it is production-grade with established
managed-service operators (Conduit, Caldera, Polygon Labs itself),
reducing foundation operational burden during bootstrap; its
zero-knowledge security model provides fast finality without
fraud-proof challenge windows, improving user experience for purchase
and transfer flows; and settlement on Polygon preserves USDC liquidity
and the existing V4.1 contract investment, enabling holders of legacy
tokens to bridge into the chain without disruption.

The chain's block economics differ from those of general-purpose Layer-2
chains in three ways. First, the chain uses LMA as its native gas asset,
giving the LMA token operational utility tied directly to protocol
usage. Account abstraction [^6] paymaster contracts allow users to pay
gas in USDC where preferred, insulating consumers from gas-asset
volatility; LMA's role as native gas is structural to the protocol's
incentive design rather than a user-facing surface. Second, a
configurable percentage of every transaction's gas fee is burned
(initial parameter: 50%), contracting LMA supply in proportion to chain
usage. This follows the pattern established by Ethereum's EIP-1559 [^14]
base-fee burn, applied to a media-specific chain. Third, a fraction of
emission per block flows to storage providers that successfully prove
retrievability of registered film CIDs in that epoch (§7), coupling the
storage incentive directly to chain operations rather than running as a
separate off-chain mechanism.

Bridges connect the Liquid Media Chain to Polygon mainnet for USDC, POL
where required, and any V4.1 token holdings. Bridge contracts are
audited and operated by the Liquid Media Foundation during bootstrap,
with the option to migrate to a decentralized bridge protocol at network
maturity. USDC bridged from Polygon retains its peg and serves as the
canonical commerce currency on the Liquid Media Chain: filmmakers
receive USDC; storefront markup flows in USDC; the protocol fee
accumulates in USDC at the foundation treasury for the periodic burn
auctions specified in §11.

*Implementation status:* specification. The chain is in design; its
launch under foundation governance is a Year-1 milestone of the
protocol's bootstrap roadmap (§19). Until launch, LMAP operates on
Polygon mainnet as the bootstrap substrate. The V4.1 contracts continue
to serve existing tokens through and beyond the chain's deployment.

## 7. Content Storage and Incentivized Pinning {-}

Media files are encrypted using AES-256-GCM before distribution on a
content-addressed storage network [^3]. The metadata structure nests
content identifiers: the token URI points to a metadata file containing
references to both unencrypted promotional assets (poster, trailer) and
encrypted media files. Each encrypted asset specifies a threshold — the
token quantity required for access — corresponding to the rights tiers
established at minting.

Encrypted content is stored in a chunked format
(`[Length(4 bytes)][IV(12 bytes)][Ciphertext+Tag(16 bytes)]` per 4-MiB
chunk) which is self-authenticating per chunk and supports streaming
decryption with constant memory. The format is documented in the
protocol specification; any compliant client can implement encryption
and decryption against it.

### 7.1 Storage Providers and Proof of Retrievability {-}

Any participant operating an IPFS daemon plus the LMAP storage-provider
module can register as a storage provider. Registration requires
staking LMA at a storage-registry contract on the Liquid Media Chain.
Wylloh's Seed One and Origin Seed hardware (§10) are
storage-provider-capable by default; software-only nodes operating on
commodity Linux servers or virtual machines may also participate on
identical protocol terms.

Storage providers earn LMA per epoch based on proof of retrievability:
the protocol periodically challenges providers with random byte-range
requests; providers must respond within a configured deadline with the
requested bytes plus a cryptographic proof binding the response to the
original CID. Failure to respond, or response with incorrect bytes,
triggers slashing of staked LMA proportional to the severity. Reward
weighting incorporates latency to first byte, geographic distribution
bonuses (encouraging spread across regions with low density), and
sustained-pinning consistency. The design borrows from Filecoin [^7]
proof-of-replication and proof-of-spacetime mechanisms, adapted for
streaming-media chunks rather than arbitrary archival data: more
frequent small challenges rather than infrequent large proofs, and
incorporation of latency and geographic factors that matter for media
delivery.

### 7.2 Threshold Dispersal {-}

A future enhancement at this layer is *threshold dispersal of
ciphertext shards* — distributing encrypted content shards across the
Seed network using Reed-Solomon erasure coding, with the option of
secret-share-based reconstruction [^9], such that reconstruction
requires a quorum of nodes. This is a resilience property at the
storage layer, not the load-bearing security mechanism (see §8.4 for
the precise scope of this claim).

*Implementation status:* chunked AES-256-GCM encryption, IPFS storage,
and a centralized pinning fallback are shipped. Stake-and-slash
incentivized pinning, proof-of-retrievability, and the storage-registry
contract are specified for deployment on the Liquid Media Chain in
Year 1. Threshold ciphertext dispersal is specified for a subsequent
protocol version.

## 8. Cryptography and Threshold-Based Access Control {-}

LMAP's security model is threshold-mediated key release. Access to a
film's decryption material is gated by *current on-chain ownership of
the corresponding token*, evaluated at decryption time by a threshold
cryptographic network. No party — not the foundation, not a
storefront, not a hardware vendor, not the protocol's own contracts —
can release decryption material to a wallet that does not currently
satisfy the access condition.

We claim, and intend to demonstrate, that this model provides
security equivalent to or stronger than legacy hardware-attested DRM
systems, while preserving open-protocol participation in ways those
systems structurally cannot. Threshold cryptography with stake-based
sybil resistance is mathematically sound and has not been broken in
production deployments; Widevine L1, by contrast, has been broken
multiple times. The protocol does not require hardware attestation to
be secure; it requires honest cryptography and aligned economic
incentives, both of which the threshold model provides.

### 8.1 A Note on the Legacy Open-Tier Approach {-}

Earlier protocol versions described an *open tier* in which the
content-decryption wrapping key was deterministically derivable from
public on-chain data using a documented formula. Decryption then
proceeded entirely with public inputs: a wallet that had once received
the encrypted master key could decrypt forever, regardless of
subsequent token transfers.

This approach was articulated as a deliberate design choice in service
of platform independence. Reviewed against the requirements of a
production protocol for film distribution — independent or otherwise —
it has been retired. The derivable-key construction does not gate
decryption by current ownership: any party with the public chain data
and the published metadata can derive the wrapping key, retrieve the
encrypted master key from public storage, and decrypt the film without
ever holding the token. The construction is therefore appropriate for
*demonstrating the protocol's other mechanics on public-domain
content* — the role it played in the V4.1 deployment with the 1929
public-domain film *The Cocoanuts* — and is not appropriate for any
content of commercial value.

V3 of the protocol replaces the open-tier construction with
threshold-mediated key release as the standard production mechanism.
Legacy V4.1 tokens continue to operate under the original construction
for historical continuity; no new commercial content is tokenized
against the legacy construction.

### 8.2 Threshold-Mediated Key Release {-}

Threshold cryptography enables a network of *N* nodes to collectively
release a master key only when a configurable threshold *T* of them
independently verifies an access condition. No single node — and no
group fewer than *T* — can release the key. The mathematical security
depends on honest-majority assumptions; the operational security
depends on stake-based participation, in which threshold-network
operators stake LMA and have stake slashed for misbehavior.

At content preparation, a publisher generates a random master key and
encrypts the film with it using chunked AES-256-GCM. The publisher
then submits the master key to the threshold network for encryption to
a Distributed Key Generation public key. The network returns a
threshold-encrypted master key, which is stored alongside the
metadata. The film's metadata declares an Access Control Condition —
typically `balanceOf(:userAddress, :tokenId) > 0` against the LMAP
registry contract.

At decryption, a client signs a SIWE-style authentication message [^15]
proving control of the requesting wallet. The client submits the
authentication, the threshold-encrypted master key, and the Access
Control Condition to the threshold network. Threshold-network nodes
independently verify the wallet signature, query the chain for current
Access Control Condition state, and release decryption shares only if
the condition evaluates true. The client collects *T* shares and
reassembles the master key, then decrypts the film using the standard
chunked AES-GCM mechanism.

Transfer behavior emerges from the architecture. When a token is
transferred from one wallet to another, the Access Control Condition
is evaluated against current chain state at the next decryption
attempt. The seller's wallet no longer satisfies `balanceOf > 0`; the
buyer's now does. The threshold network refuses to release shares to
the seller and releases them to the buyer. No re-wrapping, no
foundation involvement, no seller cooperation required.

### 8.3 Year-0 Bootstrap on an Established Threshold Network {-}

During bootstrap, LMAP integrates with Lit Protocol's Naga mainnet
[^16] as the threshold-network substrate. Lit is a production-grade
threshold-decryption network with established support for chain-based
Access Control Conditions, including Polygon, and several years of
operational maturity. Year-0 commercial content is tokenized against
Lit using the threshold-mediated mechanism.

Beginning in Year 1, the Liquid Media Foundation deploys an
LMAP-native threshold network operated by registered threshold-network
nodes — initially foundation-operated bootstrap nodes, subsequently
Wylloh Seeds and any third-party operator that stakes the required LMA
minimum. New content increasingly defaults to the LMAP-native network
through Year 1. By the end of Year 2, all production content has
migrated to the LMAP-native threshold network; the Lit Protocol
dependency is retired.

The bootstrap dependency on Lit is transient and intentional, not
permanent reliance. Replacing Lit with the LMAP-native threshold
network is a public protocol commitment with a defined milestone, not
a discretionary path.

### 8.4 Forward Compatibility for Legacy Industry Frameworks {-}

Some industry licensing frameworks — primarily those originating with
major studios — reference specific hardware-DRM technologies (Widevine
L1, PlayReady, FairPlay) as contractual conditions of licensing.
These frameworks predate threshold cryptography's deployment maturity
and were written when hardware-attested per-device key custody was
the only practical mechanism for cryptographic enforcement at scale.
We anticipate that these frameworks will evolve to recognize
threshold cryptography as equivalent or stronger security over time;
this is a reasonable expectation given threshold cryptography's
production track record and the existing frameworks' demonstrated
breakability.

In the interim, LMAP's design includes forward-compatible support
for hardware-attested key wrapping. This support is a capability of
the protocol, not a positioning choice or a marketing feature. The
protocol's primary security guarantee runs through threshold release;
the hardware-attested capability exists so that licensing
relationships predicated on the legacy frameworks can be honored
without forking the protocol or compromising its open-protocol
participation properties.

When invoked for a specific content class whose licensing contract
requires it, the hardware-attested capability operates as follows:

- Each participating Seed holds a per-device keypair generated inside
  its hardware secure element. The private key is non-extractable.
- For attestation-required content, the threshold network's released
  master key is additionally wrapped to the Seed's per-device public
  key. Unwrapping occurs only inside the secure element; the
  unwrapped key never appears in main memory or persistent storage
  outside the secure perimeter.
- Wrapped-key issuance requires the Seed to present a fresh
  *attestation report* signed by its secure element, containing
  current firmware measurements. The report is verified against the
  Seed's attestation credential before any wrapped key is issued.
- Per-title content keys are derived from a master with HKDF-style
  domain-separated key derivation [^11] to prevent key reuse across
  titles.

Reference hardware for attestation-required operation includes ARM
TrustZone [^12]-capable SoCs with discrete secure elements (e.g.,
NXP SE050 or equivalent), and platforms with TPM 2.0 [^4] support.
Remote attestation [^5] follows established patterns from
contemporary trusted-computing literature.

**Hardware binding is a normative requirement when the
hardware-attested capability is invoked.** A compliant implementation
of attestation-required content delivery MUST use a hardware secure
element to (a) generate the per-device keypair, (b) hold the private
key in non-extractable form, (c) perform key unwrapping, and (d) sign
attestation reports. An implementation that performs any of these
operations outside a hardware secure element is not conformant.

A clarifying distinction: the hardware-attested capability gates
*decryption*, not *carriage*. Encrypted content under this capability
is freely distributable through the same content-addressed substrate
as all other LMAP content; any device can hold, pin, or serve the
encrypted bytes. Tokens remain freely transferable across all
wallets. Hardware attestation, when invoked, gates playback only.
This preserves user sovereignty (a buyer's ownership is unaffected
by hardware availability; they can transfer their token at any time)
while honoring the legacy contractual requirement (decryption is
impossible without an attested secure element).

The protocol's posture is explicit: this capability is forward-
compatibility for industry frameworks that have not yet evolved. As
licensing counterparties update their compliance frameworks to
recognize threshold cryptography directly, the relevance of the
hardware-attested capability decreases. The protocol's intellectual
center of gravity is threshold-mediated release; the
hardware-attested capability exists at the periphery, as a courtesy
to a legacy that is itself in the process of becoming obsolete.

### 8.5 Federated Issuance for the Hardware-Attested Capability {-}

When the hardware-attested capability is invoked, attestation
credentials are signed by independent *attestation issuers*. An
issuer verifies a Seed's hardware integrity and signs a credential
binding the device's public key to a manifest of approved firmware
measurements. Issuers operate under a federated framework governed
by the Liquid Media Foundation (§16).

No single issuer can unilaterally approve or deny attestation; the
framework's governance can revoke any issuer whose practices fail
audit. Counterparties negotiate with the framework, not with a
single platform operator. The model is structurally analogous to
the federation of certificate authorities that underpins the public
web's TLS infrastructure: independent issuers, audited practices,
root trust managed by a body distinct from any commercial
participant.

The framework launches with a single issuer (the Liquid Media
Foundation itself) and a public commitment to federate at a defined
milestone of network maturity. Federation is a visible commitment,
not an indefinite promise. We note that the framework's relevance
itself depends on the persistence of the legacy industry
requirements that necessitated it; over time, both the issuer
federation and the hardware-attested capability are expected to
decrease in significance relative to threshold-mediated release.

### 8.6 Security That Scales with Network Size {-}

Two distinct claims about how protocol security relates to network
size deserve separate treatment, because they have different
defensibility.

**Strong claim — threshold release with stake-based sybil resistance.**
Compromising the threshold network requires either compromising more
than the slashing-tolerance threshold of independently-staked nodes
(economically irrational at scale) or extracting cryptographic
material from those nodes (each holds only a share). The network's
aggregate exposure does not grow with the network's size; if anything,
it shrinks, because additional staking pools dilute the share that any
attacker would need to control. This is the load-bearing cryptographic
claim.

**Strong claim — per-device key wrapping (hardware-attested
capability, when invoked).** When the hardware-attested capability is
invoked, compromising one attested Seed yields that Seed's local
content only. The network's aggregate exposure does not grow with
the network's size, because each attested device is its own isolated
vault. This is a property of the capability when invoked, not a
property the protocol depends on for its primary security guarantee.

**Modest claim — threshold dispersal of ciphertext (storage layer).**
Sharding ciphertext across Seeds raises the per-shard extraction cost.
An attacker compromising one Seed obtains a fraction of the
ciphertext for any given film; reconstruction requires reaching the
quorum threshold. This is real but bounded: a sufficiently motivated
attacker can target enough Seeds to reach quorum. The combinatorial
cost is meaningful but does not produce asymptotic security.

This precision matters for technical readers because the conventional
DRM model degrades as user base grows (more devices, more keys, more
attack surface). Threshold release and per-device key wrapping invert
that property; threshold dispersal at the storage layer supplements
it.

### 8.7 Watermarking {-}

Forensic watermarking binds a leak to a specific wallet, raising the
cost of unauthorized distribution beyond the bare cryptographic
extraction cost. Watermarks may be inserted server-side at
content-preparation time (per-purchase variants delivered to specific
wallets) or, for attested-mode content, Seed-side at decryption time,
inside the secure element, before plaintext leaves the secure
perimeter.

Watermark robustness against transcoding and adversarial filtering is
an ongoing research area; commercial watermarking implementations
exist with established studio relationships. The protocol specifies
watermark insertion points but does not mandate a particular scheme.

*Implementation status:* threshold-mediated key release against Lit
Protocol's Naga mainnet is in active implementation; migration of the
Wylloh reference client and Seed daemon from the legacy derivable-key
construction to threshold-mediated release is a near-term engineering
milestone, completed before any commercial title is tokenized. The
LMAP-native threshold network is specified for Year-1 deployment on
the Liquid Media Chain. Hardware-attested mode is specified at the
protocol level with hardware-binding declared normative (§8.4); the
wire-level attestation specification, the framework's first issuer
beyond the foundation, governance process, and operational maturity
are forthcoming. Server-side watermarking is in initial implementation
with a commercial watermarking provider relationship to be established
before commercial-content launch.

## 9. Permanence Guarantees {-}

The protocol commits to a permanence guarantee: a buyer who has
legitimately acquired a film at any point retains the ability to play
that film indefinitely, regardless of subsequent network availability,
attestation revocation, or platform fate.

The guarantee is engineered through three mechanisms operating in
combination. First, after a client has successfully decrypted a film
through the threshold network at acquisition, the master key is
cached locally — in the browser's persistent storage, the Seed
daemon's encrypted local storage, or any compliant client
implementation's local persistence. Subsequent playback of the same
film does not contact the threshold network; the client decrypts
directly from local state. Second, holders may export their master
keys as user-encrypted backups — wrapped with a passphrase the holder
chooses, written to any storage the holder controls. A backup file
plus the downloaded encrypted bytes plus the user's passphrase enables
playback in perpetuity, even if all foundation and threshold-network
infrastructure ceases to exist. Third, the ownership record on the
chain remains the durable source of truth; a holder who has lost both
local cache and backup can re-acquire access through any compliant
implementation of the protocol that still operates against the chain,
because the wallet's holdings are recoverable from public data.

In attested mode, the permanence guarantee is preserved by a parallel
mechanism. Attestation gates the *issuance* of wrapped keys, not the
*playback* of content already keyed. A Seed whose attestation
credential is later revoked retains the wrapped keys it previously
received and continues to play the corresponding films. Revocation
prevents the Seed from acquiring further content through attested
mode; it does not retroactively disable the Seed's existing library.
This is the architectural answer to the rugpull pattern that has
characterized streaming services and digital media stores.

The hardware itself remains a single point of failure: a Seed whose
secure element fails physically loses access to its locally-wrapped
keys. The protocol mitigates this by treating the on-chain ownership
record as the durable source of truth. A user whose Seed has died can
re-acquire wrapped keys for their owned films onto a new attested
Seed, because the wallet's holdings are recoverable from the
blockchain. **The blockchain remembers; the hardware is replaceable.**
This is a stronger guarantee than physical media, which has no
equivalent recovery path when a disc fails.

The canonical claim, stated precisely: *downloaded films play forever
offline; re-download and transfer require an access network — the Lit
Protocol Naga mainnet during Year 0; the LMAP-native threshold
network from Year 1 onward — to be live; no single-company point of
failure*.

*Implementation status:* local master-key caching, the self-wrapped
backup export, and the recovery path through on-chain ownership are
in active implementation. The Year-0 threshold-network dependency on
Lit Protocol is acknowledged honestly in user-facing communications;
the Year-2 sunset of that dependency in favor of the LMAP-native
network is a public commitment.

## 10. The Seed Network {-}

Content distribution operates through *Seeds* — user-operated nodes
that combine encrypted-content storage, peer-to-peer participation, a
local LAN-streaming service for playback applications, and (when
staked) threshold-network operation and storage-incentive
participation.

A Seed is a headless device. It does not connect directly to a
television; instead, it serves LMAP-registered content to client
applications running on platforms users already own — Roku, Apple TV,
iOS, the web. The user's existing remote, the user's existing
television, the user's existing input habits all remain intact. The
Seed becomes infrastructure: quiet, reliable, operated as a piece of
furniture in the home network rather than a screen in the living
room.

Each Seed stores content its operator owns, plus optionally
contributes overflow capacity to the network. Popular films accumulate
across more Seeds as more users own tokens; niche content maintains
availability proportional to its audience. No central coordination
determines what Seeds store; ownership patterns drive distribution.

This architecture inverts conventional streaming economics.
Centralized platforms bear infrastructure costs proportional to
viewership: success is expensive. In the Seed network, increased
viewership means more Seeds joining, distributing load across more
nodes. Per-stream costs approach zero as the network grows. The system
becomes more efficient at scale rather than more costly. Seeds that
stake the LMA minimum (§16) participate in the storage-incentive
network (§7) and the threshold network (§8); they earn LMA emission
for proof-of-retrievability work and threshold-share-release work.
Network participation is therefore both a beneficial side effect of a
device that operators would buy regardless (the local film library is
the primary purchase rationale) and an ongoing source of compensation
for operators who choose to stake.

### 10.1 Reference Hardware {-}

Two reference Seed devices are specified by the protocol's first
commercial implementation (§17). The *Seed One* is a compact,
fanless, consumer-priced reference device specified to participate
fully in the protocol on commodity hardware: a current-generation
single-board computer, a hardware secure element, network storage, and
a published reference firmware. The *Origin Seed* is a sculptural,
hand-finished reference device specified at the high end of the
product line: substantially greater storage capacity, audiophile-grade
power supply, and a furniture-quality enclosure intended for the
luxury custom-integration market.

Both reference devices participate identically at the protocol level.
Both are storage-provider-capable, threshold-network-operator-capable,
and hardware-attestation-capable. The distinction between them is
form, capacity, channel, and price — not protocol participation.

The protocol does not require either reference device. Any compliant
Seed — third-party hardware, software-only nodes operating on
commodity Linux, virtual-machine instances — can participate on
identical terms. The reference Seeds exist as canonical
implementations the protocol can point to; they are not the only
implementations welcomed.

### 10.2 Operational Behavior {-}

A compliant Seed daemon verifies wallet ownership directly against the
on-chain registry, fetches encrypted content from IPFS (preferring a
co-resident node where present, falling back to public gateways),
decrypts streaming with constant memory, automatically pins source
CIDs to make the Seed a provider for content it holds, and exposes a
long-running HTTP service with mDNS auto-discovery and HTTP byte-range
streaming for LAN client applications. Where the Seed has been
configured for it, the daemon additionally participates in the
threshold network as a stake-bonded node, releasing decryption shares
for content the network requests in accordance with §8.

*Implementation status:* an open-source reference Seed daemon is
operational, demonstrating wallet-verified content fetch, decryption,
and LAN streaming on independent ARM64 hardware (Raspberry Pi 4) with
byte-identical decrypted output across architectures and no
dependency on any centralized service. The reference Seed daemon's
migration from the legacy derivable-key construction to threshold-
mediated release is a near-term milestone. Both reference Seeds —
*Seed One* and *Origin Seed* — are in pre-production. The web client
at wylloh.com serves as the first reference application.

## 11. Marketplace Mechanics {-}

The protocol includes integrated marketplace functionality. Primary
sales occur through minting at prices set by the title's author.
Secondary sales enable peer-to-peer trading with automatic royalty
distribution on each transaction. All marketplace operations execute
against smart contracts on the Liquid Media Chain (§6); commerce
settles in USDC with gas paid in LMA underneath an account-abstraction
paymaster so consumers experience USDC-only checkout.

### 11.1 Three-Way Revenue Split {-}

Every primary sale routed through the protocol distributes payment
across three parties, with proportions set per title at mint time:

- **Protocol fee: 2.5%** (immutable, hardcoded at the contract level).
  Flows to the Liquid Media Foundation treasury in USDC. The
  foundation retains a small operating carve-out (initial parameter:
  10% of accumulated fee revenue) for shared infrastructure: IPFS
  pinning redundancy, contract auditing, security work, open-source
  maintenance. The remainder flows into the periodic burn auctions
  described in §11.8.

- **Publisher fee: 0–25%** (set per title, immutable for that title).
  Flows to the publisher — the wallet that minted the title.
  Publishers are entities that bring works to market: established
  storefronts, indie collectives, or self-publishing authors. Their
  cut compensates curation, marketing, audience development, and
  brand value.

- **Author share: remainder.** Flows to the author — the credited
  creator(s). Distributed via an optional royalty shareholders
  configuration (§11.3) supporting up to 50 collaborators per title.

For a typical configuration — 10% publisher fee — the split is 2.5% /
10% / 87.5%. Authors receive dramatically better economics than
traditional publishers, where author shares of 10–20% are common. The
protocol's 25% publisher cap is the only opinionated stance:
*publishing on LMAP shall not become as extractive as the systems it
replaces*.

### 11.2 Publisher and Author as Distinct Roles {-}

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
publishing-house / author distinction familiar from books, films, and
music.

### 11.3 Royalty Shareholders {-}

Authors can configure up to 50 royalty shareholders per title, each
receiving a configurable percentage of the author's share. This
supports the realistic case where a tokenized work has multiple
contributors deserving compensation: a film with director, lead
actors, composer, screenwriter; a video game with developers, artists,
and key team members; an album with songwriter, performers, and
producer.

Shareholders are mutable by the author, allowing collaborators to be
added or adjusted as the work evolves. Sum of shares can be ≤ 100% of
the author's share; any remainder flows to the author wallet,
preserving the author as the residual recipient. For projects with
more than 50 beneficiaries, shareholders compose with external
splitter contracts: one shareholder slot can route to a splitter
address that distributes further.

Distribution happens automatically on every protocol-routed sale —
both primary and secondary. No manual royalty disbursement, no escrow,
no off-chain ledger reconciliation.

### 11.4 Royalty Enforcement Boundary {-}

The protocol enforces royalties cryptographically for sales routed
through its marketplace functions. External marketplaces honoring the
ERC-2981 royalty standard will respect the configured royalty when
displaying and processing sales. Direct wallet-to-wallet transfers —
the gift, inheritance, and personal-give use cases — do not trigger
royalties; this is a property of the underlying ERC-1155 standard and
a deliberate preservation of token-as-property semantics.

Off-chain payment with on-chain gift is theoretically possible and
unenforceable cryptographically, as with every royalty-bearing token
system. The protocol's mitigation is structural: the low 2.5%
protocol fee minimizes the savings from circumvention; the integrated
marketplace makes legitimate sales easier than coordination; on-chain
transparency makes wash-trade patterns visible and reputationally
costly.

### 11.5 Bulk Acquisition for Rights Stacking {-}

The marketplace supports atomic batch purchases, enabling a single
transaction to acquire tokens from many sellers simultaneously. This
is essential for the rights-stacking use case (§12): a buyer
assembling tokens to meet a theatrical-exhibition threshold may need
to acquire thousands of tokens from hundreds of sellers in a single
coordinated purchase. The atomic semantics guarantee all-or-nothing:
if any listing in the batch fails, the entire transaction reverts,
preventing the partial-fill case where a buyer pays fees but does not
reach their target threshold.

Platform UIs aggregate, sort, and present available listings; the
protocol provides the batch-execution primitive.

### 11.6 The Protocol Fee Is Not a Platform Fee {-}

The 2.5% protocol fee supports shared infrastructure all
implementations depend on, identical across every LMAP-compatible
marketplace. Third-party marketplaces may layer their own commercial
markup on top, competing on user experience, curation, and discovery
rather than by undercutting the protocol fee. This places third-party
marketplaces and the reference web client at wylloh.com in a peer
relationship with one another, not a competitive one.

### 11.7 Settlement and Gas Abstraction {-}

Transactions settle in stablecoin to insulate buyers from
cryptocurrency volatility. On the Liquid Media Chain (§6), settlement
is in USDC; gas is paid in LMA underneath an ERC-4337 [^6] paymaster
contract such that users experience USDC-only checkout. The paymaster
contract pays LMA gas on the user's behalf, recovering the cost via
a small USDC surcharge bundled into the transaction. Paymasters are
deployed and funded at the marketplace layer; each marketplace can
choose whether and how to subsidize gas as part of its commercial
offering.

The legacy V4.1 deployment on Polygon mainnet operates against
USDC.e and requires users to hold POL for gas — friction the protocol
acknowledges as a near-term limitation of the bootstrap substrate
rather than an intended feature. Migration to the Liquid Media Chain
removes both: USDC replaces USDC.e; LMA gas under the paymaster
removes the user-facing POL requirement.

### 11.8 LMA Token Burn from Protocol Fees {-}

The Liquid Media Foundation operates periodic Dutch auctions
converting accumulated USDC protocol-fee revenue into LMA, which is
then permanently burned. The auction cadence is configurable
(initial parameter: weekly); the burn destination is the conventional
zero-public-key burn address. Burn events emit on-chain logs; supply
contraction is public and auditable.

This mechanism couples LMA supply contraction directly to protocol
usage. Every sale on every LMAP-compatible marketplace contributes
to the burn pool. As protocol usage grows, the burn rate grows; the
LMA token captures value not through extraction by any intermediary,
but through deflationary pressure proportional to actual network
activity. The structure follows the precedent of Ethereum's EIP-1559
[^14] base-fee burn, with the analogous result: token holders
benefit from network growth proportionally, with no entity acting
as an extractive operator.

*Implementation status:* primary sales with three-way distribution,
secondary sales with royalty enforcement, royalty shareholder
distribution, batch acquisition, and the protocol fee are specified
in the V5 reference contract. The V5 contract is in active
development; deployment under foundation governance on the Liquid
Media Chain is a 2026 milestone. The legacy V4.1 registry remains
in operation for existing tokens (legacy derivable-key construction,
two-way author / protocol split) during the transition. The
USDC-to-LMA burn auction is specified for the Liquid Media Chain
deployment.

## 12. Commercial Rights Discovery {-}

The stacking mechanism enables a novel form of commercial rights
acquisition. Consider a film that achieves cult status: tokens are
distributed across thousands of fans who purchased during initial
release. A theater chain wishes to conduct a theatrical run, requiring
tokens above the exhibition threshold the filmmaker configured for
that title.

Rather than negotiating with the original filmmaker, the theater
acquires tokens directly from fans through open market purchases. As
buy pressure increases, token prices rise, rewarding early believers
who funded the film's success. Royalties trigger on each transfer,
flowing to the copyright holder regardless of who sells. The market
determines that theatrical rights to this particular film, at this
particular moment, command a specific price — no negotiation required.

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

## 13. Production Funding {-}

The token architecture enables presale-based production financing.
Rather than relying on studio executives or platform algorithms to
greenlight projects, creators can presell tokens directly to audiences.
This validates market demand before production begins while
distributing ownership of the work directly to its audience.

Presale tokens grant the same ownership rights as post-release tokens
but are purchased at a discount, rewarding early supporters. Smart
contracts can structure milestone-based fund releases with
multi-signature approval from stakeholder representatives. If
production fails to meet milestones, remaining funds return to presale
participants.

This model removes centralized gatekeepers from greenlighting
decisions. A film need not fit a platform's content strategy. If
sufficient audience interest exists to fund production, the project
proceeds. The presale serves simultaneously as market research,
financing mechanism, and community-building exercise.

*Implementation status:* design intent. The token architecture
supports presales architecturally; the milestone-based escrow
contracts and the corresponding presale-tokenization workflow are
specified for a future protocol version.

## 14. Privacy {-}

Contemporary streaming platforms extract extensive personal data to
drive recommendation algorithms and advertising. The protocol operates
on a different principle: *movies should not watch their viewers*.
Analytics derive exclusively from public blockchain data —
transaction patterns, token distribution, market activity — rather
than viewing behavior or personal information.

The conventional streaming model links user identity to viewing
history to platform to advertisers, forming a chain of surveillance
maintained primarily for monetization through inferred consumer
preferences. The protocol model maintains pseudonymous wallets
executing public transactions on a transparent ledger, with no link
to real-world identity, no telemetry from playback events, and no
viewing patterns aggregated by any party. Creators receive aggregate
insights — token distribution by region inferred from public data,
secondary-market activity, holder concentration — without
compromising individual privacy.

## 15. Security Philosophy {-}

The protocol does not attempt perfect copy protection. History
demonstrates that technological restrictions on digital media
inevitably fail while degrading legitimate user experience —
including the legacy hardware-DRM systems that this protocol claims
to equal or exceed. Widevine L1 has been broken in production
multiple times; PlayReady and FairPlay have had their own
compromises. The premise that the user is an adversary, and that
sufficient hardware can prevent extraction, has not held in practice.

Instead, the protocol aligns incentives such that ownership provides
value beyond mere access — liquidity, permanence, community membership
— making legitimate acquisition the rational choice. The
cryptographic enforcement that *is* present (threshold-mediated key
release, §8) gates access by current on-chain ownership, evaluated
by a network of stake-bonded nodes. This provides honest
cryptographic protection against the systematic extraction case
without treating audiences as adversaries.

The analog hole — capture of content via camera or screen recording
during legitimate playback — remains possible. Watermarking is the
only mitigation, and watermark robustness against transcoding is an
ongoing arms race. The protocol does not claim immunity from this
class of attack; it claims that legitimate purchase confers economic
benefits that bare ciphertext extraction does not, and that
forensic watermarking enables attribution of leaks to specific
purchasers.

When content is owned not by a distant corporation but by potentially
many individual token holders, piracy dynamics shift. Unauthorized
distribution harms not an abstract studio but a community of fellow
enthusiasts. Token holders own copies of the work itself, aligning
their interest with its integrity rather than its piracy. Social
contracts, properly constructed, provide stronger protection than
technological locks against the casual case; threshold-mediated
key release provides cryptographic protection against the systematic
extraction case. These two mechanisms together are the protocol's
security posture; they do not require — and do not depend on —
hardware-attested per-device key custody. Where forward-compatible
hardware-attested key wrapping is invoked for licensing relationships
predicated on legacy industry frameworks (§8.4), it operates as an
additional credential check, not as the load-bearing security layer.

Physical media operated on similar principles. Copy protection on
optical discs was trivially circumvented, yet the market thrived for
decades. Convenience, quality assurance, and social norms around
ownership provided sufficient protection. The protocol adds financial
incentives physical media lacked: ownership appreciates in genuinely
successful work, and secondary markets reward early adoption.

A specific guidance for technical readers: when evaluating the
protocol's claims, separate the *cryptographic claim* (threshold-
mediated release with stake-based sybil resistance provides security
equivalent to or stronger than legacy hardware-attested DRM, and does
not degrade with network scale) from the *operational claim*
(legitimate purchase is more economically rational than extraction
for participants in the network). Both claims hold, but they hold at
different layers and under different threat models. The whitepaper is
precise about this because the audiences this document serves —
investors, developers, and licensing counterparties — read the same
words and need to extract the same meaning.

## 16. Governance and the Liquid Media Foundation {-}

The protocol is governed by an independent foundation, structurally
distinct from any commercial operator. The Liquid Media Foundation
holds the protocol's intellectual property under a permissive
open-source license, operates the Liquid Media Chain (§6) sequencer
during bootstrap, manages the LMA token's issuance and burn
mechanics, stewards the forward-compatible attestation framework
(§8.4) for licensing relationships predicated on legacy industry
requirements, publishes the protocol specification, and operates as
a protocol-neutral standards body.

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

### 16.1 Legal Structure {-}

The Liquid Media Foundation is structured as a *Cayman Foundation
Company*. This structure has established legal precedent for
protocol stewardship under regulatory frameworks that recognize
utility-token issuance — the Tezos Foundation, the Cardano
Foundation, the Polkadot Web3 Foundation, the BNB Foundation, and
others follow analogous structures. The Cayman Foundation Company
offers three properties relevant to LMAP: cross-jurisdictional
flexibility (the protocol's participants are global), token-issuance
precedent (the structure has been tested against securities-law
analysis in adjacent contexts), and operational separation between
the foundation's protocol-stewardship role and any commercial
participant in the ecosystem.

A pragmatic note about the present: the foundation's legal structure
is the working commitment for v3 of this whitepaper, made on
informed-but-pre-counsel grounds. Formal incorporation and the
securities-counsel review attendant to LMA token issuance are funded
milestones of the protocol's bootstrap roadmap (§19). If counsel
review identifies a structurally superior alternative, v3.1 of this
whitepaper will reflect the revised commitment; readers should treat
§16.1 as the current working commitment, not as a ratified outcome
of completed legal review.

### 16.2 What the Foundation Stewards {-}

The foundation, at its mature governance, stewards:

- **Specification governance.** Protocol upgrades, EIP-equivalent
  proposals, and version transitions.
- **The attestation framework (§8.5).** Maintaining the federation
  of attestation issuers, audit standards, and revocation governance
  for hardware-attested mode.
- **The Liquid Media Chain (§6).** Operating the chain sequencer
  during bootstrap; coordinating the migration to decentralized
  stake-based sequencer consensus by a defined network-maturity
  milestone.
- **The LMA token.** Holding the initial token treasury, operating
  the periodic burn auctions (§11.8), maintaining the emission
  schedule for storage providers (§7) and threshold-network
  operators (§8.2), administering staking and slashing parameters.
- **Treasury.** Custody of the foundation's operating allocation of
  LMA and the USDC operating carve-out from protocol-fee revenue;
  application to shared infrastructure costs and grants to ecosystem
  development.
- **Token-holder governance.** Per-protocol parameter changes (fee
  rates, emission curve adjustments, attestation federation
  milestones, chain parameter changes) by vote of staked LMA
  holders. During the bootstrap phase (Years 1–3), the foundation
  board retains veto power; sunset of board veto in favor of full
  token-holder governance is committed to a defined maturity
  threshold.

### 16.3 What the Foundation Does Not Do {-}

The foundation does not operate any commercial storefront, does not
manufacture or sell any reference Seed hardware, does not take fees
on bilateral commercial relationships between ecosystem participants,
does not hold any extractive position in LMA appreciation, and does
not gatekeep participation in the standard-tier protocol
operations. The hardware-attested mode's federated framework
(§8.5) is the only context in which the foundation acts as a
gating party, and even there it acts as one of multiple federated
issuers rather than as a sole authority.

### 16.4 The LMA Token {-}

LMA is the native token of the Liquid Media Chain and the
coordination instrument for storage-provider and threshold-network
participation. Its three functions compose into a single internally
consistent economic system: gas on the chain (Section 6); stake
collateral for storage providers and threshold-network operators
(§§7, 8); and value-capture instrument via burn from protocol fees
(§11.8) and burn from chain base-fee mechanics.

The token's maximum supply is fixed at one billion LMA at launch,
with allocation across the network-operator emission reserve,
foundation operations, ecosystem development grants, early
contributor pool, strategic partner reserve, foundation endowment,
and public bootstrap reserve. The network-operator emission reserve
releases via a decaying schedule modeled on Filecoin's storage
reward emission [^7], with high early emission to attract bootstrap
participation and asymptotic decay thereafter. Detailed parameters
are specified in a companion token-economics document published
alongside the foundation's incorporation.

A core structural property of the allocation: the commercial entity
Wylloh, Inc. — the first commercial implementation of the protocol
(§17) — receives zero LMA allocation. Individuals who contribute to
the foundation's bootstrap may receive LMA grants as individuals
against their foundation contributions, separate from any equity
they hold in commercial implementations. This separation is the
load-bearing structural commitment for the protocol's
"non-extractive" framing: the foundation, the token, and the
commercial implementations are kept in three distinct entity
categories, and no commercial implementation depends on token
economics for its revenue.

The token is designed and structured to function as a network
utility instrument rather than as an investment instrument.
Specifically: there is no initial coin offering or public token
sale; distribution is via emission (for work performed), grants
(for verified ecosystem contribution), and small structured
strategic allocations; functional utility (gas, staking,
governance) is operational at chain launch; no entity claims returns
from LMA appreciation; the Cayman Foundation Company structure
enables securities-compliant issuance under a regulatory framework
with established precedent for protocol-utility tokens. These
structural choices are intended to satisfy applicable securities
analysis by ensuring that any reasonable acquirer of LMA acquires
it for protocol utility rather than for profit from another entity's
efforts.

*Implementation status:* the foundation is in formation; incorporation
as a Cayman Foundation Company is a funded milestone of the upcoming
raise. The Liquid Media Chain is in design; launch under foundation
governance is a Year-1 milestone. The LMA token is specified;
launch under foundation operation is concurrent with the chain
launch. V5's permissionless minting and verified-publisher registry
are specified and implemented in the reference contract scaffold;
deployment under foundation governance is a 2026 milestone.

### 16.5 Curation: Gateless, Not Absent {-}

The protocol layer is permissionless — any wallet can mint a title
(V5 onward). Curation happens at the application and registry
layers, not at the protocol. Three signals work together:

1. **Cryptographic identity at mint.** The wallet that mints a title
   is recorded as the publisher, on-chain, immutably. Brand identity
   is wallet-bound and cannot be impersonated.

2. **Foundation-maintained verified publishers registry.** The
   Liquid Media Foundation publishes a curated list of verified
   publishers at `liquidmediafoundation.org/publishers.json`.
   Verification signals quality and accountability without
   restricting the protocol; unverified publishers can still mint,
   but will not appear in verified-only application views.

3. **Application-layer editorial choice.** Each platform built on
   LMAP applies its own filter: the Wylloh storefront shows titles
   from Wylloh and other respected publishers; an indie aggregator
   might show all unverified content; a music-focused platform
   filters by `mediaType: music` and music-publisher wallets. The
   protocol exposes the truth (who minted what); applications
   shape the experience.

This model — *permissionless protocol, curated applications* —
mirrors how DNS works: anyone can register a domain, but resolvers,
browsers, and search engines each apply their own filters. Quality
emerges economically rather than by gatekeeping. A publisher with
poor taste mints work nobody buys; a publisher with good taste
accumulates verified status and earns the publisher fee from real
demand.

The legacy V4.1 registry retains its role-gated mechanism as the
editorial mechanism for the legacy-construction deployment serving
already-minted titles. New tokenizations under V5 land in the
permissionless model.

## 17. Comparison with Prior Work {-}

LMAP inherits ideas from several adjacent ecosystems and addresses
limitations specific to each.

**Centralized streaming services** (Netflix, Disney+, and others) own
the relationship with audiences and bear infrastructure costs
proportional to viewership. They cannot offer durable digital
ownership because durable ownership conflicts with subscription
economics. LMAP inverts this by routing ownership through a public
ledger and distribution through a peer-to-peer network.

**Kaleidescape** ships hardware-backed ownership for theatrical-
quality content but operates within a closed ecosystem at luxury
price points and serves a narrow demographic. LMAP shares the
philosophical commitment to genuine ownership but extends the
addressable audience by separating the protocol from any particular
hardware vendor and accepting standard 4K HDR streaming quality
rather than requiring lossless masters.

**Plex** demonstrates the "headless server at home plus client app on
the television" architecture at scale (over 25 million users) with
primarily user-ripped content of unclear provenance. LMAP-compatible
Seed devices inherit this architecture and address Plex's structural
limitations: no provenance, no royalty flow, no curatorial focus,
closed-source business model. The reference Seed devices extend
Plex's pattern with on-chain provenance and an open protocol.

**Filecoin** [^7] **and Helium** demonstrate decentralized-network
plays with token-incentive mechanisms. Both attracted speculative
participants more than utility-driven users, primarily because the
hardware in each case had no standalone consumer value. The purchase
rationale collapsed if the token economics did not deliver expected
returns. LMAP's reference Seed devices have primary consumer
utility: the operator's film library, accessible to LMAP-compatible
playback clients on their local network. This utility does not
depend on any token-incentive mechanism. Network participation is a
beneficial side effect of a device that operators would buy
regardless. This sidesteps the chicken-and-egg adoption problem
that has limited prior decentralized-CDN plays.

**Lit Protocol** [^16] demonstrates threshold-mediated key release as
a production-grade primitive for on-chain access control. LMAP
incorporates Lit Protocol as the Year-0 bootstrap substrate for
threshold release (§8.3); the Year-1 LMAP-native threshold network
implements the same threshold-cryptography primitive operated by
LMAP-staked nodes on the Liquid Media Chain. The relationship is
explicit and time-bounded: bootstrap dependency, not permanent
reliance.

**Polygon and the Polygon CDK** [^13] provide the chain settlement
substrate and the zero-knowledge rollup framework on which the
Liquid Media Chain is constructed. LMAP is to Polygon what
application-specific Layer-2 chains generally are to their Layer-1
anchors: a domain-specific execution environment that benefits from
the security and liquidity of the underlying chain while tuning
block economics to the application's requirements.

**Bitcoin** [^10] **and Ethereum** [^8] establish the cryptographic
and economic primitives this protocol relies upon. The protocol's
contributions specific to film distribution are the dual-contract
architecture (§3), the modular rights-stacking mechanism (§4), the
threshold-mediated access control model (§8), the permanence
guarantee (§9), the Seed-network distribution model (§10), the
publisher-author distinction with royalty-shareholder distribution
(§11.2–§11.3), and the LMA token's burn-from-fee value-capture
mechanism (§11.8).

## 18. Conclusion {-}

We have proposed a protocol for film distribution addressing
fundamental misalignments in centralized streaming. By tokenizing
films into standardized units with embedded licensing rights, we
create genuine digital ownership. By distributing content through a
peer-to-peer network growing stronger with demand, we invert
economics that punish platforms for success. By automating royalty
distribution including on secondary sales, we ensure transparent
creator compensation through markets that never existed for physical
media.

Threshold-mediated key release replaces the legacy derivable-key
construction as the production cryptographic model. Access to a
film's decryption material is gated by current on-chain ownership at
decryption time, evaluated by a threshold network rather than by any
single party. The protocol claims, and intends to demonstrate,
security equivalent to or stronger than legacy hardware-attested
DRM. Forward-compatible support for hardware-attested key wrapping
exists as a capability for licensing relationships predicated on
legacy industry frameworks, governed by a federated issuance
framework structurally independent from any commercial operator; we
expect those frameworks to evolve toward recognizing threshold
cryptography directly, and the protocol's center of gravity is
positioned accordingly.

The separation of distribution tokens from copyright ownership
enables fluid rights markets while preserving creator control over
intellectual property. Commercial exhibitors can acquire rights
directly from collectors. Studios can acquire copyright for
derivative works without disrupting existing token markets. Rights
flow to natural owners through market mechanisms rather than
negotiated deals.

A dedicated Layer-2 chain, a single coordination token, an
independent foundation, and a federated attestation framework
together produce a protocol whose external dependencies sunset over a
defined three-year horizon. The protocol's intellectual integrity
does not require any commercial entity's continued existence; the
chain remembers, the network distributes, the contracts execute.

The protocol requires no permission from existing gatekeepers.
Public-domain content bootstraps the network, demonstrating
capabilities before commercial titles join. As the network grows,
established platforms face a choice: implement the protocol and
benefit from its efficiencies, or cede ground to peer marketplaces
and competitors that do.

LMAP represents not disruption but recoherence — using peer-to-peer
technology once deployed to undermine the industry to instead
restore fair compensation and sustainable economics. The same
distributed networks that enabled unauthorized copying can now
enable legitimate, liquid, permanent ownership. *In the venom, the
antidote.*

## 19. Bootstrap Roadmap {-}

The protocol's external dependencies are explicitly bootstrap-only.
Each is replaced by an LMAP-native substrate on a defined timeline.

**Year 0 — Bootstrap.** The protocol operates on Polygon mainnet
with the V4.1 registry contract. Threshold-mediated key release runs
against Lit Protocol's Naga mainnet. Content storage uses IPFS with
a centralized pinning service operated by the first commercial
implementation as a high-availability substrate. The foundation is
in formation; the Liquid Media Chain is in design; LMA does not yet
exist on-chain.

**Year 1 — Native Substrate Launch.** The Liquid Media Foundation
incorporates as a Cayman Foundation Company. The Liquid Media Chain
launches as a Polygon CDK zero-knowledge rollup with LMA as native
gas. LMAP V5 contracts deploy natively on the chain. The LMA token
launches under foundation operation. The LMAP-native threshold
network deploys with foundation-operated bootstrap nodes plus
permissionless stake-based participation. The storage-provider
registry and proof-of-retrievability mechanism activate. New content
defaults to the LMAP-native threshold network increasingly through
the year. Periodic LMA burn auctions begin operation.

**Year 2 — Dependency Sunset.** All production content has migrated
to the LMAP-native threshold network. The Lit Protocol dependency is
retired. The centralized pinning fallback is decommissioned. The
attestation framework's first federation milestone is achieved (at
least one independent issuer beyond the foundation co-signs
attestation credentials). The Liquid Media Chain sequencer begins
decentralization via stake-based consensus.

**Year 3 — Mature Operation.** Token-holder governance replaces
foundation-board veto for protocol parameter changes. The attestation
framework operates with multiple federated issuers. The chain operates
with decentralized sequencer consensus. The protocol's external
dependencies are fully resolved; the protocol operates self-sufficiently
on its own substrate.

This roadmap is a public commitment, not a roadmap of intent. Each
milestone is a defined deliverable with a published acceptance test;
the foundation's annual report enumerates progress against each.

## Implementation Status Summary {-}

A precise summary of the protocol's components by their status as of
this paper's publication:

- **Shipped (legacy V4.1 deployment on Polygon mainnet):** ERC-1155
  distribution registry at
  `0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D`; role-gated minting
  for the bootstrap deployment; modular rights stacking; chunked
  AES-256-GCM encryption; legacy deterministic key derivation (now
  scoped to public-domain demonstration content, not for new
  production); self-contained manifest reading from on-chain
  metadata + IPFS, with storage-service fallback; open-source
  reference Seed daemon (verify ownership, fetch + decrypt,
  auto-pin, LAN-stream over HTTP/mDNS); web client at wylloh.com;
  first tokenized film (*The Cocoanuts*, 1929) sold and downloaded
  end-to-end across two independent architectures (macOS arm64,
  Raspberry Pi aarch64) with byte-identical output. The V4.1
  contract continues to serve existing tokens.

- **In active migration (Year-0 bootstrap):** migration of the
  Wylloh reference web client and Seed daemon from the legacy
  derivable-key construction to threshold-mediated key release via
  Lit Protocol's Naga mainnet. Completion of this migration is a
  blocking prerequisite for tokenizing any commercial content; the
  V4.1 deployment continues to serve already-tokenized public-domain
  content under the legacy construction during and after the
  migration.

- **Specified, in active implementation (V5 on Polygon mainnet
  during Year 0; on Liquid Media Chain from Year 1):** the
  LMAPRegistryV5 reference contract under foundation governance —
  adds the three-way revenue split (§11.1), publisher/author
  distinction (§11.2), royalty shareholder distribution (§11.3),
  atomic batch acquisition for rights stacking (§11.5), `mediaType`
  field for media-agnostic operation, updateable platform treasury
  via multi-sig timelock, ERC-4337 paymaster hooks, and
  permissionless minting (§16.5). Scaffold with passing tests;
  full marketplace implementation, comprehensive test coverage, and
  deployment under foundation governance are 2026 milestones.

- **Specified, foundation-formation work (Year 0):** Cayman
  Foundation Company incorporation; securities-counsel review of
  the LMA token structure; constitution of the foundation board;
  publication of the verified-publishers registry; constitution of
  the first attestation issuer.

- **Specified, Year-1 deployment:** the Liquid Media Chain as a
  Polygon CDK zero-knowledge rollup; LMA token launch; LMAP-native
  threshold network with stake-based participation; the storage-
  provider registry and proof-of-retrievability mechanism; periodic
  LMA burn auctions; LMAP V5 contracts on the chain natively;
  bridge contracts to Polygon mainnet for USDC and legacy V4.1
  holdings.

- **Specified, Year-2+ deployment:** Lit Protocol dependency sunset;
  centralized pinning sunset; first attestation-issuer federation
  milestone; sequencer decentralization to stake-based consensus.

- **Specified, future protocol versions (V6+):** ERC-721 copyright
  registry; on-chain staking for commercial-exhibition windows;
  presale-funding milestone-escrow contracts; threshold dispersal
  of ciphertext shards; the hardware-attested mode with
  **normatively-required hardware-attested per-device key wrapping**
  (§8.4). The wire-level attestation specification (report format,
  credential schema, issuer federation protocol, revocation flow)
  is committed to a separate LMAP V6 technical specification,
  forthcoming.

- **Long-horizon (operational maturity required):** studio-grade
  licensing through hardware-attested mode with major rights
  holders; full token-holder governance of protocol parameters with
  foundation-board veto retired; decentralized chain-sequencer
  consensus operating at production load.

This paper is a working specification. Components shipped today
behave as described; components specified are commitments the
protocol is engineered toward. The Liquid Media Foundation, once
formally established, will maintain this status summary as a living
public artifact.

\vspace{1em}

## Changelog {-}

**Version 3.0 (June 2026).** Substantial revision following the V5
contract-specification work and the architectural decisions of the
seed-round preparation. Four structural changes: (a) the legacy
*open tier* of the §7 cryptography framing is retired as a production
model — the deterministic key-derivation construction is reclassified
as a public-domain demonstration approach, valid for the V4.1
deployment of *The Cocoanuts* but not appropriate for new commercial
content; threshold-mediated key release becomes the production
security model. (b) The protocol claims and intends to demonstrate
security equivalent to or stronger than legacy hardware-attested
DRM through threshold cryptography with stake-based sybil resistance;
hardware attestation is reframed as forward-compatibility for
legacy industry licensing frameworks (§8.4) rather than as a
co-equal "mode" of the security architecture. The expectation is
that industry compliance frameworks evolve to recognize threshold
cryptography directly; the hardware-attested capability exists at
the periphery of the protocol's design, decreasing in significance
over time. (c) A dedicated Layer-2 chain — the *Liquid Media Chain*,
§6 — is introduced as the protocol's operational substrate, hosting
the V5 contracts and using LMA as native gas. (d) A single
coordination token — *LMA* — is introduced (§16.4) for storage
incentives (§7.1), threshold-network staking (§8.2), gas, and
value-capture via burn from protocol fees (§11.8). The foundation's
legal structure is specified as a Cayman Foundation Company
(§16.1), with the explicit caveat that this commitment precedes
formal securities-counsel review attendant to LMA token issuance
and may be revised in v3.1 should counsel recommend a structurally
superior alternative. The implementation-status summary is expanded
to reflect bootstrap, migration, and native-substrate-launch phases.
The closing line of v2.3 — *In the venom, the antidote* — is
preserved.

**Version 2.3 (May 2026).** Reference Seed daemon promoted from
"specified" to "shipped" in the Implementation Status. §9 (Seed
Network) updated to reflect end-to-end operation of the open-source
reference daemon on independent ARM64 hardware (Raspberry Pi 4)
with byte-identical decrypted output across architectures and no
dependency on any centralized service. §7.2 (Certified Tier) gained
a normative statement on hardware binding. A clarifying paragraph
distinguished *playback* (which requires certified hardware) from
*carriage* (which does not — tokens, encrypted content, and pinning
remain freely accessible across all hardware).

**Version 2.2 (May 2026).** V5 reference contract specification
additions. §10 (Marketplace Mechanics) substantially expanded to
specify the V5 economic model: three-way revenue split, distinct
publisher/author identities, royalty shareholder distribution
supporting up to 50 collaborators per title, atomic batch
acquisition for rights stacking, and an honest articulation of the
royalty enforcement boundary. §15 (Governance) updated to reflect
V5's permissionless minting model.

**Version 2.1 (May 2026).** Rebrand pass under Liquid Media
Foundation stewardship. The protocol — previously referred to
internally as "Wylloh" — is renamed *LMAP* (Liquid Media Access
Protocol) to formalize the separation between the open standard
(LMAP, stewarded by the foundation) and the first commercial
implementation (Wylloh, the company building the reference
hardware and storefront).

**Version 2.0 (April 2026).** Comprehensive revision following the
April 2026 mainnet launch and the architectural pivot to the
headless-Seed network. Key additions: layered architecture, two-tier
attestation model (now superseded by §8's threshold-mediated
release with optional hardware-attested mode), permanence
guarantees, governance and the foundation, comparison with prior
work.

**Version 1.0 (April 2026).** Initial publication.

\vspace{1em}

## References {-}

[^1]: W. Radomski et al., "EIP-1155: Multi Token Standard," Ethereum
  Improvement Proposals, 2018.

[^2]: W. Entriken et al., "EIP-721: Non-Fungible Token Standard,"
  Ethereum Improvement Proposals, 2018.

[^3]: J. Benet, "IPFS — Content Addressed, Versioned, P2P File
  System," arXiv:1407.3561, 2014.

[^4]: Trusted Computing Group, "TPM 2.0 Library Specification,"
  trustedcomputinggroup.org, current edition.

[^5]: H. Birkholz et al., "Remote ATtestation procedureS (RATS)
  Architecture," IETF RFC 9334, January 2023.

[^6]: V. Buterin et al., "ERC-4337: Account Abstraction Using Alt
  Mempool," Ethereum Improvement Proposals, 2021.

[^7]: Protocol Labs, "Filecoin: A Decentralized Storage Network,"
  filecoin.io technical specification.

[^8]: V. Buterin, "Ethereum: A Next-Generation Smart Contract and
  Decentralized Application Platform," 2014.

[^9]: A. Shamir, "How to Share a Secret," *Communications of the
  ACM*, vol. 22, no. 11, pp. 612–613, 1979.

[^10]: S. Nakamoto, "Bitcoin: A Peer-to-Peer Electronic Cash System,"
  2008.

[^11]: H. Krawczyk and P. Eronen, "HKDF: HMAC-based Extract-and-Expand
  Key Derivation Function," IETF RFC 5869, May 2010.

[^12]: ARM Limited, "ARM TrustZone Technology," developer.arm.com,
  current edition.

[^13]: Polygon Labs, "Polygon CDK: A Framework for Sovereign
  ZK-Rollups," docs.polygon.technology, current edition.

[^14]: T. Beiko, A. Davidson, V. Buterin et al., "EIP-1559: Fee
  Market Change for ETH 1.0 Chain," Ethereum Improvement Proposals,
  2019.

[^15]: W. Stewart, J. Galindo, "EIP-4361: Sign-In with Ethereum,"
  Ethereum Improvement Proposals, 2021.

[^16]: D. Hyun et al., "Lit Protocol: Decentralized Access Control
  with Threshold Cryptography," developer.litprotocol.com, current
  edition.
