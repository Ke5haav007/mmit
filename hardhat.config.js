require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      // Add more compiler versions as needed
    ],
  },

  networks: {
    bscTestNet: {
      url: `https://bsc-dataseed4.binance.org/`,
      accounts: [process.env.PVT_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.BSCSCAN_API_KEY 
  },
  sourcify: {
    enabled: true
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 21,
    enabled: process.env.REPORT_GAS === 'true',
  }
};

// https://data-seed-prebsc-2-s1.binance.org:8545/  - TestNet
// https://bsc-dataseed4.binance.org/ - Mainnet