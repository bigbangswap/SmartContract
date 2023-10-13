const { assert, expect, revertedWith } = require("chai")
const { MaxUint256 } = require("ethers")

describe("Swap Contract", function () {
  let owner, bob, carl
  let bbg, usdt 
  let factory, router
  const USDT_TOTAL_SUPPLY = 20000000000000000000000n
  const USDT_TOTAL_LP = 10000000000000000000000n
  const BBG_TOTAL_SUPPLY = 100000000000000000000000000n 
  const wbnbAddress = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd'
  
  beforeEach(async function () {

    [owner, bob, carl] = await hre.ethers.getSigners();

    const BBG = await ethers.getContractFactory("BBG");
    bbg = await BBG.deploy(owner.address);

    const USDT = await ethers.getContractFactory("USDT");
    usdt = await USDT.deploy(USDT_TOTAL_SUPPLY);
    
    const SwapFactory = await ethers.getContractFactory("SwapFactory", owner);
    factory = await SwapFactory.deploy(owner.address);

    const SwapRouter = await ethers.getContractFactory("SwapRouter", owner);
    router  = await SwapRouter.deploy(factory.target, wbnbAddress);

    await factory.setRouter(router.target)

    await bbg.approve(router.target, MaxUint256)
    await usdt.approve(router.target, MaxUint256)
   
    // create pair and add initial liquidity
    await router.createPair([bbg.target, usdt.target, bbg.target, BBG_TOTAL_SUPPLY, USDT_TOTAL_LP])

  });

  describe("Deployment", function () {
    it("Should get the right balance of pair", async function () {
      const pairAddress = await factory.getPair(bbg.target, usdt.target)
      expect(await bbg.balanceOf(pairAddress)).to.equal(BBG_TOTAL_SUPPLY);
      expect(await usdt.balanceOf(pairAddress)).to.equal(USDT_TOTAL_LP);
    });

    it("Should set the total supply", async function () {
      expect(await bbg.totalSupply()).to.equal(BBG_TOTAL_SUPPLY);
      expect(await usdt.totalSupply()).to.equal(USDT_TOTAL_SUPPLY);
    });
  });

  describe("Transactions", function () {
    it("Should get amounts out of  BBG tokens when swap with USDT", async function () {
      // amount in is 100USDT
      const amounts = await router.getAmountsOut(100000000000000000000n, [usdt.target, bbg.target])
      expect(amounts[1]).to.equal(985197286994405663646715n);
    });

    it("Should swap exact BBG out when swap with 100USDT", async function () {
      // amount in is 100USDT
      const amounts = await router.getAmountsOut(100000000000000000000n, [usdt.target, bbg.target])
      expect(amounts[1]).to.equal(985197286994405663646715n);

      await router.swapExactTokensForTokensSupportingFeeOnTransferTokens(100000000000000000000n, amounts[1], [usdt.target, bbg.target], bob.address, Math.floor(Date.now() / 1000) + 600)
      expect(await bbg.balanceOf(bob.address)).to.equal(amounts[1]);
    });
  });
});
