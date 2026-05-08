# LMAP — Positioning

> A living document on what LMAP is, what it isn't, and how it
> relates to the clients, hardware, and marketplaces that build on it.
>
> **Status:** Living document. Last revised April 2026.
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

- **Lenient on downloads.** Token holders can download as many times
  as they want, to as many devices as they want. Unmetered. Trustless.
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

The 2.5% is hardcoded in the smart contract. It cannot be raised, and
it cannot be waived per-sale. It is stable, legible, and the same for
every marketplace built on LMAP. The protocol treasury — ultimately
governed by token holders, currently stewarded by the founding team —
is the recipient.

**Filmmakers keep 97.5% of every sale, regardless of which
marketplace the sale happens through.**

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

The filmmaker's share is identical. The marketplace competes on
service, not on undercutting the protocol.

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
| **Wylloh Seed** (headless home server) | Encrypted → stays encrypted on SSD → streaming decrypt to LAN client | Encrypted, hardware-bound | Strong |
| **Wylloh Roku / Apple TV / iOS app** | Streams from a paired Seed over LAN | No persistent local copy | Inherits Seed's resistance |
| **Third-party clients** | Client's choice | Client's choice | Client's choice |

Each serves a different use case:

- The **browser** is the onboarding surface. Zero install. Plaintext
  output. This is where new users meet LMAP. We do not fight them.
- The **Seed** is the sovereignty tier — a headless home server
  paired with branded client apps on the TV platforms users already
  own. Extraction-resistant by design. For collectors who want a
  physical-media feel without the DIY friction of Plex.
- **Third-party clients** are welcome. They inherit the protocol,
  make their own UX choices, pay the same 2.5% fee.

See `docs/seed-one/ARCHITECTURE.md` for the V2 Seed architecture
(headless server + client apps on Roku/Apple TV/iOS).

---

## 6. Native apps — the surface where users live

Branded Wylloh client apps for Roku, Apple TV, and iOS are a core
part of the V2 Seed architecture, not optional add-ons. They are how
users actually meet a Seed in their living room.

The order of build:
1. **Roku app** — lowest dev friction, biggest US TV install base
2. **Apple TV app** — premium UX expectations, brand alignment
3. **iOS app** — phone-as-remote, take-with-you offline mode
4. **Android TV / Fire TV / smart TV native apps** — later

Each app is a thin client over the Seed's LAN-served Wylloh API.
The Wylloh brand shows up in typography, in the curatorial-shelf
metaphor, in moments of warmth — but the navigation, remote bindings,
and platform-native gestures all belong to the host platform. We
don't fight Roku's UX conventions; we live within them.

A desktop app (macOS/Windows/Linux) is not on the near-term roadmap.
The browser plus the Seed plus the TV-platform apps cover every edge
that matters for v0. Desktop app revisits if/when adoption data
shows demand.

---

## 7. Two tiers, one protocol — open and certified

The architectural answer to the open-protocol-vs-studio-trust tension
lives at the *attestation layer*, not the *encryption layer*. Both
tiers run the same eight-layer protocol underneath; the gating is
narrow.

**Open tier.** Any Seed implementation that follows the spec serves
content licensed under permissive terms — public domain, Creative
Commons, indie creators who opt in. Encryption is AES-256-GCM with
deterministic key derivation from public on-chain data. It is
intentionally permeable: once a holder has the encrypted master key,
decryption can happen forever, with or without any Wylloh-operated
service. **This permeability is what makes the protocol genuinely
platform-independent.** A developer with the public docs could write
a 50-line CLI that downloads and decrypts an LMAP-tokenized film without ever
touching any Wylloh-operated server. That is a feature, not a
weakness — it is the sovereignty commitment made concrete.

**Certified tier.** Seeds carrying hardware attestations from a
federated certification authority. Required for studio-licensed
content. Revocable. Audited. Content keys are wrapped per-device,
unwrappable only inside the Seed's secure element. Compromising one
certified Seed yields *that Seed's local content only* — the
network's aggregate exposure does not grow with N. This is the
load-bearing security claim that makes credible studio engagement
possible without breaking the protocol's openness.

**Both tiers run the same protocol.** A user's library aggregates
content from both tiers under one unified interface. Storefronts can
sell into either tier. Playback clients support both. The gating is
narrow: hardware attestation for premium content keys.

