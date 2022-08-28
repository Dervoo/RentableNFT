require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan")
let secret = require("./.secret")
require("dotenv").config()
/** @type import('hardhat/config').HardhatUserConfig */
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
module.exports = {
  solidity: "0.8.9",
  gasReporter: {
    enabled: true,
    allowUnlimitedContractSize: true
  },
  defaultNetwork: "hardhat",
    networks: {
        localhost: {
            url: "http://127.0.0.1:8545/",
            chainId: 31337,
            allowUnlimitedContractSize: true
        },
        rinkeby: {
            url: secret.rinkeby_url,
            accounts: [secret.rinkeby_key],
            chainId: 4
        },
      },
      mocha: {
        timeout: 100000000000
      },
      etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },
      
};
