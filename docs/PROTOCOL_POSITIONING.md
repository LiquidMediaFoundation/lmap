# LMAP — Positioning

> A living document on what LMAP is, what it isn't, and how it
> relates to the clients, hardware, and marketplaces that build on it.
>
> **Status:** Living document — **aligned to whitepaper v2.5 (July
> 2026); pending external re-review.** The whitepaper (v2.5),
> `PROTOCOL_LAYERS.md`, and `DEVICE_COMPLIANCE_AND_ACCESS_CONTROL.md`
> remain canonical for engineering detail; this doc carries the
> strategic and positioning framing. A full v2.5 alignment pass has
> been applied: sealed direct-player as the primary surface, the
> compliant tier as the day-1 (Seed-gated) launch mechanism, the
> on-chain binding registry that *informs but never gates*, the
> threshold-released open tier (legacy public-data derivation retired),
> 97.5%-of-list-price economics, Foundation-board governance, and
> Apache-2.0.
>
> Opening sections are written to potentially become web copy. Later
> sections go deeper.
>
> **Companion:** `docs/PROTOCOL_LAYERS.md` — the layered engineering
> reference for what each layer of the protocol does.

---

## 1. A protocol, not a platform

**LMAP is the protocol.** Like DVD. Like USB. A standard, a set of
specifications and immutable smart contracts that anyone can implement
and build on. LMAP itself is not something most consumers ever need
to think about, in the same way most consumers never had to think
about the DVD specification when they bought a movie at a store.

What consumers experience is **liquid media** — a generic, public term
for the category LMAP enables. *Liquid media* is to streaming
services what *physical media* was to broadcast television: a different
form of ownership, with different rights, that buyers can hold,
transfer, and pass on.

The terms relate like this:

- **LMAP** = the protocol (the specification)
- **liquid media** = the public category term (the consumer language)
- **the Origin** = a reference Seed device that implements the protocol
- **wylloh.com** = the first storefront and reference web client
- A future commercial entity may operate hardware, marketplaces, or
  platforms built on the protocol. Such an entity would be a
  *participant* in the LMAP ecosystem, not its operator. Names and
  scope: TBD.

The discipline of separating protocol from platform is the discipline
that lets every adopter — filmmakers, third-party storefronts,
hardware manufacturers, eventually studios — build on LMAP without
fearing that the protocol's stewards are also their competitors. It is
the same discipline that lets Filecoin be a protocol distinct from
Protocol Labs, that lets Ethereum be distinct from any single
Ethereum company.

The protocol lives on Polygon as a set of immutable smart contracts.
Anyone can read from it. Anyone can build clients on top of it.
Minting new films is role-gated today (see §8) — a deliberate
editorial gate during the protocol's early life, not the end state.
No company owns the protocol. No server can turn it off.

---

## 2. The token is the license. The bytes are just bytes.

LMAP uses encryption. The Seed is hardware-bound. But the
protocol's primary mechanism is not technical enforcement — it is the
legibility of ownership on a public ledger.

The token you hold is the provable thing: publicly verifiable on
Polygon, tradable, inheritable, permanent. The MP4 you download is a
file. If you lose it, download it again. If someone copies it off
your hard drive, the copy has no ownership weight; the blockchain
knows whose wallet holds the token.

This is a balance, not an absolute. On the Seed — where we invest in
hardware-bound encryption and streaming decrypt — extraction is
genuinely hard. In the browser, the file lands in your Downloads
folder and the rest is up to you. Different edges, different
trade-offs, the same user served at different moments.

Where cryptography would require treating our audience as adversaries,
we lean on trust and social incentive instead. The film community is
not a threat to be controlled — it is the reason any of this exists.

> _"If you don't trust the people, you make them untrustworthy."_
> — Lao Tzu, _Tao Te Ching_ (tr. Stephen Mitchell)

**Our mission is twofold:** ensure fair compensation for filmmakers so
independent film stays sustainable, and earn the trust of audiences
and collectors so the community grows the right way. Each depends on
the other. A marketplace that doesn't pay filmmakers fairly starves
the work. A marketplace that treats its audience as pirates poisons
the relationship. LMAP tries to do neither.

