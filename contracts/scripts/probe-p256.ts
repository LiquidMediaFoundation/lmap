import { ethers } from "hardhat";
import { p256 } from "@noble/curves/p256";
async function main() {
  const priv = p256.utils.randomPrivateKey();
  const pub = p256.getPublicKey(priv, false);
  const x = "0x" + Buffer.from(pub.slice(1, 33)).toString("hex");
  const y = "0x" + Buffer.from(pub.slice(33, 65)).toString("hex");
  const digest = ethers.hexlify(ethers.randomBytes(32));
  const sig = p256.sign(ethers.getBytes(digest), priv, { lowS: true, prehash: false });
  const r = "0x" + sig.r.toString(16).padStart(64, "0");
  const s = "0x" + sig.s.toString(16).padStart(64, "0");
  const data = "0x" + [digest, r, s, x, y].map((v) => v.slice(2)).join("");
  const out = await ethers.provider.call({ to: "0x0000000000000000000000000000000000000100", data });
  console.log("real P-256 sig via 0x100 →", out, out.endsWith("1") ? "✓ precompile PRESENT" : "(absent/rejected)");
}
main().catch(console.error);
