const { ethers, upgrades, hardhatArguments } = require("hardhat");

function sleep(ms) {
  return new Promise(resolve => { setTimeout(resolve, ms) })
}

// testnet
let PROXY_ADDRESS = ''

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  // mainnet
  PROXY_ADDRESS = ''
}
console.log(`Proxy address: ${PROXY_ADDRESS}`);

async function main() {
  const StakingContract = await ethers.getContractFactory("StakingContract")
  const res = await upgrades.upgradeProxy(PROXY_ADDRESS, CardSale);
  console.log(res)

  /*
  await sleep(10000)
  const proxy = await ethers.getContractAt("contracts/StakingContract.sol:StakingContract", PROXY_ADDRESS);
  const result = await proxy.fixPlan()
  console.log(result)
  */
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