**What this means in practice:**

- **Lenient on downloads (open tier).** Open-tier content can be
  downloaded as many times as you want, to as many devices as you
  want — unmetered, trustless. Compliant-tier content instead *binds*
  one active copy per unit owned: you can hold as many copies as
  units and move or sell any of them, but a given unit plays on one
  device at a time. Two honest models for two kinds of content.
- **Honest about each edge.** The browser leaves a plaintext file; the
  Seed does not. Users can pick the edge that fits their values.
- **Strict where it's the premium.** The Seed is the sovereignty
  tier. That's where extraction resistance earns its keep, because
  that's where collectors are paying for a physical-media feel.
- **Social before cryptographic.** Where a technical measure would
  punish honest users more than it protects filmmakers, we choose
  trust.

---

## 3. The protocol fee

Every sale that routes through the LMAP registry contract pays a 2.5%
**protocol fee**. This fee is not a platform fee, and the distinction
matters.

- A platform fee is rent extracted by a marketplace for matching
  buyers with sellers.
- A protocol fee is shared infrastructure compensation — pinning
  redundancy on IPFS, contract auditing, security work, open-source
  development, the costs of keeping the network resilient.

The 2.5% is stable, legible, and the same for every marketplace built
on LMAP, and cannot be waived per-sale. Protocol parameters are not
unilaterally alterable: any change occurs only through the
Foundation's governance, via a public multi-sig timelock — never by a
single operator and never per-sale. The protocol treasury is governed
by the **Liquid Media Foundation** — an independent foundation with an
independent-majority board, *not* a protocol-token holder vote (v2.4
removed the token concept) — bootstrapped by the founding team and
federating to that board over time.

**The one constant is the protocol's 2.5%.** It is the same on every
sale, through any marketplace, and cannot be waived per-sale. The
other **97.5% stays on the rights-holder side** — but how it divides
depends on how the film was minted, and that part is *variable*:

- **Self-minted:** the filmmaker is the publisher and keeps the full
  97.5%.
- **Minted through a publishing platform:** that platform sets a
  **publisher fee — 0–25%, variable, chosen by the minting platform at
  mint** — which comes *out of* the 97.5%; the author receives the
  remainder (as low as 72.5%). The fee is fixed for that title once
  minted and disclosed up front (whitepaper §10.1).

So "97.5%" is the rights-holder-side total after the protocol's flat
cut — *not* a flat number the filmmaker always pockets; the publisher
fee is the variable, set by the minting platform. Separately, a
third-party marketplace *reselling* a title may add its own markup
*on top* of the list price — paid by the buyer as the cost of that
marketplace's service — but it cannot reach into the 97.5%. The
rights-holder share never leaves the people who made and released the
film for a platform.

---

## 4. Third-party marketplaces are peers, not competitors

Because the fee is at the protocol layer, other marketplaces built on
LMAP are not in economic conflict with wylloh.com. They pay the
same 2.5% protocol fee and can layer their own commercial markup on
top — typically a marketplace fee for discovery, curation, or
audience.

A user buying the same film on two different LMAP-compatible
marketplaces might see:

```
wylloh.com:        $4.99  ($0.12 protocol fee, $4.87 to filmmaker)
indiemarket.tv:    $5.49  ($0.12 protocol fee, $0.50 marketplace,
                           $4.87 to filmmaker)
```

