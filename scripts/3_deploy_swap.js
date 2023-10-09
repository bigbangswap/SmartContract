const { ethers, hardhatArguments } = require("hardhat");

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
}

let feeCollector = '0xD18cF39585dB64e46b1ceaf395aa8BC7b047bE85'
let wbnbAddress = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd'
const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  feeCollector = '0xD18cF39585dB64e46b1ceaf395aa8BC7b047bE85'
  wbnbAddress = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd'
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
