const { ethers } = require("hardhat");

function sleep(ms) {
  return new Promise(resolve => { setTimeout(resolve, ms) })
}

async function main() {
  const lsd = await ethers.deployContract("LSDContract");
  await lsd.waitForDeployment();
  const lsdAddress = await lsd.getAddress()
  console.log(`LSDContract deployed to: ${lsdAddress}`);

  const proxyAddress = '0x93bBa2526F99D3d557AE91820f49D0b7CC89Bb3d'
  const proxyInstance = await ethers.getContractAt("contracts/LSDContract.sol:LSDContract", proxyAddress);
  const res = await proxyInstance.upgrade(lsdAddress)
  console.log(res)

  /*
  await sleep(10000)

  const ret = await proxyInstance.fixPlan()
  console.log(ret)
  */
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
