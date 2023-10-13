const { ethers, hardhatArguments } = require("hardhat");

async function main() {

  const token = await ethers.deployContract("USDT", [100000000000000000000000000n]);
  await token.waitForDeployment();

  console.table({
    "USDT address": await token.getAddress()
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
