const main = async () => {
  const [owner, randomPerson] = await hre.ethers.getSigners();
  const LPContract = await hre.ethers.getContractFactory(
    "LendingPlatformWithToken"
  );
  const LendingPlatformWithToken = await LPContract.deploy();
  await LendingPlatformWithToken.deployed({
    value: hre.ethers.utils.parseEther("0"),
  });
  console.log("Contract deployed to: ", LendingPlatformWithToken.address);
  console.log("Contract Owner: ", LendingPlatformWithToken.owner);

  let contractBalance;
  contractBalance = await LendingPlatformWithToken.getContractBalance();
  console.log("Present Contract Balance: ", contractBalance);

  let contractLPBalance;
  contractLPBalance = await LendingPlatformWithToken.getContractLPBalance();
  console.log("Present Contract LP Balance: ", contractLPBalance);

  let myLPBalances;
  myLPBalance = await LendingPlatformWithToken.getMyLPBalance();
  console.log("My Wallets LP Balance: ", myLPBalance);

  //   Lets mint
  let mintTxn = await LendingPlatformWithToken.mint(
    (parseFloat("0.1") * 10 ** 18).toString()
  ); // o.1 eth
  await mintTxn.wait();
  console.log(mintTxn);

  myLPBalance = await LendingPlatformWithToken.getMyLPBalance();
  console.log("New My Wallets LP Balance: ", myLPBalance);

  console.log(
    "New Contract Balance is : ",
    LendingPlatformWithToken.getContractBalance()
  );
};

const runMain = async () => {
  try {
    await main();
    process.exit(0); // exit Node process without error
  } catch (error) {
    console.log(error);
    process.exit(1); // exit Node process while indicating 'Uncaught Fatal Exception' error
  }
  // Read more about Node exit ('process.exit(num)') status codes here: https://stackoverflow.com/a/47163396/7974948
};

runMain();
