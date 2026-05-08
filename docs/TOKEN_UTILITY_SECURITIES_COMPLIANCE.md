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
- An immutable smart contract (no party can revoke access)
- A symmetric encryption scheme with a deterministic key derivation
  (open tier; see [`PROTOCOL_LAYERS.md`](./PROTOCOL_LAYERS.md) §4)
- Content stored on a public, content-addressed network (IPFS)

The encrypted master key, once delivered to a holder, can be
decrypted forever with or without any Wylloh-operated service. A
holder's ability to use the token does not depend on the ongoing
managerial efforts of any team.

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
in commercial success"). See git history for the edit.

---

## Operational considerations

### Where the analysis is strongest

- The deterministic key-derivation step at the open tier means
  utility is delivered cryptographically and is not revocable by
  any party. This significantly weakens the "efforts of others"
  prong.
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
