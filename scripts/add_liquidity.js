const { ethers, hardhatArguments } = require("hardhat");
const { MaxUint256 } = require("ethers")

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
}

const USDT_TOTAL_LP = 1000000000000000000000000n
const BBG_TOTAL_SUPPLY = 100000000000000000000000000n 

let BBG = '0x9Ed43917BB4aE7598383368F93113aFAF7BB03AD'
let USDT = '0x5AD5a0C3bBdDAAAaB90580087B71F877596B7Ac5'
let FACTORY = '0x7DDD8d914633c052DfD8c6d72071FDE14DA12536'
let ROUTER = '0x973e0fFe16105446e615e6d4Ec96EA2b618fe0a6'
const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  BBG = ''
  USDT = ''
  FACTORY = ''
  ROUTER = ''
} 

async function main() {

  const bbg = await ethers.getContractAt("contracts/BBG.sol:BBG", BBG);
  await bbg.approve(ROUTER, MaxUint256)

  await sleep(10000)
  const usdt = await ethers.getContractAt("contracts/USDT.sol:USDT", USDT);
  await usdt.approve(ROUTER, MaxUint256)

  await sleep(10000)
  const router = await ethers.getContractAt("contracts/SwapRouter.sol:SwapRouter", ROUTER);
  const res = await router.createPair([BBG, USDT, BBG, BBG_TOTAL_SUPPLY, USDT_TOTAL_LP])
  console.log(res)

  await sleep(10000)
  const factory = await ethers.getContractAt("contracts/SwapFactory.sol:SwapFactory", FACTORY);
  const pairAddress = await factory.getPair(BBG, USDT)
  console.log(`pair address = ${pairAddress}`)
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
