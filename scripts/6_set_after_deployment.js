const { ethers, upgrades, hardhatArguments } = require("hardhat");

function sleep(ms) {
  return new Promise(resolve => { setTimeout(resolve, ms) })
}

// testnet
let ROUTER_ADDRESS = '0x973e0fFe16105446e615e6d4Ec96EA2b618fe0a6'
let PAIR_ADDRESS = '0x0056D1757525C64FBad8be74E253F862018ECDe7'
let STAKING_ADDRESS = '0x19E2c03A49F18e63D95c3A3D100d81138FAa228f'
let CARDSALE_ADDRESS = '0x451D9Ea87A4986182A068104620d320Db83f3Ef8'

const network = hardhatArguments.network;
if(network === 'bsc_main')
{
  // mainnet
  ROUTER_ADDRESS = ''
  PAIR_ADDRESS = ''
  STAKING_ADDRESS = ''
  CARDSALE_ADDRESS = ''
}
console.log(`Router address: ${ROUTER_ADDRESS}`);

async function main() {
  const router = await ethers.getContractAt("contracts/SwapRouter.sol:SwapRouter", ROUTER_ADDRESS);

  let res = await router.setStakingFactory(STAKING_ADDRESS)
  console.log(`set staking factory in router: ${res.hash}`)

  await sleep(10000)
  res = await router.setWhiteList(PAIR_ADDRESS, STAKING_ADDRESS, true)
  console.log(`set staking factory to whitelist: ${res.hash}`)

  await sleep(10000)
  res = await router.setWhiteList(PAIR_ADDRESS, CARDSALE_ADDRESS, true)
  console.log(`set cardsale to whitelist: ${res.hash}`)

  await sleep(10000)
  const cardsale = await ethers.getContractAt("contracts/CardSale.sol:CardSale", CARDSALE_ADDRESS);
  res = await cardsale.setStakingFactory(STAKING_ADDRESS)
  console.log(`set staking factory in cardsale: ${res.hash}`)

  // transfer LP token to staking contract
  await sleep(10000)
  const signers = await ethers.getSigners()
  const signer = signers[0]
  const pairToken = await ethers.getContractAt("contracts/SwapERC20.sol:SwapERC20", PAIR_ADDRESS);
  const balance = await pairToken.balanceOf(signer.getAddress()) 
  res = await pairToken.transfer(STAKING_ADDRESS, balance)
  console.log(`transfer LP token to staking factory: ${res.hash}`)
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
