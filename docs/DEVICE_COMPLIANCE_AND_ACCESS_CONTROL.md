# LMAP — Device Compliance & Access Control

*Specification / design note. Drafted 2026-07-04. **Status: DRAFT for review.** Once settled, this drives updates to `PROTOCOL_LAYERS.md` §4.2–4.5, `PROTOCOL_POSITIONING.md` §7–8, and the whitepaper §7–9 (see §8). Working sections (§8–9) are editorial and are removed before publication.*

---

## 1. Principles

Under LMAP, playback of protected content occurs on a **compliant device** — a player meeting a published hardware conformance specification (§3) — and decryption is gated by **current on-chain ownership** of the entitling token. Access control is **native to the protocol**: it depends on no external key-management service.

This independence is a protocol requirement, not a preference. A participant's access to content they own must never be contingent on a third party's continued operation or business decisions; an access layer rented from an outside service would make every holder's ownership revocable by that service's fate — the dependency LMAP exists to remove. (Downloaded content therefore plays indefinitely offline; see §6.)

**Compliant hardware is required; a particular manufacturer's hardware is not.** The requirement is a **public conformance specification** any manufacturer can build to — making concrete the protocol's existing commitment that "any compliant device can participate" (whitepaper §9). Certification (§4) verifies a device model against the public criteria; it is open, non-discriminatory, and privileges no implementer. Reference implementations exist to be copied, not to gate.

**Two properties are kept conceptually distinct** — conflating them is a known category error, since they solve different threat models:

| | Access control | Endpoint protection |
|---|---|---|
| Question | *Who may obtain the key?* | *What may the device do with decrypted frames?* |
| Answer | Current on-chain ownership (`balanceOf > 0`) | A compliant device (secure element, in-perimeter decrypt) |
| Nature | **Ownership-cryptographic** — the protocol ideal, hardware-independent in principle | Hardware — supplied by compliant devices |
| Enforced by | The ownership check at binding, and release before transfer (§2) — decentralizing to a threshold network (§5) | Device attestation (§3, §4) |

Access control is never "you must own particular hardware." It is "you must own the token." Compliance is what makes it *safe to hand the key to an endpoint* — an endpoint-protection concern, not an access-control one.

### 1.1 Aligned incentives — why openness serves every participant

Networks thrive when incentives are aligned among their participants. LMAP's openness — any manufacturer may build a compliant device, any operator may run a storefront — is not a concession; it is the mechanism by which the network compounds in value for everyone on it. The logic, stated plainly so it is visible:

- **Every compliant device is capacity for the whole network.** A device that stores and seeds content adds replicas, upload bandwidth, and redundancy for *all* titles — supplied by the device owner. The network behaves as a **grassroots, member-owned CDN** whose performance and resilience *rise* with total device count, across every manufacturer. Delivery cost per stream *falls* as the fleet grows; no one carries the centralized curve where success is expensive.
- **A multi-vendor fleet is more secure than a monoculture.** The native threshold layer (§5) grows stronger and more available as independent nodes join, and manufacturer diversity removes single-vendor compromise and single-point-of-failure risk. More participants harden the protection that protects them all.
- **More participants mean more liquidity, and liquidity is the value.** Owned media is worth having in proportion to where it can be bought, lent, resold, and played. Additional storefronts and players deepen that liquidity, raising the value of every title for every holder. Participants grow the market together; they do not divide a fixed one (`PROTOCOL_POSITIONING.md` §4).
- **An open standard outlasts a closed one.** A standard anyone may implement accrues adoption a proprietary one cannot; openness is how the protocol endures rather than being displaced by something more open.
- **Openness differentiates rather than commoditizes.** Every LMAP title is available in every storefront, yet storefronts do not collapse into identical price-takers. The storefront that *mints* a title sells it at the natural price floor (its fee is set into the mint); any other storefront reselling it must add its own fee on top, so for them the title is about exposure and retention, not price leadership. Storefronts therefore compete on the two things openness *cannot* level: **selection** (the desirable originals they bring to mint) and **curation** (in a gateless registry anyone can mint anything, so which titles a storefront chooses to represent *is* its brand). Openness commoditizes the plumbing and frees competition to happen where it should — on taste and on what you make.

And the property that keeps this honest rather than naive: **the protocol confers no structural advantage on any participant.** No implementer holds a lock-in lever; advantage is earned through experience and must be continuously re-earned. That discipline is exactly what protects users — the incentive to excel never relaxes into captivity. Openness and quality reinforce each other instead of trading off.

## 2. Access-control model — binding (day 1)

