# LMAP — Positioning

> A living document on what LMAP is, what it isn't, and how it relates
> to the clients, hardware, and marketplaces that build on it.
>
> **Status:** Living document. Last revised June 2026.
>
> Opening sections are written to potentially become web copy. Later
> sections go deeper.
>
> **Companions:** `docs/PROTOCOL_LAYERS.md` — the layered engineering
> reference for what each layer of the protocol does;
> `whitepaper/whitepaper.md` — the canonical full specification.

---

## 1. A protocol, not a platform

**Wylloh is a protocol.** Like DVD. Like USB. A standard, a set of
specifications and immutable smart contracts that anyone can implement
and build on. Wylloh itself is not something most consumers ever need
to think about, in the same way most consumers never had to think
about the DVD specification when they bought a movie at a store.

What consumers experience is **liquid media** — a generic, public term
for the category Wylloh enables. *Liquid media* is to streaming
services what *physical media* was to broadcast television: a different
form of ownership, with different rights, that buyers can hold,
transfer, and pass on.

The terms relate like this:

- **LMAP** = the protocol (Liquid Media Access Protocol — the open specification)
- **LMF** = the Liquid Media Foundation (Cayman Foundation Company that stewards LMAP and operates Liquid Media Chain)
- **Liquid Media Chain** = the dedicated L2 (Polygon CDK ZK-rollup) where LMAP smart contracts deploy natively; LMA is the native gas asset
- **LMA** = Liquid Media Access — the protocol's coordination + gas + value-capture token, issued by LMF
- **liquid media** = the public category term (the consumer language for what LMAP enables)
- **Wylloh** = the first commercial implementation — operating wylloh.com, manufacturing Seed One and Origin Seed hardware, contributing engineering to LMF. **One participant in the LMAP ecosystem; not its operator.**
- **Wylloh Seeds** = the Wylloh-manufactured reference hardware — Seed One ($899, 4 TB NVMe, accessible price point) and Origin Seed ($4,499–4,999, founders' edition, sculptural hardware). Both participate in the LMAP network as storage providers and threshold-network operators.
- **wylloh.com** = the first storefront and reference web client
- **Other commercial entities** are welcome and expected — competing storefronts, alternative hardware vendors, integrator-channel deployments, future studio implementations. All operate on identical protocol terms.

**This is the Filecoin / Protocol Labs structure applied to media.** Protocol Labs is one ecosystem participant in Filecoin; the Filecoin Foundation stewards the protocol. Wylloh is one ecosystem participant in LMAP; LMF stewards the protocol.

The discipline of separating protocol from platform is the discipline
that lets every adopter — filmmakers, third-party storefronts,
hardware manufacturers, eventually studios — build on Wylloh without
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

## 2. The token is the license. Access is gated by current ownership.

LMAP uses cryptography. The token, however, is the load-bearing
mechanism — publicly verifiable on chain, tradable, inheritable,
permanent. Decryption material for any film is released only to
wallets that currently satisfy the access condition, evaluated at
decryption time by a threshold cryptographic network. The token is
the license. Access follows the token.

The token you hold is the provable thing. The MP4 you have on disk
is a file. If you lose the file, you re-acquire it through the same
ownership-gated path. If someone copies the file off your hard
drive, the copy has no ownership weight: the chain knows which
wallet holds the token, and decryption material flows only to that
wallet's current holder.

This is a stronger version of the protocol's earlier framing.
Earlier protocol versions described an *open tier* in which content
decryption was derivable from public data, with platform
independence asserted as the justification for accepted permeability.
That construction has been retired. Threshold-mediated key release
preserves platform independence — the threshold network is itself a
distributed substrate, not a Wylloh-operated service — while
cryptographically gating decryption by current ownership. Both
properties hold: the protocol is platform-independent *and*
ownership-gated.

> _"If you don't trust the people, you make them untrustworthy."_
> — Lao Tzu, _Tao Te Ching_ (tr. Stephen Mitchell)

The protocol's posture toward audiences remains unchanged: cryptography
binds access to ownership, not behavior. Token holders can download
as many times as they want, to as many devices as they want, with
no per-download metering or surveillance. The protocol does not
care how you watch; it cares that ownership and access remain
coupled.

**Our mission is twofold:** ensure fair compensation for filmmakers
so independent film stays sustainable, and earn the trust of
audiences and collectors so the community grows the right way. Each
depends on the other. A marketplace that doesn't pay filmmakers
fairly starves the work. A marketplace that treats its audience as
pirates poisons the relationship. LMAP attempts neither.

**What this means in practice:**

- **Ownership-gated access throughout.** All production content uses
  threshold-mediated key release. Decryption material is released
  only to wallets that currently satisfy the access condition.
- **Unmetered for holders.** Token holders re-acquire access freely.
  Multiple devices, multiple downloads, multiple regions — all
  permitted by the protocol; the access check passes on every
  request from a current holder.
- **Privacy preserved.** Threshold-network nodes verify wallet
  signatures and chain state; they do not log viewing behavior,
  associate identity, or build profiles. Analytics are derived from
  public chain data, not from user telemetry.
- **Permanence engineered.** Downloaded films play forever offline
  via local key cache and the optional self-wrapped backup export.
  Re-download and transfer require the access network to be live;
  no single-company point of failure.
- **Threshold cryptography is the security model.** The protocol
  claims and intends to demonstrate security equivalent to or
  stronger than legacy hardware-attested DRM. Forward-compatible
  support for hardware-attested key wrapping exists as a capability
  for licensing relationships predicated on legacy industry
  frameworks (whitepaper v3 §8.4); we do not lead with it, and
  expect industry frameworks to evolve to recognize threshold
  cryptography directly over time.

---

## 3. The protocol fee

Every sale that routes through the Wylloh smart contract pays a 2.5%
**protocol fee**. This fee is not a platform fee, and the distinction
matters.

- A platform fee is rent extracted by a marketplace for matching
  buyers with sellers.
- A protocol fee is shared infrastructure compensation — pinning
  redundancy on IPFS, contract auditing, security work, open-source
  development, the costs of keeping the network resilient.

The 2.5% is hardcoded in the smart contract. It cannot be raised, and
it cannot be waived per-sale. It is stable, legible, and the same for
every marketplace built on Wylloh. The protocol treasury — ultimately
governed by token holders, currently stewarded by the founding team —
is the recipient.

**Filmmakers keep 97.5% of every sale, regardless of which
marketplace the sale happens through.**

---

## 4. Third-party marketplaces are peers, not competitors

Because the fee is at the protocol layer, other marketplaces built on
Wylloh are not in economic conflict with wylloh.com. They pay the
same 2.5% protocol fee and can layer their own commercial markup on
top — typically a marketplace fee for discovery, curation, or
audience.

A user buying the same film on two different Wylloh-compatible
marketplaces might see:

```
wylloh.com:        $4.99  ($0.12 protocol fee, $4.87 to filmmaker)
indiemarket.tv:    $5.49  ($0.12 protocol fee, $0.50 marketplace,
                           $4.87 to filmmaker)
```

The filmmaker's share is identical. The marketplace competes on
service, not on undercutting the protocol.

This makes Wylloh valuable to other marketplaces: we are their shared
plumbing, not their rival. A film minted on Wylloh is portable to any
Wylloh-compatible marketplace, and its provenance is permanent
regardless of where the next sale happens.

---

## 5. Clients and edges

The protocol is one thing. Clients that talk to it are many. Each
client makes its own tradeoffs about where plaintext content lives
and how hard extraction is.

All compliant clients gate access through threshold-mediated key
release; what varies is what happens after the master key is in
hand — where the plaintext lives and how hard extraction is.

| Client | Access control | Plaintext residence | Extraction resistance |
|---|---|---|---|
| **wylloh.com (browser)** | Threshold-mediated; master key cached in IndexedDB | Streaming-decrypted in memory; can be saved as plaintext MP4 to Downloads | Modest — once a holder downloads, the plaintext is on disk |
| **Wylloh Seed** (headless home server) | Threshold-mediated; master key cached in encrypted device store; optional attested-mode wrapping | Encrypted at rest on Seed; streaming decrypt to LAN client | Strong — encrypted bytes only on persistent storage |
| **Wylloh Roku / Apple TV / iOS app** | Inherits Seed's threshold-mediated access | No persistent local copy; LAN-streamed plaintext only | Inherits Seed's resistance |
| **Third-party clients** | Must implement threshold-mediated access correctly to serve registered content | Client's choice within protocol constraints | Client's choice within protocol constraints |

Each serves a different use case:

- The **browser** is the onboarding surface. Zero install.
  Threshold-mediated access; local key cache enables offline
  playback after first decrypt. The protocol does not prevent the
  holder from saving plaintext to disk after legitimate decryption;
  the social contract handles the rest. This is where new users
  meet LMAP-compatible storefronts. We do not fight them.
- The **Seed** is the sovereignty surface — a headless home server
  paired with branded client apps on the TV platforms users already
  own. Plaintext-resistant at rest by design. For collectors who
  want a physical-media feel without the DIY friction of Plex.
  Shipped by Wylloh in two reference SKUs (Seed One, Origin Seed);
  identical firmware, identical protocol role, different form and
  price. Third-party Seed implementations are welcomed on identical
  protocol terms.
- **Third-party clients** are welcome. They inherit the protocol,
  make their own UX choices, pay the same 2.5% protocol fee on
  marketplace-routed sales.

See `docs/seed-one/ARCHITECTURE.md` for the SKU-neutral Seed architecture
(headless server + client apps on Roku/Apple TV/iOS) and
`docs/seed-one/README.md` for the Seed One / Origin SKU strategy.

---

## 6. Native apps — the surface where users live

Branded Wylloh client apps for Roku, Apple TV, and iOS are a core
part of the Seed architecture, not optional add-ons. They are how
users actually meet a Seed in their living room — whether that Seed
is a $249 Seed One behind the TV or an Origin Seed on the console table.

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

## 7. The security model — threshold cryptography, full stop

LMAP's security model is threshold-mediated key release. Decryption
material for any film is gated by current on-chain ownership of the
corresponding token, evaluated at decryption time by a threshold
cryptographic network. No party — not the foundation, not a
storefront, not a hardware vendor — can release decryption material
to a wallet that does not currently satisfy the access condition.

**The claim:** threshold cryptography with stake-based sybil
resistance provides security equivalent to or stronger than legacy
hardware-attested DRM (Widevine L1, PlayReady, FairPlay). We intend
to demonstrate this through public deployment, audit, and operational
record. Widevine L1 has been broken in production multiple times;
threshold cryptography in deployed systems has not. The protocol's
security does not depend on hardware attestation.

**Earlier framing retired.** Previous versions of this document
described a "two-tier" model — an *open tier* with deterministic key
derivation alongside a *certified tier* with hardware attestation.
That framing has been retired. The deterministic key-derivation
construction does not actually gate decryption by ownership (anyone
with the public chain data can derive the wrapping key), so it
cannot serve as a production access-control mechanism for content of
commercial value. It survives only as a public-domain demonstration
approach for *The Cocoanuts* and similar V4.1 deployments.
Threshold-mediated release replaces it as the production model.

**Forward-compatibility for legacy industry frameworks.** Some
industry licensing frameworks — primarily those originating with
major studios — reference specific hardware-DRM technologies as
contractual conditions of licensing. These frameworks predate
threshold cryptography's deployment maturity. LMAP's design includes
forward-compatible support for hardware-attested key wrapping so
that licensing relationships predicated on these frameworks can be
honored without forking the protocol. This is a capability of the
design, not a feature we lead with. The expectation is that industry
compliance frameworks evolve to recognize threshold cryptography
directly over time; the hardware-attested capability's relevance
decreases as that happens.

The protocol's intellectual center of gravity is threshold release.
The hardware-attested capability exists at the periphery, providing
forward-compatibility for a legacy that is itself in the process of
becoming obsolete. We do not market the hardware-attested capability
as "the studio mode" or position it as a destination state for
premium content. We expect studios to come to threshold cryptography
on its own terms.

| Property | LMAP security model | Forward-compat capability (legacy industry) |
|---|---|---|
| Mechanism | Threshold-mediated key release | Per-device key wrapping inside secure element |
| Sybil resistance | Stake-based, slashable | Hardware attestation by federated issuers |
| Trust anchor | Wallet + threshold network | Wallet + threshold network + attested device |
| Required for | All production content | Content where licensing contract demands it |
| Implementation status | In active migration (Lit Y0; LMAP-native Y1+) | Capability in design; activated when invoked by content metadata |

**The critical invariant: the ownership token is the license.**
Under both the standard threshold-mediated path and the
hardware-attested capability, the token remains transferable,
provably owned on-chain, and executable off-platform. Hardware
attestation, when invoked, gates playback only — never carriage,
never tokens, never transfer.

For technical readers: this section's earlier "two-tier" framing
positioned threshold and attestation as parallel modes of the
protocol's security model. They are not parallel. Threshold release
is *the* model; attestation is forward-compatibility. The framing
matters because it shapes what we expect of industry counterparties
and what we expect to demonstrate publicly.

See `docs/PROTOCOL_LAYERS.md` §4 and §7 for the engineering view,
and the LMAP whitepaper v3 §8 for the canonical specification.

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
  a contract, not a Wylloh-owned dependency)
