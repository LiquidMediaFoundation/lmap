<div class="titleblock">

# LMAP — Liquid Media Access Protocol {.title}

#### A Peer-to-Peer Protocol for Media Distribution and Ownership {.subtitle}

Harrison Kavanaugh  ·  contact\@liquidmediafoundation.org

*Version 2.3 — May 2026*

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
is stored on a content-addressed network. Two attestation tiers
coexist within the protocol: an *open tier* that uses
deterministically-derivable keys for permissive content, intentionally
permeable to preserve platform-independent ownership; and a *certified
tier* that uses hardware-attested per-device key wrapping for
content where contractual digital-rights management is required. A
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
specified for a future protocol version (V5+) and has not yet been
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
| 2 | Cryptography | Encryption, key hierarchy, dispersal, watermarking |
| 3 | Entitlement | Smart contracts: distribution + copyright registries, royalties, rights tiers |
| 4 | Network | Peer discovery, shard request/response, LAN streaming |
| 5 | Attestation | Open tier / certified tier hardware attestation |
| 6 | Application | Storefronts, library UI, playback clients, integrator tooling |
| 7 | Governance | Foundation structure; federated certification; protocol governance |

A storefront (Layer 6) only needs to read entitlement (Layer 3); a
Seed manufacturer needs to implement Layers 1, 2, 4, and optionally
5; an academic auditor of the certified tier only needs to engage
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
in the protocol specification; any compliant client can implement
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

## 7. Cryptography and the Two-Tier Attestation Model {-}

The protocol resolves the open-protocol-versus-studio-trust tension
at Layer 5 (attestation), not at Layer 2 (encryption). Two tiers run
the same protocol underneath; the gating between them is narrow and
hardware-attested.

### 7.1 Open Tier {-}

Any compliant Seed implementation serves content licensed under
permissive terms — public domain, Creative Commons, indie creators
who opt their content into open-tier distribution.

In the open tier, a film's master content key is derivable from
public on-chain data using a documented formula:

\begin{center}
\texttt{key = SHA-256(contract\_address \textbar\textbar\ ":" \textbar\textbar\ token\_id \textbar\textbar\ ":wylloh-v1")}
\end{center}

The encrypted master key, in turn, is delivered to a buyer by a
storage service after that service verifies on-chain that the
buyer's wallet holds at least one token. Once the buyer has the
encrypted master key, derivation of the decrypting key is purely
local and does not depend on any external service.

This permeability is a deliberate design choice. **A developer with
the public protocol specification could write a fifty-line program
that downloads and decrypts an LMAP-tokenized film without ever touching any
Wylloh-operated server.** The open tier accepts this and makes it
explicit, because the alternative — wallet-bound or
service-dependent decryption — would break the platform-independence
guarantee that gives the protocol its long-term value.

