# LMAP — Liquid Media Access Protocol

> An open standard for tokenized media ownership and peer-distributed
> delivery. Stewarded by the Liquid Media Foundation.

LMAP defines how digital media — beginning with film — can be
tokenized as on-chain entitlements, encrypted and content-addressed
on public storage, and delivered through a peer network independent
of any single platform. The token is the license. The bytes are
encrypted and content-addressed. Anyone can build storefronts,
players, or hardware that conforms to the spec.

What this enables, in consumer language: **liquid media** —
physical-grade ownership in liquid digital form.

---

## Status (July 2026)

LMAP Specification v1.0 is in drafting. The reference contract for
v1.0 (`LMAPRegistryV5`) is in development under foundation
governance. A legacy registry (`WyllohRegistryProtocolV4_1`) is
deployed on Polygon mainnet today and serves as the open-tier
reference deployment until V5 ships.

Access to decryption is native to the protocol and gated by current
on-chain ownership — no external, rentable key service stands between
a holder and content they own. At maturity a distributed threshold
network enforces this; at bootstrap a single Foundation-operated
issuer performs key release under the same rule, gating transfer and
first binding, never playback of content already held. Permissive
content uses no-hardware threshold release (the **open tier**);
commercial content binds one active copy to a sealed, conformant
player (the **compliant tier**) for endpoint protection. The
compliant tier is the Seed-gated launch mechanism, in active
specification and implementation. See the whitepaper for the full
model and per-component status.

| Component | Status |
|---|---|
| LMAP Specification v1.0 | Drafting (this repository) |
| Reference contract `LMAPRegistryV5` | In development |
| Paired copyright registry `LMAPCopyrightRegistryV1` | Specified |
| Legacy `WyllohRegistryProtocolV4_1` (open-tier compatible) | Shipped, immutable, on Polygon mainnet |
| Node.js reference client (Seed daemon) | Operational in the Wylloh reference implementation; extraction to this repo planned |
| Whitepaper | **v2.5** (July 2026) — [read the PDF](./whitepaper/whitepaper.pdf) or [Markdown source](./whitepaper/whitepaper.md) |

---

## What's in this repository

```
lmap/
├── docs/                              Specification and reference docs
│   ├── PROTOCOL_LAYERS.md             Canonical 8-layer architecture
│   ├── PROTOCOL_POSITIONING.md        Strategic posture; what's open
│   ├── INTEGRATION.md                 Developer guide
│   ├── CoreValues.md                  The four problems LMAP exists to address
│   ├── TOKEN_UTILITY_SECURITIES_COMPLIANCE.md
│   └── adr/                           Architecture decision records
├── contracts/                         Reference contracts and tests
│   ├── contracts/                     V5 reference (in development)
│   │   └── legacy/                    V4.1 preserved for verification continuity
│   ├── test/                          Compliance test suite
│   └── DEPLOYED_CONTRACTS.md          On-chain artifacts
├── whitepaper/                        Whitepaper source and rendered PDF
├── LICENSE                            Apache-2.0
├── NOTICE                             Attribution
├── CONTRIBUTING.md                    How to contribute
├── CODE_OF_CONDUCT.md
└── SECURITY.md
```

---

## Liquid Media Foundation

LMAP is stewarded by the Liquid Media Foundation, an independent
non-profit (in formation, structured as a 501(c)(6) trade
association). The Foundation holds the LMAP specification under an
open license, governs the compliant-tier attestation framework,
and publishes companion specifications for additional media types
as those communities develop.

The Foundation is structurally distinct from any commercial
implementation — modeled on the Wi-Fi Alliance, USB-IF, and HDMI
Forum precedents. Its purpose is that no commercial entity controls
LMAP. During the current stewarded bootstrap the founding team
operates the protocol and holds admin authority; the transition to
independent Foundation governance is a commitment the roadmap makes
explicit (whitepaper §15), not yet a completed fact.

---

## Reference implementation

Wylloh ([wylloh.com](https://wylloh.com)) is the first commercial
implementation of LMAP, focused on film distribution. Wylloh
operates a storefront, a storage service, and the reference Seed
device (the Origin) — all built on top of the LMAP protocol.

LMAP is open. Other commercial implementations — film, music,
software, and beyond — are welcome.

---

## Quick start

For developers building on LMAP:

- Read [`docs/PROTOCOL_LAYERS.md`](./docs/PROTOCOL_LAYERS.md) for
  the full architecture
- Read [`docs/INTEGRATION.md`](./docs/INTEGRATION.md) for a
  practical developer guide
- See [`contracts/DEPLOYED_CONTRACTS.md`](./contracts/DEPLOYED_CONTRACTS.md)
  for current on-chain addresses

For filmmakers interested in tokenizing a film today:
[contact@wylloh.com](mailto:contact@wylloh.com) (the reference
implementation team handles tokenization until self-service
minting ships in V5+).

---

## License

Apache License 2.0 — see [LICENSE](./LICENSE) and
[NOTICE](./NOTICE).

---

## Contact

- GitHub: [github.com/LiquidMediaFoundation/lmap](https://github.com/LiquidMediaFoundation/lmap)
- Reference implementation: [wylloh.com](https://wylloh.com)
- Foundation contact: TBD (forthcoming with incorporation)
