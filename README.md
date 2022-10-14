# Decentralized Lending Platform Project

Link to Website - https://LendingPlatform.yashpatel142.repl.co

LendingPlatformWithToken Smart Contract is deployed on Polygon Testnet.
Link to PolyScan Mumbai Testnet - https://mumbai.polygonscan.com/address/0xcc22E2d7EC063eE495a52F77892b2C4CcF5F75BB

Smart Contract Address - 0xcc22E2d7EC063eE495a52F77892b2C4CcF5F75BB

# Things you can Perform on Lending Platform
1. Mint LP (ERC 20 Tokens) - 1 Eth will get you 1000 LP Tokens
2. Borrow LP Tokens when Crypto Currency is deposited as Collateral - You will receive 50% value of your collateral as Loan in form of LP, which will be supposed to be used by you in open market to make profit for Yourself.
3. Lend Crypto - When you lend Crypto to the Platform, it will mint LP Tokens for itself and then will allow any Borrower to use them.

# Interest Rates
1. When Borrowed - Simple interest of 25% per Year. But for testing purposes we will be calculating it for minutes. Also, I have multiplied whole equation with 100000 which means 1 min = 100000 min.
2. When Lent - Simple interest of 14% per Year. But for testing purposes we will be calculating it for minutes. Also, I have multiplied whole equation with 1000000 which means 1 min = 1000000 min.

# Functioning of Smart Contract
1. Suppose a Lender lent 3 Eth to the platform, the platform will mint 3000 LP for itself and its LP token balance will increase by 3000. A time of lending will be noted in the smart contract so that whenever asked for his Crypto back he would get it with interest.
2. Now comes the borrower1 who will deposit suppose 4 Eth to Platform, so as a loan he will get 2000 LP (50% of 4 ETH). It would be supposed that he will gain profits fromm this 2000 LP and will be able to repay his loan with interest in form of LP so that his collateral could be released to him.
Note - The current LP Balace with smart contract was 3000 LP so when 2000 LP was given to borrower1 it was deducted from it i.e. current contract LP balace would be: 3000 - 2000 = 1000.
3. Now comes the borrower2 who will deposit suppose 6 Eth to Platform, so as a loan he will get 3000 LP (50% of 6 ETH). It would be supposed that he will gain profits fromm this 2000 LP and will be able to repay his loan with interest in form of LP so that his collateral could be released to him.
Note - The current LP Balace with smart contract was 1000 LP so when 3000 LP was given to borrower2 it was deducted from it i.e. current contract LP balace would be: 1000 - 1000 = 0 AND new tokens were minted by contract to give borrower2 as loan i.e 2000 LP will be getting freshly minted.
4. Now let borrower1 repay his loan with interest (Mechanism - contract will add his valuation of LP Balance and Crypto Balance and will check does the guy have sufficient amount to repay? If yes, it would check automatically mint LPs that he need to pay as interest and then all his LPs will get transfered to smart contract, while smart contract will release his collateral. If the amount of LP in his balance is greater than or equal to Loan Amount + Interest then it will not mint, Just the LP would have been transfered) so on repayment which would be giving LP, 2000 LP which were just transfered from Smart contract will be transfered back to smart contract and the amount of Interest will be paid in which ever form it was taken from. Therefore, Smart Contract's LP  Balance = 0 + 2000 = 2000
5. Now let borrower2 repay his loan with interest so on repayment which would be giving LP, 1000 LP which were just transfered from Smart contract will be transfered back to smart contract + the freshly minted 2000 LP will get burn and the amount of Interest will be paid in which ever form it was taken from. Therefore, Smart Contract's LP  Balance = (2000 + Interest from Borrower 1) + 1000 + Interest from Borrer2 = 3000 + Interest from Borrower1 and Borrower2.
6. Now let Lender ask for his Crypto back with interest, so in that case


# Polygon Testnet
RPC URL - https://rpc-mumbai.maticvigil.com
Chain ID - 80001
Currency Symbol - MATIC

