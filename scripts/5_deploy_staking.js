require('@openzeppelin/hardhat-upgrades');
const { ethers, upgrades, hardhatArguments } = require("hardhat");

let operator = '0xBE2Fb2Dd89Af8e474053527cEEf00357b6D5310B'
let factory = '0x53d26a23d2BEe833146bFfADd102E0f6A0429055'
let router = '0xf3C7eC9312804Ae66daB2F7D4C90E57eD92A2eDA'
let pair = '0xBB986Eca8d2De8552C3ee4627544C5A703d712Af'
let usdt = '0x894040DCAb6F356B7e3FDC6914A8F765b95bbc6a'
let bbg = '0x460Cf8DbF5c819245324907C8455e8c675Acb6D3'
let wbnb = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd'
let circulatingPool = '0xD18cF39585dB64e46b1ceaf395aa8BC7b047bE85'
let lpRewardPool = '0xD18cF39585dB64e46b1ceaf395aa8BC7b047bE85'
let techEcoFund = '0x1ea686Da1e65a70E721Dbaca4938bE68D4b0C06B'
let marketingFund = '0x1C74ddc8B363dF722069148d054C0831b37acb73'
let feeTo = '0xAeD1842817Fb15adE4235938BD07cE7d694415c1'
let startTime = 1696833578

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  operator = '0xBE2Fb2Dd89Af8e474053527cEEf00357b6D5310B'
  factory = '0x53d26a23d2BEe833146bFfADd102E0f6A0429055'
  router = '0xf3C7eC9312804Ae66daB2F7D4C90E57eD92A2eDA'
  pair = '0xBB986Eca8d2De8552C3ee4627544C5A703d712Af'
  usdt = '0x894040DCAb6F356B7e3FDC6914A8F765b95bbc6a'
  bbg = '0x460Cf8DbF5c819245324907C8455e8c675Acb6D3'
  wbnb = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd'
  circulatingPool = '0xD18cF39585dB64e46b1ceaf395aa8BC7b047bE85'
  lpRewardPool = '0xD18cF39585dB64e46b1ceaf395aa8BC7b047bE85'
  techEcoFund = '0x1ea686Da1e65a70E721Dbaca4938bE68D4b0C06B'
  marketingFund = '0x1C74ddc8B363dF722069148d054C0831b37acb73'
  feeTo = '0xAeD1842817Fb15adE4235938BD07cE7d694415c1'
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