- Transferring, reselling, and holding tokens — all standard
  ERC-1155 semantics, no permission needed
- The Wylloh SDK and reference implementations (storage service,
  encryption library, registry interface)
- The wylloh.com web client (MIT-licensed, on GitHub)
- The Wylloh Seed firmware reference, shared by both Seed One and Origin
  (will be open-sourced when the reference implementation reaches v1)

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
- **Hardware-attested capability for legacy licensing frameworks.**
  When invoked by a content's licensing contract, content-key
  wrapping uses the per-device hardware-attestation pathway (Layer
  5). The issuance framework is foundation-only at first invocation,
  with a public commitment to federate at a defined milestone. This
  capability is forward-compatibility for legacy industry frameworks,
  not a feature we lead with.

**Commercial products built on top of the protocol** (operated under
their own commercial terms):

- **Seed One** — the affordable Wylloh Seed SKU, manufactured as a
  commercial good (~$249 retail). The Y0 ship; the SKU that scales the
  decentralized delivery network. Firmware reference is open; the
  manufactured hardware (enclosure, brand, packaging, support) is a
  commercial product.
- **Origin Seed** — the Y1 brand-crown founders' edition (~$4,499–4,999
  retail), the sculptural walnut-and-brass furniture object. Same
  firmware as Seed One; what's commercial is the industrial design,
  brand, packaging, channel position, and support.
