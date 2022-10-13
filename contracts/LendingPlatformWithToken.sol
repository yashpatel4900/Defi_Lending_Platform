// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LPToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract LendingPlatformInheritance is LPToken {
    using PriceConverter for uint256;

    // address payable public owner;

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

    LPToken public LPTokenContract;

    constructor() payable {
        // LPTokenContract = _tokenContractAddress;
        totalBorrowers = 0;
        owner = payable(msg.sender);
    }

    // receive() external payable{
    // }

    // modifier onlyOwner() {
    //     require(
    //         msg.sender == owner,
    //         "You do not have permission for withdraw!"
    //     );
    //     _;
    // }

    // Lets first build Functionality for Borrower
    // He will pay crypto to get stable coin (Here LP)
    function deposit() public payable {
        // Check if he hasn't taken any loan before
        require(addressToLoanAmount[msg.sender] == 0);

        // uint256 halfOfAmountToBeDeposited = msg.value/2;

        // First he has to Pay.
        // 1. Half Amount will be transferd directly to Contract.
        // 2. Second Half through minting.
        bool success = payable(address(this)).send(msg.value / 2);
        require(success, "Call Failed to deposit");

        // Get LP Token which will be 50% of total amount
        uint256 loanApprovedOfInWei = msg.value / 2;
        mint(loanApprovedOfInWei);

        // Loan Details
        BorrowedLoanInfo[msg.sender] = LoanInfo(
            msg.sender,
            block.timestamp,
            msg.value / 2,
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
        // uint256 time = BorrowedLoanInfo[msg.sender].startLoanTime/6000 - block.timestamp/6000;
        // uint256 time = BorrowedLoanInfo[msg.sender].startLoanTime + 1 minutes ;
        time1 = BorrowedLoanInfo[msg.sender].startLoanTime;
        time2 = block.timestamp;
        timeDifference = time2 - time1;

        // Simple Interest
        // 14% interest for an Year
        // Therefore (r(in %) * t(in min) = 14*1/100*365*24*60 = 0.000000266362253

        // Interest based on minutes
        // * Currently I'm Multiplying this equation with 1000 to check interest amount
        // * That means 1 min = 1000 min
        interestToBePaid[msg.sender] =
            (1000 *
                ((timeDifference / 60) *
                    BorrowedLoanInfo[msg.sender].loanAmountInLP *
                    14)) /
            (100 * 365 * 24 * 60);

        // interestToBePaid[msg.sender] = 100 minutes  * BorrowedLoanInfo[msg.sender].loanAmountInLP * 10 / 10000000;
        // interestToBePaid[msg.sender] = (100 minutes  * BorrowedLoanInfo[msg.sender].loanAmountInLP * 14) / (100*365*24*60);
    }

    // Now Let Him Repay in form of Stable Coins (Here LPs) with interest to get back his Crypto
    function repayLoan(uint256 LP_amount) public payable {
        // Check if he is paying back with Interest
        // uint256 time = BorrowedLoanInfo[msg.sender].startLoanTime/6000 - block.timestamp/6000;
        require(
            LP_amount >=
                BorrowedLoanInfo[msg.sender].loanAmountInLP +
                    ((1000 *
                        (((block.timestamp -
                            BorrowedLoanInfo[msg.sender].startLoanTime) / 60) *
                            BorrowedLoanInfo[msg.sender].loanAmountInLP *
                            14)) / (100 * 365 * 24 * 60))
        );

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

        // // // // CHANGE EVERYTHING BACK TO AS IT WAS

        // !!!!!!!Check if he hasn't taken any loan before
        addressToLoanAmount[msg.sender] == 0;

        // !!!!!!!Get LP Token which will be 60% of total amount
        BorrowedLoanInfo[msg.sender].loanApprovedOfInDollar = 0;

        // !!!!!!!Loan Details
        BorrowedLoanInfo[msg.sender] = LoanInfo(
            payable(msg.sender),
            block.timestamp,
            0,
            0,
            0,
            0,
            true
        );

        // !!!!add his address to list

        // !!!!!!!Assigning Loan Amount
        addressToLoanAmount[msg.sender] = 0;
    }
}