A title's master key is random at content preparation and gated by **current** on-chain ownership of the entitling token (`balanceOf(wallet, tokenId) > 0`). The day-1 mechanism is **attested per-device binding**: a copy is bound to one compliant player at a time — the mechanism `PROTOCOL_LAYERS.md` §4.3 specifies, here elevated from a future tier to the launch mechanism. A token therefore corresponds to **at most one active copy**, which restores scarcity, while a bound copy plays **without ever contacting the network**. Only *transfer* requires liveness; *playback* never does.

**Binding flow (once, at acquisition):**
1. The buyer's wallet acquires the token.
2. The compliant player presents to the **issuer** (§4): (a) a **device attestation report** proving it is a certified, integrity-checked player with a secure element, and (b) proof the wallet **currently owns** the token.
3. The issuer verifies *both* — compliant player **and** current ownership — then **wraps the master key to the player's secure-element public key** and records the token's status as **`bound`**. A revoked player (§4) is refused.
4. The player unwraps the key **inside its secure element**; the film is decrypted **in memory at the decode boundary**. The raw key never touches disk or main memory.

**Bound possession is durable.** The wrapped key is retained locally; subsequent playback contacts no network and works fully offline, indefinitely (§6). The binding is *recorded*, not *re-verified* — a bound player never phones home to play.

**One active copy — the scarcity property.** Each token carries an on-chain status flag, **`bound`** or **`released`**, and can be `bound` to only one player at a time. This restores copy-scarcity — and with it collectible value and resale price — *without* any ongoing ownership check: scarcity is enforced only at the discrete moments of binding and release, never by surveilling playback. This resolves the sovereignty-vs-scarcity tension: playback stays sovereign; only transferability is gated.

**Transfer and release.** To transfer a token it must be **`released`** — the bound player deletes its wrapped key and copy, and the status flips to `released`. Because only a released token is usable by a buyer, the norm is *release before you list*. A prospective buyer need not take release on trust: **a protocol sale settles through a marketplace/escrow contract that asserts `released` atomically with the transfer, payment, and royalty.** A token still `bound` (or re-bound after listing) cannot be purchased through the protocol — settlement reverts and the buyer is refunded — so there is no check-then-buy race. A *raw* ERC-1155 transfer outside the protocol marketplace is caveat-emptor: a compliant wallet simply warns that the token is `bound`. Binding gates *issuance*, not the token transfer, so the token itself remains a standard, freely-transferable asset. (Optional fast-follow — *atomic release-at-sale* — lets a seller keep watching until the moment of sale by bundling the release into settlement.)

**Recovery of a lost or destroyed player.** Playback always fails *open* — a present-but-offline player keeps playing its bound copy forever — so only *transferability* depends on liveness. A bound player emits a periodic heartbeat when online. After a **30-day** silence (a tunable protocol parameter), the binding becomes eligible for **owner-initiated recovery**: the wallet owner proves ownership, force-releases the stale binding, and binds a fresh player. Recovery is *owner-initiated, never automatic* — a merely-travelling player that returns re-asserts its binding, and nothing is released behind the owner's back. The window is the abuse throttle: manufacturing a second copy requires keeping the old player permanently offline, waiting out the window, and re-binding — at most one extra, watermarked, personally-attributable copy per ~month. That is a negligible, traceable, physical-media-tier leak, not a redistribution vector (§7).

## 3. Device compliance requirements (the open conformance spec)

A device is **compliant** if it provides the following *capabilities* — stated as capabilities, not a specific chip, so a small-form-factor player, an SBC with a secure element, or future hardware can all conform:

- **Secure key custody.** A secure element or TEE holding a **non-exportable** device key, able to unwrap content keys **internally** and decrypt **without exposing the key or plaintext frames outside the protected perimeter**.
- **Verified boot.** Secure / measured boot, so an attestation of device state is meaningful.
- **Remote attestation.** The device can produce a verifiable report of its identity and firmware integrity that the issuer (§4) checks against the certified-device roots.
- **Output protection** appropriate to the title's tier (e.g., HDCP on HDMI), so plaintext frames are not trivially re-captured downstream.

**Reference hardware candidates** (from `PROTOCOL_LAYERS.md` Layer 0): NXP SE050, Microchip ATECC608B, ARM TrustZone, TPM 2.0. The *Origin* reference design targets ARM TrustZone plus a discrete secure element.

This section, plus a machine-checkable **conformance checklist**, is the public resource any manufacturer builds to.

## 4. Certification & issuance authority (neutral, open, federating)