In open-tier security terms, this is approximately DVD-level
protection. A determined party with technical knowledge can extract
plaintext; the casual sharing case ("burn a copy and hand it to a
friend") does not extract anything that the friend could not have
purchased themselves for $4.99 USDC. Defense rests on social
incentive, the ease of legitimate purchase, and the alignment of
buyers with creators — not on cryptographic enforcement against
sophisticated extraction.

### 7.2 Certified Tier {-}

Studios and rights holders who require contractual digital-rights
management cannot use the open tier as-is. The certified tier
provides hardware-attested per-device key wrapping for content where
this is required.

In the certified tier:

- Each certified Seed holds a per-device keypair generated inside its
  hardware secure element. The private key is non-extractable.
- Content keys are wrapped to each certified Seed's public key.
  Compromising one certified Seed yields *that Seed's local content
  only*; the network's aggregate exposure does not grow with the
  network's size.
- Wrapped keys are unwrapped only inside the secure element. The
  unwrapped key never appears in main memory or on persistent storage
  outside the secure perimeter.
- Issuance of a wrapped key requires the Seed to present a fresh
  *attestation report* signed by its secure element, containing
  current firmware measurements. The report is verified against the
  Seed's attestation credential before any wrapped key is issued.

Reference hardware for the certified tier includes ARM
TrustZone [^12]-capable SoCs with discrete secure elements (e.g.,
NXP SE050 or equivalent), or platforms with TPM 2.0 [^4] support.
Remote attestation [^5] follows established patterns from
contemporary trusted-computing literature. Per-title content keys
are derived from a master with HKDF-style domain-separated key
derivation [^11] to prevent key reuse across titles.

**Hardware binding is a normative requirement of the certified tier.**
A compliant certified-tier implementation MUST use a hardware secure
element to (a) generate the per-device keypair, (b) hold the private
key in non-extractable form, (c) perform key unwrapping, and (d) sign
attestation reports. An implementation that performs any of these
operations outside a hardware secure element is not conformant with
LMAP V6 and MUST NOT be marketed as such. This is the protocol-level
guarantee studios rely on when authorizing content for the certified
tier. Wire-level specifics of the attestation report format, the
attestation credential schema, and the issuer federation protocol are
committed to a separate LMAP V6 technical specification, forthcoming.

A clarifying distinction: only the *decryption* step requires
certified hardware. Encrypted certified-tier content is freely
distributable through the same content-addressed substrate as
open-tier content — any device can hold, pin, or serve it. Tokens
remain freely transferable across all wallets. The certified tier
gates *playback*, not *carriage*. This preserves user sovereignty (a
buyer's ownership is unaffected by hardware availability; they can
transfer their token at any time) while satisfying the studio
requirement (decryption is impossible without an attested secure
element). The architectural model mirrors theatrical distribution
under DCI: the encrypted DCP is portable and freely distributable;
only certified projectors with KDM-bound keys can play.

### 7.3 Attestation Issuers and the Federated Framework {-}

Attestation credentials in the certified tier are signed by
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

### 7.4 Security That Scales with Network Size {-}

Two distinct claims about how protocol security relates to network
size deserve separate treatment, because they have different
defensibility.

**Strong claim — per-device key wrapping (certified tier).**
Compromising one certified Seed yields that Seed's local content
only. The network's aggregate exposure does not grow with the
network's size, because each certified device is its own isolated
vault. This is the load-bearing security claim, and it scales
positively with the number of Seeds in the network: more participants
do not increase the attack surface against any single film.

**Modest claim — threshold dispersal of ciphertext (storage layer).**
Sharding ciphertext across Seeds raises the per-shard extraction
cost. An attacker compromising one Seed obtains a fraction of the
ciphertext for any given film; reconstruction requires reaching the
quorum threshold. This is real but bounded: a sufficiently motivated
attacker can target enough Seeds to reach quorum. The combinatorial
cost is meaningful but does not produce asymptotic security.

The protocol therefore claims that *per-device key wrapping at the
certified tier provides security that does not degrade with scale*,
and that *threshold dispersal provides resilience and modestly raises
extraction cost*. Both are valuable; only the first is the
load-bearing claim.

This precision matters for technical readers because the conventional
DRM model degrades as user base grows (more devices, more keys, more
attack surface). The certified tier inverts that property; the
storage layer's dispersal supplements it.

### 7.5 Watermarking {-}

Forensic watermarking binds a leak to a specific wallet, raising the
cost of unauthorized distribution beyond the bare cryptographic
extraction cost. In the open tier, a watermark may be inserted
server-side by a storage service when fulfilling a download. In the
certified tier, watermarks are inserted Seed-side at decryption time,
inside the secure element, before plaintext leaves the secure
perimeter.

Watermark robustness against transcoding and adversarial filtering
is an ongoing research area; commercial watermarking implementations
exist with established studio relationships. The protocol
specifications watermark insertion points but does not mandate a
particular scheme.

*Implementation status:* open tier (deterministic key derivation,
chunked AES-256-GCM, self-contained manifest reading from on-chain
metadata + IPFS, with storage-API fallback for tokens whose metadata
predates the self-contained format) is shipped and demonstrated
end-to-end on independent hardware. Certified tier (per-device key
wrapping, hardware attestation, federated issuers) is specified at
the protocol level with hardware-binding declared normative (§7.2);
the wire-level attestation specification, the framework's first
issuer, governance process, and operational maturity are forthcoming.

## 8. Permanence Guarantees {-}

The protocol commits to a permanence guarantee in both tiers: a
Seed that has legitimately acquired a license to a film at any
point in time retains the ability to play that film indefinitely,
regardless of subsequent network availability, attestation revocation,
or platform fate.

In the open tier, this guarantee is structural. The decryption key
for any owned film is derivable from public on-chain data using the
documented formula. A Seed unplugged for twenty years and plugged
back in can play any film it previously legitimately acquired, even
if the Liquid Media Foundation has ceased to exist, with zero network
connectivity, using a reference client a third party authored from
the public protocol specification. The blockchain remembers what
was bought; nothing else needs to.

In the certified tier, this guarantee is engineered. Attestation
gates the *issuance* of wrapped keys, not the *playback* of content
already keyed. A Seed whose attestation credential is later revoked
retains the wrapped keys it previously received and continues to
play the corresponding films. Revocation prevents the Seed from
acquiring further content through the certified tier; it does not
retroactively disable the Seed's existing library. This is the
architectural answer to the rugpull pattern that has characterized
streaming services and digital media stores.

The hardware itself remains a single point of failure: a Seed whose
secure element fails physically loses access to its locally-wrapped
keys. The protocol mitigates this by treating the on-chain ownership
record as the durable source of truth. A user whose Seed has died
can re-acquire wrapped keys for their owned films onto a new
certified Seed, because the wallet's holdings are recoverable from
the blockchain. **The blockchain remembers; the hardware is
replaceable.** This is a stronger guarantee than physical media,
which has no equivalent recovery path when a disc fails.

## 9. The Seed Network {-}

Content distribution operates through *Seeds* — user-operated nodes
that combine encrypted-content storage, peer-to-peer participation,
and a local LAN-streaming service for playback applications. Seeds
run on commodity hardware following published reference designs.

A Seed is a headless device. It does not connect directly to a
television; instead, it serves LMAP-registered content to client
applications running on platforms users already own — Roku, Apple
TV, iOS, the web. The user's existing remote, the user's existing
television, the user's existing input habits all remain intact. The
Seed becomes infrastructure: quiet, reliable, operated as a piece of
furniture in the home network rather than a screen in the living
room. Earlier protocol designs envisioned the Seed as a custom-UI
device that attached directly to a television; experience has shown
that a headless server paired with thin client applications on
existing platforms is simpler, more accessible, and less subject to
the obsolescence that affects custom television-UI hardware.

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
Network participation may be incentivized through future token
mechanisms (proof-of-storage rewards, bandwidth credits); in the
near term, Seeds participate by default because their primary
value to the operator is local — the films they own, accessible to
LMAP-compatible playback clients on their local network — and
network participation is a beneficial side effect rather than the
purchase rationale.

A reference Seed device — the *Origin* — is specified separately
from this paper as a buildable open-hardware design. The protocol
does not require the Origin or any particular Seed implementation;
any compliant device can participate.

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
must currently hold both USDC.e and a small amount of MATIC to
cover network gas — friction the protocol acknowledges as a
near-term limitation rather than an intended feature. The
architectural answer is account abstraction via ERC-4337 [^6]
*paymaster contracts*: a paymaster pays MATIC gas on the user's
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
viewing patterns aggregated by any party. Creators receive
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
than technological locks against the casual case; the certified
tier provides cryptographic protection against the sophisticated
case where contractual DRM is required.

Physical media operated on similar principles. Copy protection on
optical discs was trivially circumvented, yet the market thrived
for decades. Convenience, quality assurance, and social norms around
ownership provided sufficient protection. The protocol adds
financial incentives physical media lacked: ownership appreciates
in genuinely successful work, and secondary markets reward early
adoption.

A specific guidance for technical readers: when evaluating the
protocol's claims, separate the *cryptographic claim* (the certified
tier's per-device key wrapping does not degrade with network scale)
from the *operational claim* (legitimate purchase is more
economically rational than extraction for participants in the
network). Both claims hold, but they hold at different layers and
under different threat models. The whitepaper is precise about this
because the audiences this document serves — investors, developers,
and studio business affairs — read the same words and need to
extract the same meaning.

## 15. Governance and the Liquid Media Foundation {-}

The protocol is governed by an independent foundation, structurally
distinct from any commercial operator. The foundation holds the
protocol's intellectual property under a permissive open-source
license, stewards the certified-tier attestation framework,
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
  the certified tier (§7.3).
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

**Plex** demonstrates the "headless server at home plus client app
on the television" architecture at scale (over 25 million users)
with primarily user-ripped content of unclear provenance. LMAP-
compatible Seed devices inherit this architecture and address
Plex's structural limitations: no provenance, no royalty flow, no
curatorial focus, closed-source business model. The reference Seed
device extends Plex's pattern with on-chain provenance and an open
protocol.

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
two-tier attestation model (§7), the permanence guarantee (§8), and
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

The two-tier attestation model resolves the perceived conflict
between open-protocol architecture and contractual studio trust
requirements. The open tier accepts permissive content with
intentional cryptographic permeability, in exchange for the
platform-independence guarantee that makes the protocol durable.
The certified tier provides hardware-attested per-device key
wrapping for content where contractual DRM is required, governed
by a federated attestation framework structurally independent from
any commercial operator.

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

- **Shipped (legacy V4.1 deployment):** ERC-1155 distribution
  registry on Polygon mainnet at
  `0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D`; role-gated minting;
  modular rights stacking; chunked AES-256-GCM encryption;
  open-tier deterministic key derivation; self-contained manifest
  reading from on-chain metadata + IPFS, with storage-service
  fallback; open-source reference Seed daemon (verify ownership,
  fetch + decrypt, auto-pin, LAN-stream over HTTP/mDNS); web client
  at wylloh.com; first tokenized film (*The Cocoanuts*, 1929) sold
  and downloaded end-to-end across two independent architectures
  (macOS arm64, Raspberry Pi aarch64) with byte-identical output.
  The V4.1 contract continues to serve existing tokens.
- **Specified, in active implementation (V5):** the LMAPRegistryV5
  reference contract under foundation governance — adds the
  three-way revenue split (§10.1), publisher/author distinction
  (§10.2), royalty shareholder distribution (§10.3), atomic batch
  acquisition for rights stacking (§10.5), `mediaType` field for
  media-agnostic operation, updateable platform treasury via
  multi-sig timelock, ERC-4337 paymaster hooks, and permissionless
  minting (§15). Scaffold with passing tests; full marketplace
  implementation, comprehensive test coverage, and deployment under
  foundation governance are 2026 milestones.
- **Specified, in implementation (hardware and clients):** reference
  Seed device (the *Origin*); native client applications for Roku,
  Apple TV, and iOS.
- **Specified, future protocol versions (V6+):** ERC-721 copyright
  registry; on-chain staking for commercial-exhibition windows;
  presale-funding milestone-escrow contracts; threshold dispersal
  of ciphertext shards; certified-tier attestation framework with
  federated issuers and **normatively-required hardware-attested
  per-device key wrapping** (§7.2). The wire-level attestation
  specification (report format, credential schema, issuer federation
  protocol, revocation flow) is committed to a separate LMAP V6
  technical specification, forthcoming.
- **Long-horizon (operational maturity required):** studio-grade
  certified-tier engagement with major rights holders; native
  protocol token mechanics for proof-of-storage incentives.

This paper is a working specification. Components shipped today
behave as described; components specified are commitments the
protocol is engineered toward. The Liquid Media Foundation, when
formally established, will maintain this status summary as a
living public artifact.

\vspace{1em}

## Changelog {-}

**Version 2.3 (May 2026).** Reference Seed daemon promoted from
"specified" to "shipped" in the Implementation Status. §9
(Seed Network) updated to reflect end-to-end operation of the
open-source reference daemon on independent ARM64 hardware (Raspberry
Pi 4) with byte-identical decrypted output across architectures and
no dependency on any centralized service. The daemon's operating
behavior — IPFS fetch with local Kubo preference, automatic
content pinning to make the Seed a provider, LAN-streaming via
HTTP/mDNS with byte-range support — is documented as the
canonical reference behavior for compliant Seeds. §7.2 (Certified
Tier) gains a normative statement: hardware binding (SE-resident
keypair generation, non-extractable private keys, in-SE key
unwrapping, in-SE attestation signing) is a MUST for V6
conformance, and an implementation omitting any of these operations
is not LMAP-V6-conformant and MUST NOT be marketed as such. A
clarifying paragraph distinguishes *playback* (which requires
certified hardware) from *carriage* (which does not — tokens,
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
