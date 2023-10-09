require('@openzeppelin/hardhat-upgrades');
const { ethers, upgrades, hardhatArguments } = require("hardhat");

let BBG = '0x460Cf8DbF5c819245324907C8455e8c675Acb6D3'

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