- **Branded client apps** for Roku, Apple TV, iOS — distributed
  through their respective stores under commercial terms; reference
  implementations may be open-sourced separately.
- **Wylloh-operated storage and pinning service** — the API contract
  is documented and replicable; the operated instance is a commercial
  service.
- **Future commercial entities** built on top of the protocol —
  storefronts, hardware brands, marketplace operators — would each be
  participants in the Wylloh ecosystem, not its operators.

**The frame for VCs:**

- **Crypto-native investors** (a16z Crypto, Polychain, Variant,
  Protocol Labs, 1confirmation): the protocol is open, credibly
  neutral, MIT-licensed. Every film minted on Wylloh is portable to
  any third-party marketplace. This is the open-protocol play.
- **Hardware/infrastructure investors** (Playground Global, 1517
  Fund, Foundry): the consumer products built on the protocol —
  Seed One (the affordable network SKU) and Origin Seed (the brand
  crown) — are commercial, defensible by brand, by filmmaker
  relationships, by the canonical-default status that comes from
  being first and being polished, and by the CEDIA-channel access
  Wylloh's founder + advisor already operate.
- **Strategic investors** (broadcaster M&A arms, studio ventures,
  former-streamer founders as angels): the long-horizon ecosystem —
  studios eventually licensing content as their compliance
  frameworks evolve to recognize threshold cryptography, integrators
  deploying into luxury homes, third-party storefronts — only works
  because the protocol stays neutral.

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

If you tokenize a film on Wylloh:

- You keep 97.5% of every sale, forever, regardless of marketplace
- Your film is portable to any Wylloh-compatible marketplace
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

> Wylloh is a protocol for film ownership. Like DVD, like USB — a
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

*Last updated: 2026-06-02. §1 (entity structure), §2 (access-control
posture), §5 (clients and surfaces), and §7 (security model)
substantively refactored to reflect the LMAP/LMF/Liquid Media Chain
architecture committed in whitepaper v3 (`docs/whitepaper/WHITEPAPER_V3.md`).
The legacy "two-tier" framing (open tier + certified tier as parallel
modes) is retired; the protocol's security model is threshold-mediated
key release at Layer 2, and hardware attestation is forward-
compatibility for legacy industry licensing frameworks rather than a
co-equal mode of the security architecture. We do not lead with
hardware attestation in any positioning material; the expectation is
that industry compliance frameworks evolve to recognize threshold
cryptography as equivalent or stronger security over time.*
