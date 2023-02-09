import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      forking: {
        url: "https://matic-mumbai.chainstacklabs.com",
      },
      chainId: 80001,
    },

    mumbai: {
      url: "https://matic-mumbai.chainstacklabs.com",
      chainId: 80001,
      accounts: [
        "",
      ],
    },
  },

  gasReporter: {
    enabled: true,
    currency: "USD",
  },

};



export default config;
