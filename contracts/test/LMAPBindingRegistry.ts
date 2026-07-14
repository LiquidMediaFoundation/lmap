import { expect } from "chai";
import { ethers, network } from "hardhat";
import { p256 } from "@noble/curves/p256";

// hardhat's EDR EVM includes the RIP-7212 P-256 precompile at 0x100, so these
// tests exercise the REAL _verifyP256 path with REAL P-256 signatures. (The
// real *hardware* signature — from the Nuvoton TPM — is proven against the live
// mainnet precompile separately; here we test the contract's accounting.)

const TIER_PERSONAL = ethers.keccak256(ethers.toUtf8Bytes("lmap.tier.personal"));
const TIER_STREAMING = ethers.keccak256(ethers.toUtf8Bytes("lmap.tier.streaming"));
const TIER_CUSTOM_HEAVY = ethers.keccak256(ethers.toUtf8Bytes("lmap.tier.test-heavy-active"));

// One "device" P-256 keypair for the suite.
const devPriv = p256.utils.randomPrivateKey();
const devPubUnc = p256.getPublicKey(devPriv, false); // 0x04 || x || y
const devX = BigInt("0x" + Buffer.from(devPubUnc.slice(1, 33)).toString("hex"));
const devY = BigInt("0x" + Buffer.from(devPubUnc.slice(33, 65)).toString("hex"));

function devSign(digest: string): { r: string; s: string } {
  const sig = p256.sign(ethers.getBytes(digest), devPriv, { lowS: true, prehash: false });
  return {
    r: "0x" + sig.r.toString(16).padStart(64, "0"),
    s: "0x" + sig.s.toString(16).padStart(64, "0"),
  };
}

