import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("WyllohSecondaryMarket", function () {
  async function deployFixture() {
    const [owner, buyer] = await ethers.getSigners();

    // Use placeholder addresses for registry and USDC
    // Full integration tests should be run against a Polygon fork
    const registryAddress = "0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D";
    const usdcAddress = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";

    const SecondaryMarket = await ethers.getContractFactory("WyllohSecondaryMarket");
    const market = await SecondaryMarket.deploy(registryAddress, usdcAddress, owner.address);

    return { market, owner, buyer };
  }

  describe("Deployment", function () {
    it("deploys with correct fee structure", async function () {
      const { market } = await loadFixture(deployFixture);
      expect(await market.creatorRoyaltyBps()).to.equal(700);
      expect(await market.platformFeeBps()).to.equal(300);
    });

    it("starts with listing ID 1", async function () {
      const { market } = await loadFixture(deployFixture);
      expect(await market.nextListingId()).to.equal(1);
    });

    it("sets correct platform treasury", async function () {
      const { market, owner } = await loadFixture(deployFixture);
      expect(await market.platformTreasury()).to.equal(owner.address);
    });
  });

  describe("Admin", function () {
    it("allows owner to update fees", async function () {
      const { market, owner } = await loadFixture(deployFixture);
      await market.connect(owner).updateFees(500, 200);
      expect(await market.creatorRoyaltyBps()).to.equal(500);
      expect(await market.platformFeeBps()).to.equal(200);
    });

    it("rejects fees above 30%", async function () {
      const { market, owner } = await loadFixture(deployFixture);
      await expect(market.connect(owner).updateFees(2500, 600)).to.be.revertedWith("fees too high");
    });

    it("rejects non-owner fee updates", async function () {
      const { market, buyer } = await loadFixture(deployFixture);
      await expect(market.connect(buyer).updateFees(500, 200)).to.be.reverted;
    });

    it("allows owner to update treasury", async function () {
      const { market, owner, buyer } = await loadFixture(deployFixture);
      await market.connect(owner).updateTreasury(buyer.address);
      expect(await market.platformTreasury()).to.equal(buyer.address);
    });
  });
});
