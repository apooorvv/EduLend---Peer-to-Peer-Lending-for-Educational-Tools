// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EduLend {
    struct Loan {
        address borrower;
        uint256 amount;
        uint256 interestRate; // in basis points (e.g., 500 = 5%)
        uint256 repaymentPeriod; // in seconds
        uint256 startTime;
        bool isFunded;
        bool isRepaid;
        address lender;
    }

    mapping(uint256 => Loan) public loans;
    uint256 public loanCounter;

    event LoanRequested(uint256 loanId, address borrower, uint256 amount, uint256 interestRate, uint256 repaymentPeriod);
    event LoanFunded(uint256 loanId, address lender);
    event LoanRepaid(uint256 loanId);

    // Borrower requests a loan
    function requestLoan(uint256 amount, uint256 interestRate, uint256 repaymentPeriod) external {
        loanCounter++;
        loans[loanCounter] = Loan({
            borrower: msg.sender,
            amount: amount,
            interestRate: interestRate,
            repaymentPeriod: repaymentPeriod,
            startTime: 0,
            isFunded: false,
            isRepaid: false,
            lender: address(0)
        });
        emit LoanRequested(loanCounter, msg.sender, amount, interestRate, repaymentPeriod);
    }

    // Lender funds a loan
    function fundLoan(uint256 loanId) external payable {
        Loan storage loan = loans[loanId];
        require(!loan.isFunded, "Loan already funded");
        require(msg.value == loan.amount, "Incorrect funding amount");

        loan.isFunded = true;
        loan.startTime = block.timestamp;
        loan.lender = msg.sender;

        payable(loan.borrower).transfer(loan.amount);
        emit LoanFunded(loanId, msg.sender);
    }

    // Borrower repays the loan
    function repayLoan(uint256 loanId) external payable {
        Loan storage loan = loans[loanId];
        require(loan.isFunded, "Loan is not funded");
        require(!loan.isRepaid, "Loan is already repaid");
        require(msg.sender == loan.borrower, "Only the borrower can repay");

        uint256 interest = (loan.amount * loan.interestRate) / 10000;
        uint256 totalRepayment = loan.amount + interest;
        require(msg.value == totalRepayment, "Incorrect repayment amount");

        loan.isRepaid = true;
        payable(loan.lender).transfer(totalRepayment);
        emit LoanRepaid(loanId);
    }

    // Get details of a specific loan
    function getLoanDetails(uint256 loanId) external view returns (
        address borrower,
        uint256 amount,
        uint256 interestRate,
        uint256 repaymentPeriod,
        uint256 startTime,
        bool isFunded,
        bool isRepaid,
        address lender
    ) {
        Loan memory loan = loans[loanId];
        return (
            loan.borrower,
            loan.amount,
            loan.interestRate,
            loan.repaymentPeriod,
            loan.startTime,
            loan.isFunded,
            loan.isRepaid,
            loan.lender
        );
    }
}
