# Token Utility & Securities Analysis

**Version:** 2.0
**Date:** April 2026
**Status:** Working analysis — not legal advice

---

## Purpose

This document records the working analysis under which LMAP tokens
are designed and described as utility tokens (licenses to view and
exhibit specific films) rather than investment contracts. It is
maintained for internal alignment and external transparency. It is
not legal advice and has not been certified by counsel; the
project's posture is to consult counsel at the points the situation
warrants it.

For the broader legal-risk posture, see
[`LEGAL_RISK_MITIGATION.md`](./LEGAL_RISK_MITIGATION.md).
For the protocol design itself, see
[`PROTOCOL_LAYERS.md`](./PROTOCOL_LAYERS.md).

---

## Token utility

An LMAP token is an ERC-1155 balance for a specific film, recorded
in the registry contract
(`contracts/legacy/WyllohRegistryProtocolV4_1.sol`,
`0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D` on Polygon mainnet).
Holding a balance grants:

- The right to download and decrypt the film via the storage service
- The right to play the film locally
- A position in the rights-tier ladder defined by the filmmaker for
  that token ID

**Rights tiers are filmmaker-configurable.** The registry stores a
`rightsThresholds` array per token ID, set at tokenization. Common
illustrative tier shapes:

| Tier | Quantity (illustrative) |
|---|---|
| Personal viewing | 1 |
| Small-venue exhibition | ~100 |
| Theatrical exhibition | ~tens of thousands |

These specific quantities are examples — they vary per film. The
protocol does not impose threshold values; it stores whatever the
filmmaker configured.

Each token confers immediate, consumable utility: the ability to
play the film. This utility is delivered cryptographically by the
encryption scheme described in
[`PROTOCOL_LAYERS.md`](./PROTOCOL_LAYERS.md) §4 and
[`INTEGRATION.md`](./INTEGRATION.md), not through any platform-
mediated service that could be revoked.

---

## Howey-test analysis

The U.S. Supreme Court's *Howey* test asks whether an arrangement is
an "investment contract" via four elements:

### 1. Investment of money — present

Users purchase tokens with USDC.e. This element is satisfied.

### 2. Common enterprise — not present in the typical sense

Token balances do not pool into a shared treasury. Each purchase
flows directly to the filmmaker (97.5%) and to the protocol fee
recipient (2.5%, hardcoded immutably in the contract). There is no
scheme by which token holders share in pooled returns.

### 3. Expectation of profits — designed to be absent

The protocol's public-facing materials (whitepaper, integration
docs, web client) are scoped to utility-register language:
ownership of copies, license to view, license to exhibit. Materials
avoid investment-register framing.

A secondary market does exist — tokens are transferable ERC-1155
balances and can be resold. The filmmaker receives the same 97.5/
2.5 split on secondary sales (royalty enforcement at the registry
level). The protocol acknowledges secondary markets exist; it does
not promote them as a return mechanism, and the protocol's stated
purpose (per the whitepaper) is distribution and ownership of
films, not appreciation of digital assets.

### 4. Efforts of others — not the principal source of utility

The principal utility (playing the film) is delivered by:
- An immutable smart contract (no party can revoke ownership)
- AES-256-GCM chunked content encryption (well-known primitive, not
  dependent on any party's secret keys)
- Threshold-mediated key release evaluated against current on-chain
  ownership (see [`PROTOCOL_LAYERS.md`](./PROTOCOL_LAYERS.md) §4
  and whitepaper §8). The threshold network is a distributed
  substrate of stake-bonded nodes — initially Lit Protocol's Naga
  mainnet during Year 0 bootstrap, transitioning to an LMAP-native
  threshold network operated under Foundation governance from Year 1
- Content stored on a public, content-addressed network (IPFS)

A holder's ability to use the token does not depend on the ongoing
managerial efforts of Wylloh or any other single commercial party.
The threshold network operates as distributed infrastructure with
economic alignment via the LMA token's emission and slashing
mechanics; this is structurally analogous to how Filecoin storage
incentives align providers with the network's operational health
without depending on Protocol Labs' managerial efforts.

After a successful threshold-mediated decryption, the master key is
cached locally on the holder's device (whitepaper §9). Offline
playback continues indefinitely with no network involvement. Holders
may export self-wrapped backups of their master keys for permanence
beyond the threshold network's operational lifetime.

The legacy V4.1 deployment uses a deterministic key-derivation
construction in which the wrapping key is derivable from public
on-chain data. This construction is retired for production use under
whitepaper v3 §8 and persists only for already-tokenized
public-domain content. New commercial content tokenizes against the
threshold-mediated mechanism described above.

### Working conclusion

Three of the four *Howey* elements are designed to be absent or
weak. This document treats the protocol's tokens as utility tokens
for the purpose of internal alignment and external materials. This
is a working analysis, not a legal opinion.

---

## Marketing and communication guidelines

To preserve the utility framing, the project uses utility-register
language and avoids investment-register language in all public
materials.

**Use:**
- "Ownership of copies of the work"
- "License to view / license to exhibit"
- "Tokens grant the right to..."
- "Utility tokens for film distribution"

**Avoid:**
- "Investment opportunity"
- "Profit potential" / "returns"
- "Appreciation" / "value growth"
- "Passive income" / "dividends"
- "Financial participation in commercial success"
- "Investment contract" / "security"

The whitepaper v2.0 (April 2026) was edited specifically to remove
investment-register phrasing that v1.0 contained ("financial
participation," "potential appreciation," "direct financial interest
in commercial success"). See git history for the edit. Whitepaper v3
(June 2026) introduces the LMA protocol token and its emission/burn
mechanics; the analysis in this document predates v3 architectural
ratification and **requires formal securities-counsel review before
LMA token issuance**. The Foundation's incorporation as a Cayman
Foundation Company (whitepaper §16.1) is a working commitment pending
this review; both the structural decision and this analysis are
subject to revision based on counsel's recommendations.

---

## Operational considerations

### Where the analysis is strongest

- The threshold-mediated key release is distributed across stake-
  bonded nodes operating under economic alignment, not a single
  managerial entity. The "efforts of others" prong is weakened
  because no single party's efforts gate utility — the network
  operates as distributed infrastructure analogous to Filecoin's
  storage layer.
- Local key caching and self-wrapped backup export mean post-purchase
  utility is durable to network outages or future shutdowns.
- The 97.5/2.5 split is enforced by the contract, not by a
  managerial entity that could change terms.
- Rights tiers are filmmaker-configured and stored on-chain at
  tokenization, not adjusted by a platform afterwards.

### Where the analysis warrants ongoing attention

- **Active marketing.** Even with utility-clean documentation,
  third-party marketing or community communications that frame
  tokens in investment terms could complicate the analysis.
  Maintain consistent language across channels.
- **Secondary market promotion.** The protocol must not be marketed
  primarily on its secondary-market characteristics.
- **Threshold language.** When discussing rights tiers, frame
  examples as filmmaker-configurable, not as protocol-wide
  guarantees that could be read as expectations of value tied to
  scale.
- **Foreign jurisdictions.** This analysis is U.S.-centered. EU
  (MiCA), UK (FCA), and other jurisdictions apply different
  frameworks. The project will engage local counsel as it
  encounters specific cross-border situations.

---

## Document control

- **This document is internal analysis, not legal advice.**
- Subject to revision when counsel reviews, when regulatory
  guidance evolves, or when the protocol's design changes.
- Material changes are committed to git with full diff history.

*Earlier version (February 2025) was written pre-launch with self-
attestations of "FULLY COMPLIANT" that overstated the standing of an
internal working analysis. This version softens the framing while
preserving the analytical structure.*
