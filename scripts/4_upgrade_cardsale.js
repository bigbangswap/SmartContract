const { ethers, upgrades, hardhatArguments } = require("hardhat");

function sleep(ms) {
  return new Promise(resolve => { setTimeout(resolve, ms) })
}

// testnet
let PROXY_ADDRESS = '0xDc9C56Dc376d01fB75cB9Cf8Dfb5FEbF8856a6a2'
let BBG_ADDRESS = '0x9Ed43917BB4aE7598383368F93113aFAF7BB03AD'
let ROUTER_ADDRESS = '0x973e0fFe16105446e615e6d4Ec96EA2b618fe0a6'
let STAKING_FACTORY = '0x19E2c03A49F18e63D95c3A3D100d81138FAa228f'

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  // mainnet
  PROXY_ADDRESS = '0x2a0Be05d712Da6de881B63A2a1338cB1a25e4492'
  BBG_ADDRESS = ''
  ROUTER_ADDRESS = ''
  STAKING_FACTORY = ''
}
console.log(`Proxy address: ${PROXY_ADDRESS}`);

async function main() {
  const CardSale = await ethers.getContractFactory("CardSale")
  const res = await upgrades.upgradeProxy(PROXY_ADDRESS, CardSale);
  console.log(res)

  const proxy = await ethers.getContractAt("contracts/CardSale.sol:CardSale", PROXY_ADDRESS);

  await sleep(10000)
  let result = await proxy.setBbgAddress(BBG_ADDRESS)
  console.log(`set BBG address in cardsale: ${result.hash}`)

  await sleep(10000)
  result = await proxy.setRouterAddress(ROUTER_ADDRESS)
  console.log(`set router address in cardsale: ${result.hash}`)

  await sleep(10000)
  result = await proxy.setStakingFactory(STAKING_FACTORY)
  console.log(`set staking factory address in cardsale: ${result.hash}`)
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
