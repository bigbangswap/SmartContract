require('@openzeppelin/hardhat-upgrades');
const { ethers, upgrades, hardhatArguments } = require("hardhat");

function sleep(ms) {
  return new Promise(resolve => { setTimeout(resolve, ms) })
}

let operator = '0xBE2Fb2Dd89Af8e474053527cEEf00357b6D5310B'

let factory = '0x7DDD8d914633c052DfD8c6d72071FDE14DA12536'
let router = '0x973e0fFe16105446e615e6d4Ec96EA2b618fe0a6'
let pair = '0x0056D1757525C64FBad8be74E253F862018ECDe7'
let usdt = '0x5AD5a0C3bBdDAAAaB90580087B71F877596B7Ac5'
let bbg = '0x9Ed43917BB4aE7598383368F93113aFAF7BB03AD'
let wbnb = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd'

let circulatingPool = '0xBE2Fb2Dd89Af8e474053527cEEf00357b6D5310B'
let lpRewardPool = '0x1C23E94249DEFDb8c08a1529de0671Fc76eEff36'
let techEcoFund = '0x1ea686Da1e65a70E721Dbaca4938bE68D4b0C06B'
let marketingFund = '0x1C74ddc8B363dF722069148d054C0831b37acb73'
let feeTo = '0xAeD1842817Fb15adE4235938BD07cE7d694415c1'
let startTime = 1697208200 

const CARDSALE_ADDRESS = '0x7CC2423477df8A266A47608D7e612D7d3586a417'

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
  startTime = 
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