The rights holder's share is identical. The marketplace competes on
service, not on undercutting the protocol. The honest reading: the
rights-holder side receives 97.5% of the *list price* set ($4.87 of
$4.99) in both cases; indiemarket's $0.50 is a markup added *on top*,
so the buyer pays $5.49 while the rights-holder take is untouched.
"97.5%" is of the list price — not of whatever a marketplace chooses
to charge above it. (This example is self-published, so the filmmaker
*is* the rights holder and keeps the full $4.87; had it been minted
through a publishing platform, that platform's variable fee would
split the $4.87 per §3 — the protocol's 2.5% is the only constant.)

This makes LMAP valuable to other marketplaces: we are their shared
plumbing, not their rival. A film minted on LMAP is portable to any
LMAP-compatible marketplace, and its provenance is permanent
regardless of where the next sale happens.

---

## 5. Clients and edges

The protocol is one thing. Clients that talk to it are many. Each
client makes its own tradeoffs about where plaintext content lives
and how hard extraction is.

| Client | Download | At rest | Extraction resistance |
|---|---|---|---|
| **wylloh.com (browser)** | Encrypted → streaming decrypt in memory → plaintext MP4 to Downloads folder | Plaintext | None, by design |
| **Wylloh Seed** (sealed direct player) | Encrypted → decrypts inside the sealed player → displayed on its own output | Encrypted, hardware-bound | Strong (compliant tier; measured robustness parity with commercial DRM is a property to be earned, not yet asserted — WP §7.4) |
| **Wylloh Roku / Apple TV / iOS app** | Open-tier LAN streaming from a paired Seed; phone-as-remote | No persistent local copy | Open-tier only (not the compliant path) |
| **Third-party clients** | Client's choice | Client's choice | Client's choice |

Each serves a different use case:

- The **browser** is the onboarding surface. Zero install. Plaintext
  output. This is where new users meet LMAP. We do not fight them.
- The **Seed** is the sovereignty tier — a sealed **direct player**
  that decrypts and displays compliant-tier content within one
  device. Extraction-resistant by design. For collectors who want a
  physical-media feel without the DIY friction of Plex. (Its
  companion apps on Roku / Apple TV / iOS serve *open-tier* LAN
  streaming to other rooms and phone-as-remote; compliant-tier
  premium content plays on the sealed player alone.)
- **Third-party clients** are welcome. They inherit the protocol,
  make their own UX choices, pay the same 2.5% fee.

See `docs/seed-one/ARCHITECTURE.md` for the Seed architecture (sealed
direct player; companion client apps serve open-tier LAN streaming
and phone-as-remote). *(Internal reference — not yet published in this
repository.)*

---

## 6. The player is the surface; the apps extend it

The **sealed direct player** is the primary living-room surface: it
connects to the TV and renders compliant-tier content on its own
output — the only place endpoint protection is coherent (whitepaper
§9). Branded Wylloh **companion apps** for Roku, Apple TV, and iOS are
secondary clients: they serve *open-tier* LAN streaming to other rooms
and act as phone-as-remote, reaching devices users already own. They
are a meaningful part of the experience — but never the path for
compliant-tier premium content, which plays on the sealed player
alone.

The order of build (companion apps):
1. **Roku app** — lowest dev friction, biggest US TV install base
2. **Apple TV app** — premium UX expectations, brand alignment
3. **iOS app** — phone-as-remote and open-tier LAN streaming
4. **Android TV / Fire TV / smart TV native apps** — later

Each companion app is a thin client over the Seed's LAN-served Wylloh
API.
The Wylloh brand shows up in typography, in the curatorial-shelf
metaphor, in moments of warmth — but the navigation, remote bindings,
and platform-native gestures all belong to the host platform. We
don't fight Roku's UX conventions; we live within them.

A desktop app (macOS/Windows/Linux) is not on the near-term roadmap.
The browser plus the Seed plus the TV-platform apps cover every edge
that matters for v0. Desktop app revisits if/when adoption data
shows demand.

---

## 7. Two tiers, one protocol — open and compliant

The architectural answer to the open-protocol-vs-studio-trust tension
lives at the *attestation layer*, not the *encryption layer*. Both
tiers run the same eight-layer protocol underneath; the gating is
narrow.

**Open tier.** Any Seed implementation that follows the spec serves
content licensed under permissive terms — public domain, Creative
Commons, indie creators who opt in. Encryption is AES-256-GCM with
threshold-mediated key release through a **native** access layer
(substrate-independent, operated and progressively decentralized by
the Foundation's federated framework — never rented from or revocable
by an outside party; the earlier deterministic key-derivation
construction is retired for production use and survives only for the
V4.1 deployment of public-domain content). Under the legacy V4.1 construction, once a holder has the encrypted master key,
decryption can happen forever, with or without any Wylloh-operated
service. **This particular permeability is a property of the legacy
demonstration construction, not the production protocol.** A developer
with the public docs could write a 50-line CLI that downloads and
decrypts a *legacy public-domain* LMAP title without touching any
Wylloh server — a concrete proof of the open spec. Production content
(threshold-released open tier, or compliant-tier binding) needs a
network round-trip to obtain a key; the protocol's platform-
independence rests not on that permeability but on its open
specification, on-chain ownership, and permissionless implementations
— no single company's servers in the path.

**Compliant tier.** Seeds carrying hardware attestations from the
Foundation's certification authority (single at launch, federating
over time). This is the **day-1 launch mechanism** for premium /
endpoint-protection-required content — the flagship first release is
Seed-gated and rides this tier — and the same certification path
extends to studio-licensed content as a long-horizon step. Revocable.
Audited. Content keys are wrapped per-device, unwrappable only inside
the Seed's secure element. Compromising one compliant Seed yields
*that Seed's local content only* — a constant per-compromise bound,
with no catalog-scale master secret. (Per-title leak probability still
grows with holder count; that residual is bounded by watermark
attribution and revocation, not cryptography — and that bound is
itself *conditional* on integrating a measured watermark scheme; see
whitepaper §7.4–§7.5.) This constant-per-compromise property is what
makes credible premium and studio engagement possible without breaking
the protocol's openness; measured robustness *parity* with commercial
DRM is a property to be earned through a published robustness
specification and independent review, not asserted (whitepaper §7.4).

