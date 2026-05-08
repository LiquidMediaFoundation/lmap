# Contributing to LMAP

Thank you for your interest in contributing to the Liquid Media
Access Protocol (LMAP). This document outlines how to engage with
the protocol's specification and reference materials.

LMAP is stewarded by the Liquid Media Foundation. Contributions are
welcome from filmmakers, developers, hardware integrators, security
researchers, and anyone who wants to help build a durable open
standard for tokenized media ownership.

---

## Code of Conduct

By participating, you agree to abide by the project's
[Code of Conduct](./CODE_OF_CONDUCT.md). Please read it before
contributing.

---

## What you can contribute

LMAP is a specification, a reference contract, and a set of
supporting documents. Useful contributions include:

- **Specification clarifications** — places where the protocol
  documents are ambiguous, incomplete, or outdated
- **Reference contract review** — analysis of `LMAPRegistryV5` (in
  development) and the legacy V4.1 contracts preserved in
  `contracts/contracts/legacy/`
- **Compliance test additions** — tests that codify expected
  behavior of LMAP-compliant contracts and clients
- **Reference implementation work** — code that demonstrates how to
  read from LMAP registries, decrypt content, and serve it to
  playback clients
- **Companion specifications** — schemas for additional media types
  (music, software, books, photography) once the foundation opens
  the relevant working groups
- **Interoperability reports** — documented experience integrating
  LMAP into third-party clients, marketplaces, or hardware

---

## How to contribute

### Issues

Open an issue to:
- Report a bug in a reference contract or test suite
- Propose a clarification to the specification
- Request a new section in the documentation
- Surface an interoperability problem

For substantive protocol-level proposals, see *Specification
proposals* below.

### Pull requests

For straightforward changes (typo fixes, spec clarifications,
documentation improvements, additional tests):

1. Fork the repository
2. Create a branch (`fix/typo-in-protocol-layers` or similar)
3. Make your change
4. Open a pull request against `main`

Keep PRs focused. One conceptual change per PR.

### Specification proposals

Substantive changes to the LMAP specification — new layers, breaking
changes to existing layers, additions that affect contract or client
behavior — should follow a proposal process before code changes:

1. Open an issue with the `proposal` label describing the motivation,
   the change, and known tradeoffs
2. Discussion happens in-thread; foundation stewards and interested
   contributors weigh in
3. If consensus emerges, the proposal becomes an Architecture
   Decision Record (ADR) under `docs/adr/`
4. Implementation PRs reference the ADR

This process is deliberately lightweight in the foundation's early
period. As the foundation matures, it will be formalized.

---

## Conventions

- **Markdown** for all documentation, GitHub-flavored
- **Solidity ^0.8.20+** for new contracts (legacy contracts preserved
  at their original pragma)
- **Apache-2.0** for all contributed source
- **Conventional commits** style for commit messages is appreciated
  but not required
- **No personal-data collection** in any reference implementation —
  the protocol is built around the principle that movies should not
  watch their viewers

---

## Licensing of contributions

By contributing, you agree that your contributions will be licensed
under the project's [Apache License 2.0](./LICENSE).

---

## Contact

- GitHub issues: [LiquidMediaFoundation/lmap/issues](https://github.com/LiquidMediaFoundation/lmap/issues)
- Email: TBD (foundation handle to be established)
- Reference implementation team: contact@wylloh.com