At bootstrap, the **Foundation (LMF) operates two neutral functions**:
- **Device-model certification** — establishing that a device *model* meets §3, anchoring an attestation root the issuer trusts.
- **Key issuance** — the service in §2 step 3 that wraps master keys to attested, currently-entitled devices.

**Anti-gatekeeping commitments (load-bearing):**
- Certification **criteria are public** (§3); submission is **open and non-discriminatory**; every device model is certified through the same process, reference implementations included — no implementer is privileged.
- The issuer wraps to *any* compliant device presenting valid attestation and current ownership; it privileges no manufacturer.
- **Revocation** is limited to genuine compromise, recorded in an on-chain revocation registry (`PROTOCOL_LAYERS.md` §4.3, Layer 3), and transparent.

**Self-serve conformance (the throughput mechanism).** Certification is designed to be **automated and self-serve**, not a manual review queue: an implementer — a manufacturer or a home builder alike — submits at the Foundation site and runs an on-device **conformance suite** whose results the device's **secure element attests** (it signs the test transcript). The Foundation's backend verifies that attestation against the recognized hardware roots and checks the test vectors, then issues the compliance credential automatically. This is low-gate *and* firm at the same time, precisely because compliance is proven by **hardware attestation, which a device cannot fake** — a rooted, debug, or counterfeit device fails the suite on its own; rigor lives in the cryptography, not in a gatekeeper's judgment. (A test-harness agent may run and self-delete; trust rests on the attested transcript, never on the agent's word.) The one deliberately human, deliberately transparent decision is *which hardware roots the Foundation recognizes* (secure-element and TEE families) — a published, criteria-based policy list open to new entrants, not a per-device review. A self-built rig qualifies by using a recognized root, integrated correctly; the automation verifies the integration. The same attestation that gates content access is thus also what lets anyone earn compliance without asking permission — the mechanism by which "competitors welcome" scales.

The Foundation holding these functions at bootstrap is the neutrality choice — the access layer is stewarded by the standards body, not by any single operator — and it is explicitly a **temporary centralization**, dissolved by §5.

## 5. Decentralization roadmap (issuer → threshold)

The one genuinely centralized element at launch is a **single issuer**. This is acceptable at bootstrap because **durable possession** (§2, §6) means an issuer outage never costs a holder a film they already own. But it is not the destination. The path (matching the network-reserve staging):

1. **Bootstrap** — a single Foundation-operated issuer.
2. **Federated** — issuance is threshold-distributed across a small set of **perennial anchor nodes**; no single node can issue or withhold.
3. **Native threshold** — issuance distributes across the **Seed fleet itself** once it has the numbers: an LMAP-native threshold key network. This is where threshold sharding lands — as *hardening*, not a launch blocker — and it **restores fully ownership-cryptographic access control**, with no trusted issuer at all.

**Deploy the perennial nodes early — decoupled from the threshold crypto.** Standing up a handful of always-on anchor nodes is only marginally harder than running one, and worth doing from the start for **availability and failure-independence**: nodes in genuinely uncorrelated environments — a home connection, a solar-powered Starlink node in a remote location — do not share a datacenter's single grid, ISP, or region, so no common outage takes them all down. Two honesties keep this precise. First, *node deployment* and *trust minimization* are separable milestones: early anchor nodes run as **replicated issuers** (redundancy for uptime) before the threshold cryptography that makes them **compromise-tolerant** (no single node can issue) is ready — deploy the diverse hardware early, upgrade the trust model underneath as the crypto matures. Second, a home or remote node is physically less defensible than a datacenter, so *as pure replicas* more nodes widen the attack surface (any one compromised can issue); their security payoff is fullest once threshold makes a compromised minority harmless. So: deploy early for resilience, guard the key material until threshold lands, and let the environmental diversity become a security asset exactly when the cryptography can exploit it.

Threshold cryptography is the endgame that removes the last trusted party, reached when the fleet can support it — not a prerequisite for launch.

## 6. Permanence & durability

Consistent with whitepaper §8: a **bound** copy plays **forever, offline**, regardless of issuer, foundation, or operator fate — playback never depends on liveness. Only *re-binding* (recovering a dead player, or moving to a new one) requires the issuer to be live and, for a lost player, the recovery window (§2); the on-chain ownership record is the durable source of truth, so a holder whose player dies re-binds a new compliant player from their wallet's holdings. *The blockchain remembers; the hardware is replaceable.* Holders may also export a user-encrypted key backup for issuer-independent recovery.

## 7. Threat model & honesty boundary

