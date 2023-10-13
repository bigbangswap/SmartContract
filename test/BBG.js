const { assert, expect, revertedWith } = require("chai")

describe("BBG Contract", function () {
  let owner, bob, carl
  let Token 
  let token 
  let TOTAL_SUPPLY = 100000000000000000000000000n
  
  beforeEach(async function () {
    Token = await ethers.getContractFactory("BBG");
    [owner, bob, carl] = await hre.ethers.getSigners();

    token = await Token.deploy(owner.address);
   
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await token.balanceOf(owner.address)).to.equal(TOTAL_SUPPLY);
    });

    it("Should set the total supply", async function () {
      expect(await token.totalSupply()).to.equal(TOTAL_SUPPLY);
    });
  });

  describe("Basic Info", function () {
    it("Should return the right name and symbol and decimals", async function () {
      expect(await token.name()).to.equal("BBG Token");
      expect(await token.symbol()).to.equal("BBG");
      expect(await token.decimals()).to.equal(18n);
    });
  
    it('Should assign the total supply of the tokens to the owner', async function () {
      const ownerBalance = await token.balanceOf(owner.address);
      expect(await token.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      await token.transfer(bob.address, 100n);
      expect(await token.balanceOf(owner.address)).to.equal(TOTAL_SUPPLY - 100n);
      expect(await token.balanceOf(bob.address)).to.equal(100n);
    });

    it("Should fail if sender doesn’t have enough tokens", async function () {
      const initialOwnerBalance = await token.balanceOf(owner.address);

      await expect(
        token.transfer(bob.address, TOTAL_SUPPLY + 100n)
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");

      expect(await token.balanceOf(owner.address)).to.equal(initialOwnerBalance);
    });

    it("Should update allowance", async function () {
      await token.approve(bob.address, 100n);
      expect(await token.allowance(owner.address, bob.address)).to.equal(100n);
    });

    it("Should transfer tokens from one account to another with allowance", async function () {
      await token.approve(bob.address, 100n);
      await token.connect(bob).transferFrom(owner.address, carl.address, 100n);

      expect(await token.balanceOf(owner.address)).to.equal(TOTAL_SUPPLY - 100n);
      expect(await token.balanceOf(carl.address)).to.equal(100n);
      expect(await token.allowance(owner.address, bob.address)).to.equal(0n);
    });

    it("Should fail if sender doesn’t have enough allowance", async function () {
      await token.approve(bob.address, 99n);

      await expect(
        token.transferFrom(owner.address, bob.address, 100n)
      ).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
    });
  });
  describe("Read Functions", function () {
    it("Should not be the pair", async function () {
      const pairAddress = '0xcDe678da96E6f20F348d5C3137fd7C2Ca12D6146'
      expect(await token.isSwapPair(pairAddress)).to.equal(false);
    });
  });
  describe("Write Functions", function () {
    it("Should return correct balance after burn", async function () {
      const balance = await token.balanceOf(owner.address)
      await token.burn(10000n)
      expect(await token.balanceOf(owner.address)).to.equal(balance - 10000n);
    });

    it("Should return correct feeTo address after set", async function () {
      await token.setFeeTo(bob.address)
      expect(await token.feeTo()).to.equal(bob.address);
    });

    it("Should return correct buyFeeRate after set", async function () {
      await token.setBuyFeeRate(10n)
      expect(await token.buyFeeRate()).to.equal(10n);
    });

    it("Should return correct sellFeeRate after set", async function () {
      await token.setSellFeeRate(10n)
      expect(await token.sellFeeRate()).to.equal(10n);
    });

    it("Should revert when setting value exceeds limit", async function () {
      await expect(token.setBuyFeeRate(1001n)).to.be.revertedWith("rate too large");
    });

    it("Should revert when setting sellFeeRate exceeds limit", async function () {
      await expect(token.setSellFeeRate(1001n)).to.be.revertedWith("rate too large");
    });
  });
});
