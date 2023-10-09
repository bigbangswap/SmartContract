const { ethers, upgrades, hardhatArguments } = require("hardhat");

function sleep(ms) {
  return new Promise(resolve => { setTimeout(resolve, ms) })
}

// testnet
let PROXY_ADDRESS = '0xb035d7c62fFdCc456dC670E5d518410e1AF11E3F'

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  // mainnet
  PROXY_ADDRESS = '0x2a0Be05d712Da6de881B63A2a1338cB1a25e4492'
}
console.log(`Proxy address: ${PROXY_ADDRESS}`);

async function main() {
  const CardSale = await ethers.getContractFactory("CardSale")
  const res = await upgrades.upgradeProxy(PROXY_ADDRESS, CardSale);
  console.log(res)

  /*
  await sleep(10000)
  const proxy = await ethers.getContractAt("contracts/CardSale.sol:CardSale", PROXY_ADDRESS);
  const result = await proxy.fixPlan()
  console.log(result)
  */
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