**Both tiers run the same protocol.** A user's library aggregates
content from both tiers under one unified interface. Storefronts can
sell into either tier. Playback clients support both. The gating is
narrow: hardware attestation for premium content keys.

| Property | Open tier | Compliant tier |
|---|---|---|
| Trust anchor | Wallet identity | Wallet + secure-element-attested device |
| Encryption | AES-256-GCM + threshold-mediated key release (legacy public-data derivation retired to public-domain demo) | AES-256-GCM + per-device-wrapped keys |
| Hardware required | None (any conformant Seed) | Compliant Seed with secure element |
| Content scope | Public domain, indie, Creative Commons, paid indie | Premium / endpoint-protection-required |
| Implementation status | Shipped (public-domain); threshold migration in progress | Day-1 launch mechanism (Seed-gated); wire specs in active specification |

**The critical invariant: the ownership token is always yours to
move.** The token is provably owned on-chain and is the license
itself, and it **transfers freely at all times** — the binding
registry *informs, it never gates*. In the compliant tier a bound unit
is normally *released* (its copy erased) before it **trades without
residual**, so `transferable = balance − boundCount`; but that is a
norm for clean trade, not a lock on transfer — a holder can always move
the token (a raw out-of-escrow move just leaves a watermarked,
physical-media-tier residual). Attestation governs what a device may do
with decrypted frames, and binding governs how many live copies a
wallet runs at once; neither can prevent a wallet from *holding* or
*transferring* the token it owns.

The two-tier model is the layered story that lets LMAP serve both
permissive indie content (the open tier — sufficient, and aligned with
the trust philosophy) and premium content (the compliant tier) from
day one, with major-studio licensing a natural long-horizon extension
of the same certification mechanism. The flagship first release leads
with the compliant tier (Seed-gated); none of it touches the protocol
or the token model. It is not a compromise of the sovereignty
thesis — it is the sovereignty thesis surviving contact with industry
reality.

For VC framing: this is engineering maturity, not weakness.
*"The open tier gives us honest access control for permissive content
today; the compliant tier — attested per-device binding on a sealed
player — is the launch mechanism for premium content, and the same
certification path extends to studio licensing when those
relationships warrant it. We are not retrofitting DRM; endpoint
protection is a scoped, known engineering deliverable we are executing
now."*