| Property | Open tier | Certified tier |
|---|---|---|
| Trust anchor | Wallet identity | Wallet + secure-element-attested device |
| Encryption | AES-256-GCM + public-data key derivation | AES-256-GCM + per-device-wrapped keys |
| Hardware required | None (any compliant Seed) | Certified Seed with secure element |
| Content scope | Public domain, indie, Creative Commons | Studio-licensed (long-horizon) |
| Implementation status | Shipped today | Spec'd; reference implementation in development |

**The critical invariant: the ownership token never changes.** Under
both tiers, the token remains transferable, provably owned on-chain,
and executable off-platform. The token *is* the license. The
attestation tier governs what bytes a particular Seed can serve, not
what tokens a wallet can hold.

The two-tier model is the layered story that lets LMAP start with
permissive indie content (where the open tier is sufficient and
aligns with the trust philosophy) and graduate to studio relationships
(where certified-tier hardware attestation satisfies industry
contractual norms) without touching the protocol or the token model.
It is not a compromise of the sovereignty thesis — it is the
sovereignty thesis surviving contact with industry reality.

For VC framing: this is engineering maturity, not weakness.
*"We chose the simplest possible encryption to validate the protocol
with permissive content. Hardware-attested certification is a known
engineering project we'll execute when studio relationships warrant
it."*

See `docs/PROTOCOL_LAYERS.md` §7 for the technical detail of the
attestation layer, and `docs/seed-one/ARCHITECTURE.md` for how the
reference Seed supports both tiers via firmware updates without
hardware changes.

---

## 8. What is open, and what reference implementations exist

The protocol is open. Reference implementations are open. Specific
hardware products and brand identities built on top can be operated
by commercial entities under their own terms. This is the same
posture that lets Filecoin be a protocol distinct from Protocol Labs,
or Ethereum a protocol distinct from any single Ethereum company.

**Open and permissionless** (MIT or Apache-2.0):
- Reading the registry (query any film, any balance, from any RPC)
- The IPFS file format (chunked AES-GCM, documented in
  `PROTOCOL_LAYERS.md` §4)
- The token-based key derivation (SHA-256 of contract:tokenId, no
  secrets)
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
- **Certified-tier content key issuance.** Once the certified tier
  ships, content key wrapping for studio-licensed material is gated
  by hardware attestation (Layer 5). The certification authority is
  LMF-only at v1, with a public commitment to federate
  at a defined milestone.

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
  neutral, MIT-licensed. Every film minted on LMAP is portable to
  any third-party marketplace. This is the open-protocol play.
- **Hardware/infrastructure investors** (Playground Global, 1517
  Fund, Foundry): the consumer products built on the protocol —
  starting with the Origin Seed — are commercial, defensible by
  brand, by filmmaker relationships, by the canonical-default status
  that comes from being first and being polished.
- **Strategic investors** (broadcaster M&A arms, studio ventures,
  former-streamer founders as angels): the long-horizon ecosystem —
  studios licensing into the certified tier, integrators deploying
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

**The moat is not secret code.** The moat is being the canonical
default, having the filmmaker relationships, having shipped the
polished apps, having earned the trust signal. None of that requires
closed-source on the protocol layer.

---

## 9. What this means for filmmakers

If you tokenize a film on LMAP:

- You keep 97.5% of every sale, forever, regardless of marketplace
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
  should move to holder governance. That's a separate doc.
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
> on it, anyone can build a player, anyone can build hardware — and
> filmmakers keep 97.5% of every sale, so independent film can stay
> sustainable. The 2.5% protocol fee funds shared infrastructure,
> not marketplace rent.
>
> We encrypt where it matters and trust where it matters more.
> Lenient on downloads, strict where sovereignty is the premium.
> If you don't trust the people, you make them untrustworthy.

---

*Last updated: 2026-04-28. Reframed §1 to clarify LMAP as the protocol
(like DVD) and "liquid media" as the public category term;
restructured §7 around the two-tier attestation model (open / certified)
that lives at Layer 5 of the layered architecture rather than the
prior three-tier encryption framing; updated §8 to remove "open core"
language in favor of "open protocol with reference implementations";
added cross-references to `PROTOCOL_LAYERS.md` as the canonical
engineering reference. Expect revisions as the protocol matures.*
