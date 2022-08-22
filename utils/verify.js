const { run } = require("hardhat");

/********* Programmatic Verification *********/
const verify = async (contractAddress, args) => {
  console.log("Verfiying contract address...");
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (error) {
    if (error.message.toLowerCase().includes("already verified")) {
      console.log("Already verified");
    } else {
      console.log(error);
    }
  }
};

module.exports = { verify };

// Deploy Address :
// Latest Deploy : https://rinkeby.etherscan.io/address/0x0Ca69b945f68f83a53f28E5822daA02F95c27482#code
// https://rinkeby.etherscan.io/address/0x4B89e79502a1C48dc6DEB8c4aC698b3059B348a8#code
// https://rinkeby.etherscan.io/address/0x3901C979d814Ca1797B72Ed08180C3c52e189397#code