See `docs/PROTOCOL_LAYERS.md` §7 for the technical detail of the
attestation layer, and `docs/seed-one/ARCHITECTURE.md` *(internal —
not yet published in this repository)* for how the reference Seed
supports both tiers via firmware updates without hardware changes.

---

## 8. What is open, and what reference implementations exist

The protocol is open. Reference implementations are open. Specific
hardware products and brand identities built on top can be operated
by commercial entities under their own terms. This is the same
posture that lets Filecoin be a protocol distinct from Protocol Labs,
or Ethereum a protocol distinct from any single Ethereum company.

**Open and permissionless** (Apache-2.0):
- Reading the registry (query any film, any balance, from any RPC)
- The IPFS file format (chunked AES-GCM, documented in
  `PROTOCOL_LAYERS.md` §4)
- The legacy token-based key derivation (SHA-256 of contract:tokenId,
  no secrets) — **retired as a production model** and scoped to
  public-domain demonstration content; production open-tier access is
  threshold-mediated key release (whitepaper §7.1)
- Building clients — marketplaces, players, curation layers — against
  the protocol
- Running a storage service against the protocol (the download API is
  a contract, not an LMAP-owned dependency)
- Transferring, reselling, and holding tokens — all standard
  ERC-1155 semantics, no permission needed
- The LMAP SDK and reference implementations (storage service,
  encryption library, registry interface)
- The wylloh.com web client (MIT-licensed, on GitHub)
- The Origin Seed firmware reference (will be open-sourced when the
  reference implementation reaches v1)

**Currently permissioned (by design, for now):**

- **Minting new films.** The V4.1 registry contract (immutable, on
  Polygon) has a `FILM_CREATOR_ROLE` gate on the tokenization
  function. The founding team holds `ADMIN_ROLE` and grants creator
  rights on a curated basis. This is deliberate — the small editorial
  gate that prevents the protocol from becoming an AI-slop marketplace
  before a decentralized curation mechanism is designed.
- **Path to decentralization.** Future protocol versions (V5+) will
  replace role-based minting with something permissionless:
  staking-backed minting, reputation-weighted onboarding,
  DAO-governed creator admission, or a multi-layer filtration design
  (reverse-osmosis through protocol / platform / community). This
  deserves its own doc (future `CURATION.md`).
- **How filmmakers mint today.** Contact the founding team.
- **Compliant-tier content key issuance.** The compliant tier is the
  day-1 launch mechanism; content-key wrapping for premium material is
  gated by hardware attestation (Layer 5). The certification authority
  is LMF-only at launch, with a public commitment to federate at a
  network-maturity threshold that is itself a near-term deliverable to
  define and publish (not yet set).

**Commercial products built on top of the protocol** (operated under
their own commercial terms):

- **The Origin** — a reference Seed device, manufactured as a
  commercial good. The firmware reference is open; the manufactured
  hardware (industrial design, brand, packaging, support) is a
  commercial product.
- **Branded client apps** for Roku, Apple TV, iOS — distributed
  through their respective stores under commercial terms; reference
  implementations may be open-sourced separately.
- **Wylloh-operated storage and pinning service** — the API contract
  is documented and replicable; the operated instance is a commercial
  service.
- **Future commercial entities** built on top of the protocol —
  storefronts, hardware brands, marketplace operators — would each be
  participants in the LMAP ecosystem, not its operators.

**The frame for VCs:**

- **Crypto-native investors** (a16z Crypto, Polychain, Variant,
  Protocol Labs, 1confirmation): the protocol is open, credibly
  neutral, Apache-2.0-licensed. Every film minted on LMAP is portable
  to any third-party marketplace. This is the open-protocol play.
- **Hardware/infrastructure investors** (Playground Global, 1517
  Fund, Foundry): the consumer products built on the protocol —
  starting with the Origin Seed — are commercial, defensible by
  brand, by filmmaker relationships, by the canonical-default status
  that comes from being first and being polished.
