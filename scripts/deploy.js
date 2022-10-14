const main = async () => {
  const [deployer] = await hre.ethers.getSigners();
  const accountBalance = await deployer.getBalance();

  console.log("Deploying contracts with account: ", deployer.address);
  console.log("Account balance: ", accountBalance.toString());

  const LPContract = await hre.ethers.getContractFactory(
    "LendingPlatformWithToken"
  );
  const LendingPlatformWithToken = await LPContract.deploy();
  await LendingPlatformWithToken.deployed();

  console.log(
    "LendingPlatformWithToken Contract address: ",
    LendingPlatformWithToken.address
  );
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();

// npx hardhat run scripts/deploy.js --network localhost
