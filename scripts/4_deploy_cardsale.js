// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
require('@openzeppelin/hardhat-upgrades');
const { ethers, upgrades, hardhatArguments } = require("hardhat");

let USDT = '0x5AD5a0C3bBdDAAAaB90580087B71F877596B7Ac5'
let BBG = '0x9Ed43917BB4aE7598383368F93113aFAF7BB03AD'
let ROUTER = '0x973e0fFe16105446e615e6d4Ec96EA2b618fe0a6'

let REWARD_WALLET = '0x2E27f73F985F11be79E12C555E8e3E8fb477891c'
let TECH_WALLET = '0x20A6D7FAf2fED7832405102c12089d5611ef1898'
let OP_WALLET = '0x86c784Ff87dcc0877dDFb78E959e94F34B6Dd71C'
let FEE_WALLET = '0xAeD1842817Fb15adE4235938BD07cE7d694415c1'

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  USDT = '0x55d398326f99059ff775485246999027b3197955'
  BBG = ''
  ROUTER = '' // inner SwapRouter
} 

async function main() {
  const CardSale = await ethers.getContractFactory("CardSale");
  const contract  = await upgrades.deployProxy(CardSale, [USDT, BBG, ROUTER, REWARD_WALLET, TECH_WALLET, OP_WALLET, FEE_WALLET]);
  await contract.waitForDeployment();

  console.table({
    "CardSale Proxy address": await contract.getAddress()
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
