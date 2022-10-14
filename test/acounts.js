async function main() {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }

  console.log("Currently connected with: " + accounts[0].address);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