describe("LMAPBindingRegistry", () => {
  let token: any, reg: any, admin: any, owner: any, other: any;
  const tokenId = 1n;
  const root = ethers.keccak256(ethers.toUtf8Bytes("recognized-root-1"));
  const C = (s: string) => ethers.keccak256(ethers.toUtf8Bytes(s));

  beforeEach(async () => {
    [admin, owner, other] = await ethers.getSigners();
    token = await (await ethers.getContractFactory("MockERC1155")).deploy();
    reg = await (await ethers.getContractFactory("LMAPBindingRegistry")).deploy(
      await token.getAddress(),
      admin.address
    );
    await token.mint(owner.address, tokenId, 5);
    await reg.connect(admin).enrollDevice(devX, devY, root);
  });

  async function walletSig(signer: any, quantity: bigint, tier: string, commitment: string, nonce: bigint) {
    const domain = {
      name: "LMAPBindingRegistry",
      version: "1",
      chainId: (await ethers.provider.getNetwork()).chainId,
      verifyingContract: await reg.getAddress(),
    };
    const types = {
      BindAuthorization: [
        { name: "wallet", type: "address" },
        { name: "tokenId", type: "uint256" },
        { name: "tier", type: "bytes32" },
        { name: "quantity", type: "uint256" },
        { name: "commitment", type: "bytes32" },
        { name: "nonce", type: "uint256" },
      ],
    };
    return signer.signTypedData(domain, types, {
      wallet: owner.address, tokenId, tier, quantity, commitment, nonce,
    });
  }

  async function doBind(quantity: bigint, commitment: string, opts: any = {}) {
    const tier = opts.tier || TIER_PERSONAL;
    const x = opts.x ?? devX;
    const y = opts.y ?? devY;
    const nonce = await reg.nonces(owner.address);
    const wSig = await walletSig(opts.walletSigner || owner, quantity, tier, commitment, nonce);

    const devDigest = ethers.keccak256(
      ethers.AbiCoder.defaultAbiCoder().encode(
        ["address", "uint256", "bytes32", "uint256", "bytes32", "address", "uint256"],
        [owner.address, tokenId, tier, quantity, commitment, await reg.getAddress(), (await ethers.provider.getNetwork()).chainId]
      )
    );
    let { r, s } = devSign(devDigest);
    if (opts.tamper) s = "0x" + (s[2] === "f" ? "0" : "f") + s.slice(3);

    return reg.bind(owner.address, tokenId, tier, quantity, x, y, r, s, wSig, commitment);
  }

  it("binds with a real P-256 device sig + wallet sig; enforces boundCount <= balance", async () => {
    await expect(doBind(2n, C("s1"))).to.emit(reg, "Bound");
    expect(await reg.boundCount(owner.address, tokenId)).to.equal(2n);
    expect(await reg.transferableUnits(owner.address, tokenId)).to.equal(3n);
  });

  it("rejects a bind exceeding balance", async () => {
    await expect(doBind(6n, C("s2"))).to.be.revertedWithCustomError(reg, "InsufficientBalance");
  });

  it("rejects a heavy tier registered but inactive (streaming)", async () => {
    await expect(doBind(1n, C("s3"), { tier: TIER_STREAMING })).to.be.revertedWithCustomError(reg, "TierNotActive");
  });

  it("rejects a heavy-regime tier even when active", async () => {
    await reg.connect(admin).registerTier(TIER_CUSTOM_HEAVY, 2, true); // Regime.Heavy
    await expect(doBind(1n, C("s3b"), { tier: TIER_CUSTOM_HEAVY })).to.be.revertedWithCustomError(reg, "TierRegimeUnsupported");
  });

  it("rejects a tampered device signature (precompile rejects)", async () => {
    await expect(doBind(1n, C("s4"), { tamper: true })).to.be.revertedWithCustomError(reg, "BadDeviceSignature");
  });

  it("rejects a non-enrolled device", async () => {
    await expect(doBind(1n, C("s5"), { x: 999n, y: 888n })).to.be.revertedWithCustomError(reg, "DeviceNotEnrolled");
  });

  it("rejects a revoked device", async () => {
    await reg.connect(admin).revokeDevice(await reg.deviceId(devX, devY));
    await expect(doBind(1n, C("s6"))).to.be.revertedWithCustomError(reg, "DeviceIsRevoked");
  });

  it("rejects a reused commitment", async () => {
    await doBind(1n, C("s7"));
    await expect(doBind(1n, C("s7"))).to.be.revertedWithCustomError(reg, "CommitmentInUse");
  });

  it("rejects a wrong wallet signature", async () => {
    await expect(doBind(1n, C("s8"), { walletSigner: other })).to.be.revertedWithCustomError(reg, "BadWalletSignature");
  });

  it("increments the wallet nonce (replay protection)", async () => {
    expect(await reg.nonces(owner.address)).to.equal(0n);
    await doBind(1n, C("s9"));
    expect(await reg.nonces(owner.address)).to.equal(1n);
  });

  it("release opens the commitment and decrements boundCount", async () => {
    const secret = ethers.hexlify(ethers.randomBytes(32));
    const commitment = ethers.keccak256(secret);
    await doBind(1n, commitment);
    expect(await reg.boundCount(owner.address, tokenId)).to.equal(1n);
    await expect(reg.release(secret)).to.emit(reg, "Released");
    expect(await reg.boundCount(owner.address, tokenId)).to.equal(0n);
    await expect(reg.release(secret)).to.be.revertedWithCustomError(reg, "CommitmentAlreadyOpened");
  });

  it("recovery: report -> window -> executeRecovery force-releases", async () => {
    await doBind(2n, C("s10"));
    await reg.connect(owner).reportForRecovery(tokenId, 2);
    await expect(reg.connect(owner).executeRecovery(tokenId)).to.be.revertedWithCustomError(reg, "RecoveryWindowNotElapsed");
    await network.provider.send("evm_increaseTime", [30 * 24 * 3600 + 1]);
    await network.provider.send("evm_mine", []);
    await expect(reg.connect(owner).executeRecovery(tokenId)).to.emit(reg, "RecoveryExecuted");
    expect(await reg.boundCount(owner.address, tokenId)).to.equal(0n);
  });

  it("only CERTIFIER_ROLE can enroll devices", async () => {
    await expect(reg.connect(other).enrollDevice(1n, 2n, root)).to.be.reverted;
  });
});
