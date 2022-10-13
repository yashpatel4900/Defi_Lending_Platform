// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LPToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract LendingPlatformWithToken is LPToken {
    using PriceConverter for uint256;

    // address payable public owner;

    // // // // // // // //
    // Variables for Borrower

    // Total Number of Borrowers
    uint256 public totalBorrowers;
    // Address of all Borrower
    address[] public borrowers;
    // Address to LoanAmount Mapping
    mapping(address => uint256) public addressToLoanAmount;
    // Struct of Loan
    struct LoanInfo {
        address borrowedBy;
        uint256 startLoanTime;
        uint256 amountWithLPInWei;
        uint256 loanApprovedOfInDollar;
        uint256 loanApprovedOfInWei;
        uint256 loanAmountInLP;
        bool payed;
    }
    // Address to Loan Details
    mapping(address => LoanInfo) public BorrowedLoanInfo;
    // address to Interest
    mapping(address => uint256) public interestToBePaid;
    // // // // // // // //

    // // // // // // // //
    // Variables for Lender

    // Total Number of Investers
    uint256 public totalInvester;
    // Address of all Investers
    address[] public investers;
    // Address to InvestmentAmount Mapping
    mapping(address => uint256) public addressToInvestmentAmountInWei;
    // Struct of Invester
    struct InvesterInfo {
        address investedBy;
        uint256 investmentAmountInWei;
        uint256 startInvestmentTime;
        uint256 amountOfLPGenerated;
        uint256 ApproxInterestGained;
        bool didLPReturnedWithProfit;
    }
    // Address to Investment Details
    mapping(address => InvesterInfo) public InvestmentInfo;
    // address to Interest to be returned
    mapping(address => uint256) public interestToBeReturnedInWei;

    // // // // // // // //

    LPToken public LPTokenContract;

    constructor() payable {
        // LPTokenContract = _tokenContractAddress;
        totalBorrowers = 0;
        owner = payable(msg.sender);
    }

    // Lets first build Functionality for Borrower
    // He will pay crypto to get stable coin (Here LP)
    function deposit(uint256 amt) public payable {
        // Check if he hasn't taken any loan before
        require(addressToLoanAmount[msg.sender] == 0);

        // uint256 halfOfAmountToBeDeposited = msg.value/2;

        // First he has to Pay.
        // 1. Half Amount will be transferd directly to Contract.
        // 2. Second Half through minting.
        bool success = payable(address(this)).send(amt / 2);
        require(success, "Call Failed to deposit");

        // Get LP Token which will be 50% of total amount
        uint256 loanApprovedOfInWei = amt / 2;
        mint(loanApprovedOfInWei);

        // Loan Details
        BorrowedLoanInfo[msg.sender] = LoanInfo(
            msg.sender,
            block.timestamp,
            amt / 2,
            0,
            loanApprovedOfInWei,
            EthToLP(loanApprovedOfInWei),
            false
        );

        // add his address to list
        borrowers.push(msg.sender);

        totalBorrowers += 1;

        // Assigning Loan Amount
        addressToLoanAmount[msg.sender] = loanApprovedOfInWei;
    }

    // Let Him Calculate amount of interest he need to pay in form of Stable Coins
    function calculateInterest() public {
        // Time Variables
        uint256 time1;
        uint256 time2;
        uint256 timeDifference;

        time1 = BorrowedLoanInfo[msg.sender].startLoanTime;
        time2 = block.timestamp;
        timeDifference = time2 - time1;

        // Simple Interest
        // 25% interest for an Year
        // Therefore (r(in %) * t(in min) = 25*1/100*365*24*60 = 0.00000047564688

        // Interest based on minutes
        // * Currently I'm Multiplying this equation with 1000 to check interest amount
        // * That means 1 min = 1000000000 min
        interestToBePaid[msg.sender] =
            (100000 *
                ((timeDifference / 60) *
                    BorrowedLoanInfo[msg.sender].loanAmountInLP *
                    25)) /
            (100 * 365 * 24 * 60);
    }

    // Now Let Him Repay in form of Stable Coins (Here LPs) with interest to get back his Crypto
    function repayLoan() public payable {
        uint256 LP_amount;
        uint256 requiredLPsToPayInterest;
        LP_amount =
            BorrowedLoanInfo[msg.sender].loanAmountInLP +
            ((100000 *
                (((block.timestamp -
                    BorrowedLoanInfo[msg.sender].startLoanTime) / 60) *
                    BorrowedLoanInfo[msg.sender].loanAmountInLP *
                    25)) / (100 * 365 * 24 * 60));

        if (
            balanceOf(msg.sender) <=
            BorrowedLoanInfo[msg.sender].loanAmountInLP +
                ((100000 *
                    (((block.timestamp -
                        BorrowedLoanInfo[msg.sender].startLoanTime) / 60) *
                        BorrowedLoanInfo[msg.sender].loanAmountInLP *
                        25)) / (100 * 365 * 24 * 60))
        ) {
            requiredLPsToPayInterest = LP_amount - balanceOf(msg.sender);

            // Check if total of LPs + Amount he could mint is >= The amount he needs to pay loan with interest in LPs.
            require(
                EthToLP(msg.sender.balance) + balanceOf(msg.sender) >= LP_amount
            );
            mint(LPToEth(requiredLPsToPayInterest));
        }

        // Check if he is paying back with Interest
        // require(LP_amount >= BorrowedLoanInfo[msg.sender].loanAmountInLP + (1000 * ((block.timestamp - BorrowedLoanInfo[msg.sender].startLoanTime)/60  * BorrowedLoanInfo[msg.sender].loanAmountInLP * 25) / (100*365*24*60)));

        // Borrower paying his Loan Amount in LP
        // He gets refund (function of LPToken) of whatever amount of LPs he took from Lending Platform
        refund(BorrowedLoanInfo[msg.sender].loanAmountInLP);
        // _burn(msg.sender, LP_amount - BorrowedLoanInfo[msg.sender].loanAmountInLP);
        // Amount of Interest LPs profited by LP will be transferd to Lending Platform Contract Address
        _transfer(
            msg.sender,
            address(this),
            LP_amount - BorrowedLoanInfo[msg.sender].loanAmountInLP
        );

        // Lending Platform Releasing his Crypto Collateral
        bool success = payable(msg.sender).send(
            BorrowedLoanInfo[msg.sender].amountWithLPInWei
        );
        require(success, "Call Failed");

        // // // // // // // // // // // //
        // CHANGE EVERYTHING BACK TO AS IT WAS

        addressToLoanAmount[msg.sender] = 0;
        BorrowedLoanInfo[msg.sender].loanApprovedOfInDollar = 0;

        BorrowedLoanInfo[msg.sender] = LoanInfo(
            payable(msg.sender),
            block.timestamp,
            0,
            0,
            0,
            0,
            true
        );
    }

    // // // // // // // // // // // // // //
    // Functionalities for Lender

    // Firstly a lender will invest crypto and will not get anything back
    // The Crypto Investment will be converted to LPs and thos LPs will be added
    // to LendingPlatform Smart Contract so that whenevery a borrower need to borrow LPs,
    // Platform will not generate new LP.

    function invest(uint256 amt) public payable {
        // First he has to Pay Complete Amount.
        // BUT DUE TO MINT FUNCTIONALY
        // Therefore Let Lender mint first and then transfer Minted tokens to LP.
        mint(amt);
        _transfer(msg.sender, address(this), EthToLP(amt));

        // Now Make him Pay the Crypto Investment Amount
        bool success = payable(address(this)).send(amt);
        require(success, "Call Failed to Invest");

        // IMPORTANT Now LP has Crypto + Minted Token
        // // // // // // // // // //

        // // // // // // // // // //
        //  Fill All required information about invester's investment

        totalInvester += 1;
        investers.push(msg.sender);
        addressToInvestmentAmountInWei[msg.sender] = amt;

        InvestmentInfo[msg.sender] = InvesterInfo(
            msg.sender,
            amt,
            block.timestamp,
            EthToLP(amt),
            calculateInterestToBeReturnedToInvester(),
            false
        );
    }

    function calculateInterestToBeReturnedToInvester()
        public
        returns (uint256)
    {
        // Time Variables
        uint256 time1;
        uint256 time2;
        uint256 timeDifference;

        time1 = InvestmentInfo[msg.sender].startInvestmentTime;
        time2 = block.timestamp;
        timeDifference = time2 - time1;

        // Simple Interest
        // 14% return interest on Investment for an Year
        // Therefore (r(in %) * t(in min) = 14*1/100*365*24*60 = 0.000000266362253

        // Interest based on minutes
        // * Currently I'm Multiplying this equation with 1000 to check interest amount
        // * That means 1 min = 1000000000 min
        interestToBeReturnedInWei[msg.sender] =
            (1000000 *
                ((timeDifference / 60) *
                    InvestmentInfo[msg.sender].investmentAmountInWei *
                    14)) /
            (100 * 365 * 24 * 60);
        InvestmentInfo[msg.sender]
            .ApproxInterestGained = interestToBeReturnedInWei[msg.sender];

        return interestToBeReturnedInWei[msg.sender];
    }

    function getCryptoBackWithInterest() public payable {
        // Check Did msg.sender has invested and Was the Investment returned with Interest
        require(
            InvestmentInfo[msg.sender].investmentAmountInWei > 0 &&
                InvestmentInfo[msg.sender].didLPReturnedWithProfit == false
        );

        // Now in Order to Return
        // 1. Does LP currently have sufficient amount of LPToken (which was genereted) to 'burn again'
        // 'Burn Again' Here means to Exchange them in crypto and send
        // 2. Does LP Smart Contract currently have sufficient Crypto to return as interest?
        require(
            balanceOf(address(this)) >=
                InvestmentInfo[msg.sender].amountOfLPGenerated
        );
        require(
            address(this).balance >= calculateInterestToBeReturnedToInvester()
        );

        // // // // // // // // // // // //
        // Return The Crypto back to Invester with Interest

        // 1. Need to transfer LPToken to msg.sender in order to get him refund
        _transfer(
            address(this),
            msg.sender,
            InvestmentInfo[msg.sender].amountOfLPGenerated
        );
        // 2. Initiate Refund to Burn LPToken and Transfer crypto from SmartContract to Invester
        refund(InvestmentInfo[msg.sender].amountOfLPGenerated);
        // 3. Return the Amount of Interest in Crypto
        bool success = payable(msg.sender).send(
            calculateInterestToBeReturnedToInvester()
        );
        require(success, "Call Failed");

        // // // // // // // // // // // //

        // // // // // // // // // // // //
        // CHANGE EVERYTHING BACK TO AS IT WAS

        totalInvester -= 1;
        addressToInvestmentAmountInWei[msg.sender] = 0;

        InvestmentInfo[msg.sender] = InvesterInfo(
            msg.sender,
            0,
            0,
            EthToLP(0),
            0,
            true
        );

        // // // // // // // // // // // //
    }

    function getBackEth() public payable onlyOwner {
        bool success = payable(owner).send(address(this).balance);
        require(success, "Failed to withdraw amount");
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractLPBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function getMyLPBalance() public view returns (uint256) {
        return balanceOf(msg.sender);
    }

    function getMyLoanInterest() public returns (uint256) {
        calculateInterest();
        return interestToBePaid[msg.sender];
    }

    // For this just call calculateInterestToBeReturnedToInvester()
    // function getMyInvestmentInterest() public returns(uint256){
    // }
}
