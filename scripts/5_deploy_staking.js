require('@openzeppelin/hardhat-upgrades');
const { ethers, upgrades, hardhatArguments } = require("hardhat");

let operator = '0xBE2Fb2Dd89Af8e474053527cEEf00357b6D5310B'
let factory = '0xe1555227DDc9CE209b67E55b60c1e8aE15Ad9eC0'
let router = '0xF8a3d1A716507498B49750F5E48a56510881825a'
let pair = '0xcDe678da96E6f20F348d5C3137fd7C2Ca12D6146'
let usdt = '0x894040DCAb6F356B7e3FDC6914A8F765b95bbc6a'
let bbg = '0xc2Cc561a41CC0ea4603FB58178377dC467597cA2'
let wbnb = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd'
let circulatingPool = '0xBE2Fb2Dd89Af8e474053527cEEf00357b6D5310B'
let lpRewardPool = '0x1C23E94249DEFDb8c08a1529de0671Fc76eEff36'
let techEcoFund = '0x1ea686Da1e65a70E721Dbaca4938bE68D4b0C06B'
let marketingFund = '0x1C74ddc8B363dF722069148d054C0831b37acb73'
let feeTo = '0xAeD1842817Fb15adE4235938BD07cE7d694415c1'
let startTime = 1696833578

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  operator = ''
  factory = ''
  router = ''
  pair = ''
  usdt = ''
  bbg = ''
  wbnb = ''
  circulatingPool = ''
  lpRewardPool = ''
  techEcoFund = ''
  marketingFund = ''
  feeTo = ''
  startTime = 1696833578
} 

async function main() {

  const StakingContract = await ethers.getContractFactory("StakingContract")
  const contract  = await upgrades.deployProxy(StakingContract, 
    [
      operator,
      factory,
      router,
      pair,
      usdt,
      bbg,
      wbnb,
      circulatingPool,
      lpRewardPool,
      techEcoFund,
      marketingFund,
      feeTo,
      startTime
    ]
  )
  await contract.waitForDeployment();

  console.table({
    "Staking Proxy address": await contract.getAddress()
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
