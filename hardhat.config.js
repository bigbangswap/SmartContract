require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');
require('hardhat-contract-sizer');
require('@openzeppelin/hardhat-upgrades');
//require("@nomicfoundation/hardhat-chai-matchers");

const PRIVATE_KEY = process.env.PRIV_KEY 

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 100
          },
          viaIR: true,
	  evmVersion: `paris`
        }
      }
    ]
  },
  networks: {
    dev: {
      url: `http://127.0.0.1:8545`,
      gasPrice: 5000000000,
      chainId: 97,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    bsc_test: {
      url: `https://bsc-testnet.publicnode.com`,
      gasPrice: 5000000000,
      chainId: 97,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    bsc_main: {
      url: 'https://bsc-dataseed3.binance.org',
      gasPrice: 3000000000,
      chainId: 56,
      accounts: [`0x${PRIVATE_KEY}`]
    }
  },
  etherscan: {
    apiKey: {
      bsc: 'WG1N59XV59YT1M2WYPI3SNFSCKHJUDC8JB',
      bscTestnet: 'WG1N59XV59YT1M2WYPI3SNFSCKHJUDC8JB',
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false
  }
};
