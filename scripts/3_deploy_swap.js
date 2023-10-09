const { ethers, hardhatArguments } = require("hardhat");

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
}

let feeCollector = '0x1C23E94249DEFDb8c08a1529de0671Fc76eEff36'
let wbnbAddress = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd'
const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  feeCollector = ''
  wbnbAddress = '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c'
} 

async function main() {

  const factory = await ethers.deployContract("SwapFactory", [feeCollector]);
  await factory.waitForDeployment();
  const factoryAddress = await factory.getAddress()
  console.log(`SwapFactory deployed to: ${factoryAddress}`);

  await sleep(10000)

  const router = await ethers.deployContract("SwapRouter", [factoryAddress, wbnbAddress]);
  await router.waitForDeployment();
  const routerAddress = await router.getAddress()
  console.log(`SwapRouter deployed to: ${routerAddress}`);

  await sleep(10000)

  const res = await factory.setRouter(routerAddress)
  console.log(res)
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
