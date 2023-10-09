require('@openzeppelin/hardhat-upgrades');
const { ethers, upgrades, hardhatArguments } = require("hardhat");

let BBG = '0xc2Cc561a41CC0ea4603FB58178377dC467597cA2'

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
