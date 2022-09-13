const { ethers, network } = require("hardhat");
const fs = require("fs");

const FRONT_END_ADDRESSES_FILE =
  "../6. NextJS Smart Contract Lottery/constants/contractAddress.json";
const FRONT_END_ABI_FILE =
  "../6. NextJS Smart Contract Lottery/constants/abi.json";

module.exports = async function () {
  if (process.env.UPDATE_FRONT_END) {
    console.log("Updating front end...");
    updateContractAddresses();
    updateAbi();
  }
};

async function updateAbi() {
  const raffle = await ethers.getContract("Raffle");
  fs.writeFileSync(
    FRONT_END_ABI_FILE,
    raffle.interface.format(ethers.utils.FormatTypes.json)
  );
}

async function updateContractAddresses() {
  const raffle = await ethers.getContract("Raffle");
  const chainId = network.config.chainId.toString();
  const currentAddress = JSON.parse(
    fs.readFileSync(FRONT_END_ADDRESSES_FILE, "utf8")
  );

  if (chainId in currentAddress) {
    // if chainId exist in currentAddress
    // then check  raffle address is includes in chainId array
    // if not then add it
    if (!currentAddress[chainId].includes(raffle.address)) {
      currentAddress[chainId].push(raffle.address);
    }
  } else {
    //if chainId isn't exist in currentAddress, then add it with address

    currentAddress[chainId] = [raffle.address];
  }

  fs.writeFileSync(FRONT_END_ADDRESSES_FILE, JSON.stringify(currentAddress));
}

module.exports.tags = ["all", "frontend"];
