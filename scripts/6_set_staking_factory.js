const { ethers, upgrades, hardhatArguments } = require("hardhat");

function sleep(ms) {
  return new Promise(resolve => { setTimeout(resolve, ms) })
}

// testnet
let ROUTER_ADDRESS = '0xF8a3d1A716507498B49750F5E48a56510881825a'
let PAIR_ADDRESS = '0xcDe678da96E6f20F348d5C3137fd7C2Ca12D6146'
let STAKING_ADDRESS = '0xF457d0eC4ee4CF7135A4b44B86cC5476de144F67'

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  // mainnet
  ROUTER_ADDRESS = ''
  STAKING_ADDRESS = ''
  PAIR_ADDRESS = ''
}
console.log(`Router address: ${ROUTER_ADDRESS}`);

async function main() {
  const proxy = await ethers.getContractAt("contracts/SwapRouter.sol:SwapRouter", ROUTER_ADDRESS);
  
  const res = await proxy.setStakingFactory(STAKING_ADDRESS)
  console.log(res)

  await sleep(10000)
  const res2 = await proxy.setWhiteList(PAIR_ADDRESS, STAKING_ADDRESS, true)
  console.log(res2)
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