**Protects:** keys released only to *current* owners; keys never in plaintext at rest; decryption confined to the secure perimeter; **per-device wrapping means compromising one device yields only that device's local content — exposure does not grow with N** (`PROTOCOL_LAYERS.md` §4.5, the load-bearing claim).

**Does not (stated honestly, never overclaimed):**
- Eliminate the **analog hole** (camera-at-screen). Watermarking mitigates; robustness is an arms race.
- Provide **bit-perfect copy protection** — no system does.
- **Cryptographically** guarantee one active copy against a *compromised* player. Scarcity holds because a compliant secure element honestly deletes on release; two bounded residues remain — a compromised player could report `released` while secretly retaining its copy, and the recovery path (§2) can be abused (old player kept permanently offline → recover → re-bind) for at most ~one extra copy per month. Both are watermarked and personally attributable — physical-media-tier personal leakage, not a redistribution vector — and neither affects a *buyer's* guarantee of a working token (§2).

**On hard (cryptographic) revocation — a deliberate boundary, not a gap.** Cryptographically revoking a key *already delivered* to a device is not possible without either re-keying the content and requiring a fresh online fetch to keep playing, or a device that continuously re-checks a license — i.e., surveillance and non-durable possession. That is precisely how conventional DRM achieves revocation: by never granting durable ownership in the first place. Matching it would mean surrendering the sovereignty that is the protocol's reason to exist. The design therefore pushes cryptographic enforcement as far as it goes *without* becoming DRM — the single active copy is issuer-gated (a second binding is refused while a token is `bound`), and only the honest-delete-on-release step is compliance-dependent and irreducible (a secret, once given, cannot be un-given). The protocol does not compete with DRM on revocation; it offers the thing DRM structurally cannot — ownership — and is honest that the two are mutually exclusive.

No claim of "uncopyable" or "DRM-grade." Access control (ownership + binding) and endpoint protection (hardware) are never conflated.

## 8. Updates this drives in canonical docs (editorial — remove before publication)

- **`PROTOCOL_LAYERS.md`** — §4.2: retire the external threshold-service dependency as production access control; the native issuer (§4) replaces it. §4.3: promote from "spec'd, future" to **the day-1 production mechanism**. §4.5: reframe with attested per-device wrapping as the launch mechanism. Add the **binding model** — one active copy per token, an on-chain `bound`/`released` status flag, release-before-transfer with atomic marketplace settlement, and 30-day owner-initiated recovery for lost players (§2 here). Rename "certified tier / certified device" → "compliant tier / compliant device" throughout.
- **`PROTOCOL_POSITIONING.md`** — §7 (two tiers): the *launch* tier is the compliant-hardware one; the permeable tier narrows to legacy public-domain demonstration. §8: add the device-compliance openness commitment and the §1.1 aligned-incentives framing. Note that attestation now carries launch weight *for endpoint protection* while access control remains ownership-cryptographic — position accordingly, without framing attestation as a licensing-driven "studio mode."
- **Whitepaper** — §7 / §8 / §9: replace external-threshold-service language for production access control; adopt "compliant tier" naming. Separately, §9's "headless / thin-clients" framing is stale against the direct-player direction (a distinct, deferred item).

## 9. Open questions

- **Bootstrap issuer trust** — a single issuer is a temporary central point (§5); acceptable given durable possession, but state it publicly and commit to the federation timeline.
- **Threshold scheme** — deferred design (DKG, resharing under home-device churn, liveness) for §5 step 3.
- **Certification process** — who audits, at what cost and cadence, to keep it genuinely open and non-discriminatory.
- **Public-domain legacy construction** — sunset plan for the deterministic-key demonstration path.
- **Atomic release-at-sale** (§2) — worth building for v1, or a fast-follow after release-before-listing?
- *Resolved 2026-07-04:* tier naming → "compliant" (replacing "certified"); **resale scarcity via the binding model** (§2), replacing the earlier compliance-vs-cryptographic ambiguity; **binding-status privacy** → publish only the per-token `bound`/`released` flag (status, not player identity or viewing data) — a marginal exposure given ERC-1155 ownership is already public, and worth it for trustless buyer verification; **no-heartbeat recovery window** → 30 days, owner-initiated (tunable).

## 10. Reference implementation & published resources

An **open-hardware reference design** (*Origin*) and an **open-source reference daemon** exist as the first compliant implementation. Their specifications and source are published so a manufacturer can build a compliant player, and an operator can run a storefront, without seeking anyone's permission. The conformance checklist (§3), the attestation and issuance protocol (§4), and the reference design are what the Foundation publishes for implementers. That publication is the point: the standard is the asset, and it belongs to everyone who builds on it.
