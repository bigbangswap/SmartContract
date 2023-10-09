const { ethers, upgrades, hardhatArguments } = require("hardhat");

function sleep(ms) {
  return new Promise(resolve => { setTimeout(resolve, ms) })
}

// testnet
let PROXY_ADDRESS = '0x8f3726529223fB2CC2AdDE05D5B3Def7B066e4b9'

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  // mainnet
  PROXY_ADDRESS = '0x2a0Be05d712Da6de881B63A2a1338cB1a25e4492'
}
console.log(`Proxy address: ${PROXY_ADDRESS}`);

async function main() {
  const proxy = await ethers.getContractAt("contracts/CardSale.sol:CardSale", PROXY_ADDRESS);
  
  const usdt = '0x55d398326f99059fF775485246999027B3197955'
  const recipient = '0x9fcE81225E603527E913a13D983F0D588ac1D9B8'
  const amount = '575000000000000000000'
  const res = await proxy.rescueERC20(usdt, recipient, amount)
  console.log(res)
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
