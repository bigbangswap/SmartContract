const { ethers, upgrades, hardhatArguments } = require("hardhat");

// testnet
let ROUTER_ADDRESS = '0xF8a3d1A716507498B49750F5E48a56510881825a'
let STAKING_ADDRESS = '0xF457d0eC4ee4CF7135A4b44B86cC5476de144F67'

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  // mainnet
  ROUTER_ADDRESS = ''
  STAKING_ADDRESS = ''
}
console.log(`Router address: ${ROUTER_ADDRESS}`);

async function main() {
  const proxy = await ethers.getContractAt("contracts/SwapRouter.sol:SwapRouter", ROUTER_ADDRESS);
  
  const res = await proxy.setStakingFactory(STAKING_ADDRESS)
  console.log(res)
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
