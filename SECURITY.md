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
particularly §4 (Cryptography) and §7 (Attestation). The two-tier
attestation model intentionally accepts open-tier permeability as
a feature, not a weakness — see `docs/PROTOCOL_POSITIONING.md` §2
for the reasoning. Reports that frame open-tier permeability as a
vulnerability will be acknowledged and discussed but will likely
not result in protocol changes.

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
