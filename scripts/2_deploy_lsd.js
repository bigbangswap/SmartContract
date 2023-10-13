require('@openzeppelin/hardhat-upgrades');
const { ethers, upgrades, hardhatArguments } = require("hardhat");

let BBG = '0x9Ed43917BB4aE7598383368F93113aFAF7BB03AD'

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  BBG = ''
} 

async function main() {

  const LSDContract = await ethers.getContractFactory("LSDContract")
  const contract  = await upgrades.deployProxy(LSDContract, [BBG])
  await contract.waitForDeployment();

  console.table({
    "LSD Proxy address": await contract.getAddress()
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
