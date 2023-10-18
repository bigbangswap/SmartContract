// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
require('@openzeppelin/hardhat-upgrades');
const { ethers, upgrades, hardhatArguments } = require("hardhat");

let BBG = '0x9Ed43917BB4aE7598383368F93113aFAF7BB03AD'
let PANCAKESWAP_LP_ADDRESS = ''
let OPERATOR_ADDRESS = '0x49A265d2f35d4cA65C532D6e679E641aba1E785e'

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  BBG = '0xaC4d2F229A3499F7E4E90A5932758A6829d69CFF'
  PANCAKESWAP_LP_ADDRESS = ''
  OPERATOR_ADDRESS = '0x49A265d2f35d4cA65C532D6e679E641aba1E785e'
} 

async function main() {
  const ELPContract = await ethers.getContractFactory("ELPContract");
  const contract  = await upgrades.deployProxy(ELPContract, [BBG, PANCAKESWAP_LP_ADDRESS, OPERATOR_ADDRESS]);
  await contract.waitForDeployment();

  console.table({
    "ELPContract Proxy address": await contract.getAddress()
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
