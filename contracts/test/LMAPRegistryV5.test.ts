// SPDX-License-Identifier: Apache-2.0
//
// LMAP Registry V5 — Scaffold tests.
//
// This test file is intentionally minimal: it verifies the contract compiles,
// deploys, and the core createTitle + purchaseTokens flow works end-to-end
// with the three-way payment split. Comprehensive test coverage (rights tiers,
// shareholder distribution, treasury timelock, paymaster, marketplace) lands
// in subsequent sessions.
//
// Note on USDC: Polygon mainnet USDC.e is hardcoded in the contract. For
// local testing we deploy a MockERC20 at the same address using Hardhat's
// account/storage manipulation. This keeps the contract pure (no USDC
// address parameter) while allowing local tests.

import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("LMAPRegistryV5", function () {
  // The hardcoded USDC.e address in the contract
  const USDC_ADDRESS = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";

  async function deployFixture() {
    const [deployer, treasury, publisher, author, buyer] = await ethers.getSigners();

    // Deploy a MockERC20 representing USDC.e
    const MockUSDC = await ethers.getContractFactory("MockERC20");
    const mockUsdc = await MockUSDC.deploy("Mock USDC.e", "USDC", 6);

    // Inject the mock USDC code at the hardcoded address using Hardhat's
    // setCode + setStorage. This makes USDC reads/writes in the contract
    // resolve to the mock.
    const usdcCode = await ethers.provider.getCode(await mockUsdc.getAddress());
    await ethers.provider.send("hardhat_setCode", [USDC_ADDRESS, usdcCode]);

    // Re-attach to interact with the injected USDC at the hardcoded address
    const usdc = MockUSDC.attach(USDC_ADDRESS);

    // Mint USDC to the buyer for purchases
    await usdc.connect(deployer).mint(buyer.address, ethers.parseUnits("1000", 6));

    // Deploy the registry with treasury as the platform treasury
    const Registry = await ethers.getContractFactory("LMAPRegistryV5");
    const registry = await Registry.deploy(treasury.address);

    return { registry, usdc, deployer, treasury, publisher, author, buyer };
  }

  describe("Deployment", function () {
    it("compiles, deploys, and reports the correct LMAP spec version", async function () {
      const { registry } = await loadFixture(deployFixture);
      expect(await registry.lmapSpecVersion()).to.equal("1.0");
    });

    it("sets the platform treasury and grants admin role to deployer", async function () {
      const { registry, treasury, deployer } = await loadFixture(deployFixture);
      expect(await registry.platformTreasury()).to.equal(treasury.address);

      const ADMIN_ROLE = await registry.ADMIN_ROLE();
      expect(await registry.hasRole(ADMIN_ROLE, deployer.address)).to.equal(true);
    });

    it("uses the correct hardcoded constants", async function () {
      const { registry } = await loadFixture(deployFixture);
      expect(await registry.PROTOCOL_FEE_BPS()).to.equal(250);
      expect(await registry.MAX_PUBLISHER_FEE_BPS()).to.equal(2500);
      expect(await registry.MAX_ROYALTY_BPS()).to.equal(1500);
      expect(await registry.MAX_SHAREHOLDERS()).to.equal(50);
    });
  });

  describe("createTitle (permissionless)", function () {
    it("allows any wallet to create a title; sets publisher to msg.sender", async function () {
      const { registry, publisher, author } = await loadFixture(deployFixture);

      const tx = await registry.connect(publisher).createTitle(
        "demo-title-1",
        "Demo Title",
        "film",
        author.address,
        100, // maxSupply
        ethers.parseUnits("4.99", 6), // pricePerToken
        1000, // publisherFeeBps (10%)
        500, // royaltyBps (5%)
        [], // no rights tiers for this minimal test
        "ipfs://QmTestMetadata",
        "ipfs://QmFilmRightsTierSchema"
      );
      await tx.wait();

      const tokenId = 1n;
      const title = await registry.titles(tokenId);
      expect(title.publisher).to.equal(publisher.address);
      expect(title.author).to.equal(author.address);
      expect(title.mediaType).to.equal("film");
      expect(title.publisherFeeBps).to.equal(1000n);
      expect(title.royaltyBps).to.equal(500n);
    });

    it("rejects publisher fee above MAX_PUBLISHER_FEE_BPS", async function () {
      const { registry, publisher, author } = await loadFixture(deployFixture);

      await expect(
        registry.connect(publisher).createTitle(
          "demo-title-2",
          "Demo Title",
          "film",
          author.address,
          100,
          ethers.parseUnits("4.99", 6),
          2501, // 25.01% — exceeds cap
          500,
          [],
          "ipfs://test",
          "ipfs://schema"
        )
      ).to.be.revertedWithCustomError(registry, "PublisherFeeTooHigh");
    });
  });

  describe("purchaseTokens (three-way split)", function () {
    it("distributes payment correctly: 2.5% protocol, 10% publisher, 87.5% author", async function () {
      const { registry, usdc, treasury, publisher, author, buyer } = await loadFixture(
        deployFixture
      );

      // Create a title with 10% publisher fee
      await registry.connect(publisher).createTitle(
        "split-test",
        "Split Test Title",
        "film",
        author.address,
        100,
        ethers.parseUnits("100", 6), // $100 per token (round numbers for assertion)
        1000, // 10% publisher fee
        500,
        [],
        "ipfs://test",
        "ipfs://schema"
      );

      // Buyer approves and purchases 1 token
      await usdc.connect(buyer).approve(await registry.getAddress(), ethers.parseUnits("100", 6));

      const treasuryBefore = await usdc.balanceOf(treasury.address);
      const publisherBefore = await usdc.balanceOf(publisher.address);
      const authorBefore = await usdc.balanceOf(author.address);

      await registry.connect(buyer).purchaseTokens(1, 1);

      const treasuryAfter = await usdc.balanceOf(treasury.address);
      const publisherAfter = await usdc.balanceOf(publisher.address);
      const authorAfter = await usdc.balanceOf(author.address);

      // 2.5% of $100 = $2.50 to treasury
      expect(treasuryAfter - treasuryBefore).to.equal(ethers.parseUnits("2.5", 6));
      // 10% of $100 = $10.00 to publisher
      expect(publisherAfter - publisherBefore).to.equal(ethers.parseUnits("10", 6));
      // Remainder = $87.50 to author
      expect(authorAfter - authorBefore).to.equal(ethers.parseUnits("87.5", 6));

      // Buyer receives 1 token
      expect(await registry.balanceOf(buyer.address, 1)).to.equal(1n);
    });
  });
});
