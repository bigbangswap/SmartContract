const { ethers, hardhatArguments } = require("hardhat");

const INIT_HOLDER = '0x1C23E94249DEFDb8c08a1529de0671Fc76eEff36'
const FEE_COLLECTOR = '0x1C23E94249DEFDb8c08a1529de0671Fc76eEff36'

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
