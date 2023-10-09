const { ethers, hardhatArguments } = require("hardhat");

const INIT_HOLDER = '0xD18cF39585dB64e46b1ceaf395aa8BC7b047bE85'
const FEE_COLLECTOR = '0xD18cF39585dB64e46b1ceaf395aa8BC7b047bE85'

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  INIT_HOLDER = ''
  FEE_COLLECTOR = ''
} 

async function main() {

  const token = await ethers.deployContract("BBG", [INIT_HOLDER, FEE_COLLECTOR]);
  await token.waitForDeployment();

  console.table({
    "BBG address": await token.getAddress()
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
