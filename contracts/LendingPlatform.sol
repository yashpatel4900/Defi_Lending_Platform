// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LPToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract LendingPlatform {
    using PriceConverter for uint256;

    address payable public owner;

    // Total Number of Borrowers
    uint256 public totalBorrowers;
    // Address of all Borrower
    address[] public borrowers;
    // Address to LoanAmount Mapping
    mapping(address => uint256) public addressToLoanAmount;
    // Struct of Loan
    struct LoanInfo {
        address payable borrowedBy;
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

    constructor(LPToken _tokenContractAddress) payable {
        LPTokenContract = _tokenContractAddress;
        totalBorrowers = 0;
        owner = payable(msg.sender);
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You do not have permission for withdraw!"
        );
        _;
    }

    // Lets first build Functionality for Borrower
    // He will pay crypto to get stable coin (Here LP)
    function deposit() public payable {
        // Check if he hasn't taken any loan before
        require(addressToLoanAmount[msg.sender] == 0);

        // uint256 halfOfAmountToBeDeposited = msg.value/2;

        // First he has to Pay
        bool success = payable(address(this)).send(msg.value / 2);
        require(success, "Call Failed");

        // Get LP Token which will be 50% of total amount
        uint256 loanApprovedOfInWei = msg.value / 2;
        LPTokenContract.mint(loanApprovedOfInWei);
        BorrowedLoanInfo[msg.sender]
            .loanApprovedOfInDollar = loanApprovedOfInWei.getConversionRate();

        // Loan Details
        BorrowedLoanInfo[msg.sender] = LoanInfo(
            payable(msg.sender),
            block.timestamp,
            msg.value / 2,
            loanApprovedOfInWei.getConversionRate(),
            loanApprovedOfInWei,
            LPTokenContract.EthToLP(loanApprovedOfInWei),
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
        uint256 time = BorrowedLoanInfo[msg.sender].startLoanTime /
            6000 -
            block.timestamp /
            6000;
        interestToBePaid[msg.sender] =
            (BorrowedLoanInfo[msg.sender].loanAmountInLP * 10 * time) /
            100;
    }

    // Now Let Him Repay in form of Stable Coins (Here LPs) with interest to get back his Crypto
    function repayLoan(uint256 LP_amount) public payable {
        // Check if he is paying back with Interest
        uint256 time = BorrowedLoanInfo[msg.sender].startLoanTime /
            6000 -
            block.timestamp /
            6000;
        require(
            LP_amount >=
                BorrowedLoanInfo[msg.sender].loanAmountInLP +
                    (BorrowedLoanInfo[msg.sender].loanAmountInLP * 10 * time) /
                    100
        );

        // Borrower paying his Loan Amount in LP
        LPTokenContract.refund(BorrowedLoanInfo[msg.sender].loanAmountInLP);
        // _burn(msg.sender, LP_amount - BorrowedLoanInfo[msg.sender].loanAmountInLP);

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

    // Function to Deposit
    function addContractFunds() public payable {
        (bool success, ) = payable(address(this)).call{value: msg.value}("");
        require(success, "Failed to deposit");
    }

    // Function to withdraw all Contract Balance
    function withdrawEthAndLP() public payable onlyOwner {
        // _transfer(address(this), owner, balanceOf(owner));
        bool success = payable(owner).send(address(this).balance);
        require(success, "Failed to withdraw amount");
    }
}
