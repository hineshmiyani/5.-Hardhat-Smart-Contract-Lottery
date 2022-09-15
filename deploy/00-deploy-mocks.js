const { network, ethers } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");

/**
 * 0.25 is the premium
 * It costs 0.25 LINK per requestl
 */
const BASE_FEE = ethers.utils.parseEther("0.25");

// Calclated value baed on the gas price of the chain
const GAS_PRICE_LINK = 1e9; // 1e9 => 1000000000

// Ethe price increases very much
// Chainlink nodes pat the gas fees to give us randomness and do external execution
// SO they price of requestes change based on the price of gas

/*********** Deploying VRFCoordinatorV2Mock.sol ***********/
module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const args = [BASE_FEE, GAS_PRICE_LINK];

  if (developmentChains.includes(network.name)) {
    log("Local network detected! Deploying mocks...");
    // deplot a mock vrfCoordinator...
    await deploy("VRFCoordinatorV2Mock", {
      from: deployer,
      args: args,
      log: true,
    });
    log("Mocks Deplyoed!");
    log("------------------------------------------");
  }
};

module.exports.tags = ["all", "mocks"];
