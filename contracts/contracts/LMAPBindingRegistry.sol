// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

// =============================================================================
// LMAP Binding Registry — Reference Implementation (LMAP Spec v1.0)
//
// The on-chain accounting contract for LMAP's certified/compliant access tier,
// implementing the binding model of DEVICE_COMPLIANCE_AND_ACCESS_CONTROL.md §2.
//
// What this contract IS:
//   - The world-readable scarcity ledger: a copy of a title is "bound" to a
//     compliant device, tracked as a COUNT per (wallet, tokenId) under the
//     invariant `boundCount <= balanceOf`. Transferable units = balance - bound.
//   - Written by the attested compliant-device fleet, not a central flag-writer:
//     a bind carries (a) an enrolled device P-256 signature, verified on-chain
//     by the EVM's RIP-7212 precompile, and (b) the owner wallet's EIP-712
//     signature. A release OPENS a blinded commitment `C = keccak256(secret)`
//     — proving the writer is the device that bound, with NO wallet co-sign and
//     WITHOUT revealing device identity in contract state or events.
//   - Wallet-authoritative recovery for lost/dead devices (report -> window ->
//     force-release), so a device can never veto its owner (§2, §6).
//
// What this contract is NOT (kept deliberately separate, per the spec):
//   - It never GATES transfer. The token is a plain ERC-1155; this registry
//     INFORMS (released status is public) but the chain never blocks exchange.
//   - It does not issue keys. Key WRAPPING (master key -> device SE public key,
//     §2 step 3 / §4) is a separate off-chain issuer service that watches
//     `Bound` events and wraps only on a confirmed write. Flag-write and
//     key-wrap are distinct acts.
//   - It does not enforce ENDPOINT protection. Access-control (ownership ->
//     right to a key) and endpoint-protection (what a compliant device does
//     with decrypted frames) are never conflated.
//
// Tier model (the "hybrid" governance decision, 2026-07-12):
//   - Tiers are canonical `bytes32` class ids from an LMF-governed vocabulary;
//     their security REGIME (Light | Heavy) is protocol-native, not
//     platform-assignable. Thresholds and display names are the filmmaker's.
//   - Launch vocabulary (ship 4, extend via LMF governance):
//       personal    (Light)  — private household viewing
//       screening   (Light)  — public screening of the STANDARD master; the
//                              player enforces a visible pre-title legitimacy
//                              watermark (audience can tell a licensed screening
//                              from an off-chain-ticket grift)
//       streaming   (Heavy)  — off-chain platform redistributes via IMF package
//       theatrical  (Heavy)  — off-chain exhibitor sells tickets via DCP package
//   - THIS registry binds LIGHT-regime tiers only (personal + screening: same
//     home-grade asset, sovereign/fails-open). HEAVY tiers are registered but
//     INACTIVE here — they are licensed & revocable, conditioned on continued
//     holding, and their enforcement is a distinct mechanism co-developed with
//     the DCI community (a separate contract). Registering them now keeps the
//     vocabulary stable so tokens minted today are forward-compatible.
//
// Honest open items (DEVICE_COMPLIANCE §9), flagged where they live below:
//   - Device-identity privacy: the device pubkey appears in bind() CALLDATA
//     (not in state, not in events). Full "identity never on-chain" needs a
//     privacy-preserving membership proof (Merkle enrollment + nullifier, or a
//     ring signature over the enrolled set) — future hardening.
//   - boundCount semantics when a recovered unit's orphaned commitment is later
//     opened: clamped to prevent underflow; exact reconciliation is a §9 item.
//   - Tier-threshold qualification (does the wallet hold >= the title's
//     threshold for `tier`) is verified OFF-CHAIN by the key issuer against the
//     title's rights-tier schema; on-chain we enforce scarcity + record tier.
//   - Single-token v1 (one ERC-1155). Multi-registry support is forward work.
//
// Stewardship: Liquid Media Foundation. Reference implementation.
// =============================================================================

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