- **Strategic investors** (broadcaster M&A arms, studio ventures,
  former-streamer founders as angels): the long-horizon ecosystem —
  studios licensing into the compliant tier, integrators deploying
  into luxury homes, third-party storefronts — only works because
  the protocol stays neutral.

**The moat is not secret code.** The moat is being the canonical
default, having the filmmaker relationships, having shipped the
polished reference Seed, having earned the trust signal. None of that
requires closed-source on the protocol layer.

**The frame:** the protocol is the public good; the products are the
business. Crypto-native investors get a credibly-neutral open
protocol. Traditional consumer investors get a defensible commercial
product line. The same playbook that built Stripe, MongoDB, and the
Filecoin/Protocol Labs structure.

---

## 9. What this means for filmmakers

If you tokenize a film on LMAP:

- The protocol takes a flat 2.5%, forever, on every sale through any
  marketplace; the other 97.5% stays on your side. If you self-mint you
  are the publisher and keep the whole 97.5%; if you release through a
  publishing platform, its fee (0–25%, set at mint) comes out of that
  97.5% and you keep the remainder. A reselling marketplace's markup
  rides *on top*, paid by the buyer — never subtracted from your share.
- Your film is portable to any LMAP-compatible marketplace
- Your audience can buy it on wylloh.com, a third-party marketplace,
  or directly from a Seed you host yourself
- The token is the license; your audience can lose the file and
  re-download without re-paying
- If wylloh.com disappears tomorrow, the protocol still works — your
  audience can still buy, download, and play

This is a different relationship than a streaming deal. You are not
renting your film to Netflix. You are minting a durable instrument on
a public ledger and allowing many marketplaces to distribute it. The
protocol is the common layer. Everything else is a surface.

---

## 10. Open questions

- **Governance of the protocol fee.** The 2.5% is immutable today,
  routed to a treasury stewarded by the founding team. Long-term, it
  moves to the **Liquid Media Foundation's independent-majority board**
  — *not* a protocol-token holder vote (the v2.4 design removed the
  token concept; see §3). The federation timeline for that transition
  is a near-term deliverable to define.
- **Native apps priority.** Build mobile/desktop in 2027? Later?
  Never? Depends on Seed adoption curve and third-party client
  appetite.
- **Third-party marketplace tooling.** At what point do we ship an
  SDK/template for other marketplaces, and how do we avoid that
  becoming a full-time support burden?
- **Cross-chain.** Polygon-only today. Films on Base, Optimism,
  Ethereum, Solana? Protocol says yes eventually; near-term
  complexity says no.

---

## 11. The short version (for web copy)

> LMAP is the protocol for film ownership. Like DVD, like USB — a
> standard, not a platform. What it enables is *liquid media*:
> physical-grade ownership in liquid digital form. The token is the
> license. The bytes are just bytes. Anyone can build a storefront
> on it, anyone can build a player, anyone can build hardware — the
> protocol takes a flat 2.5% and the other 97.5% of the list price
> stays on the rights-holder side, so independent film can stay
> sustainable. The 2.5% protocol fee funds shared infrastructure, not
> marketplace rent.
>
> We encrypt where it matters and trust where it matters more.
> Lenient on downloads, strict where sovereignty is the premium.
> If you don't trust the people, you make them untrustworthy.

---

*Last updated: 2026-07-05 (full v2.5 alignment pass applied — direct-player primary, compliant tier as day-1 launch, on-chain binding registry that informs-not-gates, threshold-released open tier, 97.5%-of-list economics, Foundation-board governance, Apache-2.0; pending external re-review). Reframed §1 to clarify LMAP as the protocol
(like DVD) and "liquid media" as the public category term;
restructured §7 around the two-tier attestation model (open / compliant)
that lives at Layer 5 of the layered architecture rather than the
prior three-tier encryption framing; updated §8 to remove "open core"
language in favor of "open protocol with reference implementations";
added cross-references to `PROTOCOL_LAYERS.md` as the canonical
engineering reference. Expect revisions as the protocol matures.*
