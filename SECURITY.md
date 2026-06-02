# Security Policy

## Reporting a Vulnerability

The Liquid Media Foundation takes security issues in the LMAP
specification and reference contracts seriously. We appreciate
responsible disclosure.

### How to report

Open a private security advisory on GitHub:
[github.com/LiquidMediaFoundation/lmap/security/advisories/new](https://github.com/LiquidMediaFoundation/lmap/security/advisories/new)

Until the foundation has its own dedicated security contact, urgent
issues affecting deployed contracts may also be sent to
[security@wylloh.com](mailto:security@wylloh.com) (the reference
implementation team).

Please include:

- Type of issue (cryptographic flaw, smart-contract vulnerability,
  specification ambiguity exploitable in implementations, etc.)
- Affected layer or contract
- Reproduction steps or proof-of-concept
- Potential impact
- Suggested mitigations, if any

### Response process

1. We will acknowledge your report within 3 business days.
2. Initial triage and severity assessment within 7 business days.
3. Coordinated disclosure and remediation, with credit to the
   reporter unless anonymity is requested.

## Scope

This policy covers:

- The LMAP specification documents in this repository
- The reference contracts in `contracts/contracts/` (under
  development)
- The legacy reference contracts in `contracts/contracts/legacy/`
  preserved for verification continuity
- Compliance test suites

Vulnerabilities specific to a downstream commercial implementation
(such as wylloh.com) are out of scope for this repository — please
report those to the implementing party directly.

## Threat model

The LMAP threat model is documented in `docs/PROTOCOL_LAYERS.md`,
particularly §4 (Cryptography) and §7 (Attestation), and in the
whitepaper v2.4 §7. The protocol's open-tier production access
control is **threshold-mediated key release via Lit Protocol's
Naga mainnet** — decryption material is released only to wallets
that currently satisfy the on-chain ownership check. The earlier
v2.3 framing — that "open-tier permeability is intentional" via
the deterministic key-derivation construction — is retired as a
production posture under v2.4; that construction now survives only
for the V4.1 deployment of public-domain content. Reports
identifying vulnerabilities in the threshold-mediated production
path (Lit ACC evaluation correctness, transfer semantics,
permanence guarantees) are in scope and welcomed. The certified
tier (hardware-attested per-device key wrapping) addresses a
distinct threat model — *endpoint protection during playback*
against the legitimate viewer's own device — which threshold
release does not address; reports there are also in scope.

## Smart contract scope

The deployed V4.1 registry on Polygon mainnet is immutable —
discovered vulnerabilities cannot be patched in place; they would
need to be addressed by deploying a successor contract under
foundation governance. Critical issues will be coordinated with the
reference implementation team for migration planning.

## Bug bounty

A formal bug bounty program is planned post-foundation incorporation.
In the interim, significant disclosures will be acknowledged in
release notes and considered for foundation grants once the
foundation's funding is operational.

Thank you for helping keep LMAP secure.