// === Custom errors (gas-efficient) ===
error InvalidInput();
error InsufficientBalance();     // boundCount + quantity > balanceOf
error DeviceNotEnrolled();
error DeviceIsRevoked();
error TierNotActive();           // tier unregistered or not active
error TierRegimeUnsupported();   // heavy tier: not bound through this registry
error BadDeviceSignature();      // RIP-7212 rejected the P-256 signature
error BadWalletSignature();      // EIP-712 recovery != wallet
error CommitmentInUse();
error CommitmentUnknown();
error CommitmentAlreadyOpened();
error NothingToRecover();
error RecoveryWindowNotElapsed();

contract LMAPBindingRegistry is AccessControl, ReentrancyGuard, Pausable, EIP712 {
    // =========================================================================
    // ROLES & CONSTANTS
    // =========================================================================

    /// @notice LMF multi-sig: manages the tier vocabulary, params, and pause.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice Certification authority (the automated self-serve certification
    ///         backend, §4): enrolls/revokes device keys after verifying the
    ///         device's attested conformance transcript against recognized roots
    ///         OFF-CHAIN. High-throughput by design — a home/OEM builder runs a
    ///         daemon that validates the hardware and reports back; on success
    ///         the backend calls enrollDevice().
    bytes32 public constant CERTIFIER_ROLE = keccak256("CERTIFIER_ROLE");

    /// @notice Polygon RIP-7212 secp256r1 (P-256) verification precompile.
    ///         Verified live on Polygon mainnet AND Amoy. TPM 2.0 secure
    ///         elements sign NIST P-256 natively, so a device signature is
    ///         cheaply verifiable here (EVM ecrecover cannot do P-256).
    address public constant P256_VERIFY = address(0x100);

    // Canonical launch tier ids (LMF-governed vocabulary).
    bytes32 public constant TIER_PERSONAL   = keccak256("lmap.tier.personal");
    bytes32 public constant TIER_SCREENING  = keccak256("lmap.tier.screening");
    bytes32 public constant TIER_STREAMING  = keccak256("lmap.tier.streaming");
    bytes32 public constant TIER_THEATRICAL = keccak256("lmap.tier.theatrical");

    /// @dev EIP-712 type for the owner's bind authorization. The wallet names
    ///      the device only via its blinded `commitment` — never the pubkey.
    bytes32 public constant BIND_AUTH_TYPEHASH = keccak256(
        "BindAuthorization(address wallet,uint256 tokenId,bytes32 tier,uint256 quantity,bytes32 commitment,uint256 nonce)"
    );

    // =========================================================================
    // TYPES & STATE
    // =========================================================================

    enum Regime { Unregistered, Light, Heavy }

    struct TierInfo {
        Regime regime;
        bool active; // bindable through THIS registry (light path only in v1)
    }

    struct Device {
        uint256 pubX;
        uint256 pubY;
        bytes32 root;   // recognized attestation root this device certified under
        bool enrolled;
        bool revoked;
    }

    struct BindRecord {
        address wallet;
        uint256 tokenId;
        bytes32 tier;
        uint256 quantity;
        bool opened;
    }

    struct RecoveryReport {
        uint256 quantity;
        uint64 reportedAt;
    }

    /// @notice The ERC-1155 title contract whose balances gate binding.
    IERC1155 public immutable token;

    /// @notice Recovery delay after a lost/dead-device report (§2, tunable).
    uint256 public recoveryWindow = 30 days;

    mapping(bytes32 => TierInfo) public tiers;                          // tierId => info
    mapping(bytes32 => Device) public devices;                         // deviceId => Device
    mapping(address => mapping(uint256 => uint256)) public boundCount; // wallet => tokenId => bound units
    mapping(bytes32 => BindRecord) public binds;                       // commitment => record
    mapping(address => uint256) public nonces;                        // wallet => next bind nonce
    mapping(bytes32 => RecoveryReport) public recoveries;             // keccak(wallet,tokenId) => report

    // =========================================================================
    // EVENTS  (never carry device pubkey / identity)
    // =========================================================================

    event TierRegistered(bytes32 indexed tier, Regime regime, bool active);
    event DeviceEnrolled(bytes32 indexed deviceId, bytes32 indexed root);
    event DeviceRevoked(bytes32 indexed deviceId);
    event Bound(address indexed wallet, uint256 indexed tokenId, bytes32 indexed tier, uint256 quantity, bytes32 commitment);
    event Released(address indexed wallet, uint256 indexed tokenId, bytes32 indexed tier, uint256 quantity, bytes32 commitment);
    event RecoveryReported(address indexed wallet, uint256 indexed tokenId, uint256 quantity, uint64 executableAt);
    event RecoveryExecuted(address indexed wallet, uint256 indexed tokenId, uint256 quantity);
    event RecoveryWindowUpdated(uint256 newWindow);

    // =========================================================================
    // CONSTRUCTOR
    // =========================================================================

    /// @param _token The LMAP ERC-1155 title registry whose balances gate binds.
    /// @param _admin LMF multi-sig; receives ADMIN_ROLE + bootstrap CERTIFIER_ROLE.
    constructor(IERC1155 _token, address _admin) EIP712("LMAPBindingRegistry", "1") {
        if (address(_token) == address(0) || _admin == address(0)) revert InvalidInput();
        token = _token;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(CERTIFIER_ROLE, _admin); // decentralizes to the issuer network (§5) later

        // Launch vocabulary. Light tiers are live; Heavy tiers are reserved
        // (registered, inactive) so today's tokens stay forward-compatible.
        _registerTier(TIER_PERSONAL,   Regime.Light, true);
        _registerTier(TIER_SCREENING,  Regime.Light, true);
        _registerTier(TIER_STREAMING,  Regime.Heavy, false);
        _registerTier(TIER_THEATRICAL, Regime.Heavy, false);
    }

    // =========================================================================
    // TIER VOCABULARY (protocol-native; LMF governs regime + activation)
    // =========================================================================

    /// @notice Register or update a tier class. Regime is protocol-native and
    ///         must never be platform/filmmaker-assignable (a Heavy right must
    ///         not be re-labeled Light to dodge revocation/watermark).
    function registerTier(bytes32 tier, Regime regime, bool active) external onlyRole(ADMIN_ROLE) {
        _registerTier(tier, regime, active);
    }

    function _registerTier(bytes32 tier, Regime regime, bool active) internal {
        if (tier == bytes32(0) || regime == Regime.Unregistered) revert InvalidInput();
        tiers[tier] = TierInfo(regime, active);
        emit TierRegistered(tier, regime, active);
    }

    // =========================================================================
    // DEVICE ENROLLMENT / REVOCATION (automated certification backend, §4)
    // =========================================================================

    function deviceId(uint256 pubX, uint256 pubY) public pure returns (bytes32) {
        return keccak256(abi.encode(pubX, pubY));
    }

    /// @notice Enroll a device whose attested conformance was verified off-chain
    ///         against a recognized root. Records the P-256 public key so future
    ///         binds by this device can be verified on-chain.
    function enrollDevice(uint256 pubX, uint256 pubY, bytes32 root)
        external
        onlyRole(CERTIFIER_ROLE)
        whenNotPaused
        returns (bytes32 id)
    {
        if (pubX == 0 || pubY == 0 || root == bytes32(0)) revert InvalidInput();
        id = deviceId(pubX, pubY);
        devices[id] = Device({pubX: pubX, pubY: pubY, root: root, enrolled: true, revoked: false});
        emit DeviceEnrolled(id, root);
    }

    /// @notice Revoke a device's write capability (§2: pushes any holder bound to
    ///         it onto the wallet-authoritative recovery path). Revocation cannot
    ///         WITHHOLD a release — recovery is wallet-authoritative — only delay it.
    function revokeDevice(bytes32 id) external onlyRole(CERTIFIER_ROLE) {
        Device storage d = devices[id];
        if (!d.enrolled) revert DeviceNotEnrolled();
        d.revoked = true;
        emit DeviceRevoked(id);
    }

    // =========================================================================
    // BIND  (the attested fleet writes its own bind; anyone may submit the tx)
    // =========================================================================

    /// @notice Bind `quantity` units of (wallet, tokenId) to a compliant device.
    /// @dev No access control on msg.sender: the device, a relayer, or a
    ///      paymaster may submit — authority comes from the two signatures.
    /// @param tier      Canonical LIGHT-regime tier id (personal | screening).
    /// @param pubX,pubY The device's enrolled P-256 public key.
    /// @param devR,devS The device's P-256 signature over the bind facts.
    /// @param walletSig The owner's EIP-712 BindAuthorization signature.
    /// @param commitment `C = keccak256(secret)`; the device keeps `secret` and
    ///        opens it to release. Never reveals device identity.
    function bind(
        address wallet,
        uint256 tokenId,
        bytes32 tier,
        uint256 quantity,
        uint256 pubX,
        uint256 pubY,
        bytes32 devR,
        bytes32 devS,
        bytes calldata walletSig,
        bytes32 commitment
    ) external whenNotPaused nonReentrant {
        if (quantity == 0 || commitment == bytes32(0)) revert InvalidInput();

        // (1) Tier must be active and LIGHT-regime. Heavy tiers are licensed +
        //     revocable and are NOT bound through this registry.
        TierInfo memory ti = tiers[tier];
        if (ti.regime == Regime.Unregistered || !ti.active) revert TierNotActive();
        if (ti.regime != Regime.Light) revert TierRegimeUnsupported();

        // (2) Device must be enrolled and non-revoked.
        //     NOTE (§9 privacy): pubX/pubY are in CALLDATA here (observable), but
        //     are never written to state or events. Anonymous membership proof =
        //     future hardening.
        Device memory d = devices[deviceId(pubX, pubY)];
        if (!d.enrolled) revert DeviceNotEnrolled();
        if (d.revoked) revert DeviceIsRevoked();

        // (3) Commitment must be fresh (also the anti-replay anchor).
        if (binds[commitment].wallet != address(0)) revert CommitmentInUse();

        // (4) Owner authorization (EIP-712). Names the device only via commitment.
        uint256 nonce = nonces[wallet];
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(BIND_AUTH_TYPEHASH, wallet, tokenId, tier, quantity, commitment, nonce))
        );
        if (ECDSA.recover(digest, walletSig) != wallet) revert BadWalletSignature();

        // (5) Device attestation-of-intent over the same facts, verified by the
        //     EVM's RIP-7212 P-256 precompile.
        bytes32 devDigest =
            keccak256(abi.encode(wallet, tokenId, tier, quantity, commitment, address(this), block.chainid));
        if (!_verifyP256(devDigest, devR, devS, pubX, pubY)) revert BadDeviceSignature();

        // (6) Scarcity invariant: boundCount + quantity <= balanceOf.
        uint256 newBound = boundCount[wallet][tokenId] + quantity;
        if (newBound > token.balanceOf(wallet, tokenId)) revert InsufficientBalance();

        // (7) Commit.
        nonces[wallet] = nonce + 1;
        boundCount[wallet][tokenId] = newBound;
        binds[commitment] = BindRecord({
            wallet: wallet,
            tokenId: tokenId,
            tier: tier,
            quantity: quantity,
            opened: false
        });

        emit Bound(wallet, tokenId, tier, quantity, commitment);
    }

    // =========================================================================
    // RELEASE  (open the blinded commitment — no wallet sig, no device identity)
    // =========================================================================

    /// @notice Release a bound copy by revealing the commitment preimage. Only
    ///         the device that bound knows `secret`, so opening proves it is that
    ///         device — without a wallet co-sign or any device-identity disclosure.
    /// @dev Intentionally not pausable: users must always be able to free their
    ///      own units.
    function release(bytes32 secret) external nonReentrant {
        bytes32 commitment = keccak256(abi.encode(secret));
        BindRecord storage r = binds[commitment];
        if (r.wallet == address(0)) revert CommitmentUnknown();
        if (r.opened) revert CommitmentAlreadyOpened();

        r.opened = true;
        _decrementBound(r.wallet, r.tokenId, r.quantity);
        emit Released(r.wallet, r.tokenId, r.tier, r.quantity, commitment);
    }

    // =========================================================================
    // RECOVERY  (wallet-authoritative; no heartbeat, no presence beacon — §2)
    // =========================================================================

    /// @notice Report units to recover from a lost/dead/uncooperative device.
    ///         Wallet-authoritative: msg.sender is the owner; the count-only
    ///         registry needs no device->title map because the owner enumerates
    ///         their own bound titles.
    function reportForRecovery(uint256 tokenId, uint256 quantity) external {
        if (quantity == 0) revert InvalidInput();
        bytes32 key = keccak256(abi.encode(msg.sender, tokenId));
        recoveries[key] = RecoveryReport({quantity: quantity, reportedAt: uint64(block.timestamp)});
        emit RecoveryReported(msg.sender, tokenId, quantity, uint64(block.timestamp + recoveryWindow));
    }

    /// @notice After the window, force-release the reported units so they become
    ///         transferable again. A still-live lost device must verifiably erase
    ///         those titles as a precondition of its next transaction (off-chain).
    /// @dev The decrement is clamped (see _decrementBound); exact reconciliation
    ///      with a later orphaned-commitment open is a §9 open item.
    function executeRecovery(uint256 tokenId) external nonReentrant {
        bytes32 key = keccak256(abi.encode(msg.sender, tokenId));
        RecoveryReport memory rep = recoveries[key];
        if (rep.reportedAt == 0) revert NothingToRecover();
        if (block.timestamp < rep.reportedAt + recoveryWindow) revert RecoveryWindowNotElapsed();

        delete recoveries[key];
        uint256 applied = _decrementBound(msg.sender, tokenId, rep.quantity);
        emit RecoveryExecuted(msg.sender, tokenId, applied);
    }

    // =========================================================================
    // ADMIN PARAMS
    // =========================================================================

    function setRecoveryWindow(uint256 newWindow) external onlyRole(ADMIN_ROLE) {
        recoveryWindow = newWindow;
        emit RecoveryWindowUpdated(newWindow);
    }

    function pause() external onlyRole(ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(ADMIN_ROLE) { _unpause(); }

    // =========================================================================
    // VIEWS
    // =========================================================================

    /// @notice Units this wallet may currently transfer for a title.
    function transferableUnits(address wallet, uint256 tokenId) external view returns (uint256) {
        uint256 bal = token.balanceOf(wallet, tokenId);
        uint256 bound = boundCount[wallet][tokenId];
        return bal > bound ? bal - bound : 0;
    }

    // =========================================================================
    // INTERNAL
    // =========================================================================

    /// @dev Decrement bound count, clamped at zero (never underflow). Returns the
    ///      amount actually applied.
    function _decrementBound(address wallet, uint256 tokenId, uint256 quantity)
        internal
        returns (uint256 applied)
    {
        uint256 cur = boundCount[wallet][tokenId];
        applied = quantity > cur ? cur : quantity;
        boundCount[wallet][tokenId] = cur - applied;
    }

    /// @dev RIP-7212 P-256 verify. Input = hash||r||s||x||y (160 bytes). Success
    ///      returns 32-byte 0x..01; failure returns empty.
    function _verifyP256(bytes32 hash, bytes32 r, bytes32 s, uint256 x, uint256 y)
        internal
        view
        returns (bool)
    {
        bytes memory input = abi.encodePacked(hash, r, s, bytes32(x), bytes32(y));
        (bool ok, bytes memory out) = P256_VERIFY.staticcall(input);
        return ok && out.length == 32 && out[31] == 0x01;
    }
}
