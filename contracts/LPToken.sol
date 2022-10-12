// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//Define a contract named 'LPToken' that inherits the OpenZeppelin `ERC20` and `ERC20Detailed` contracts.
//solidity
contract LPToken is ERC20 {
    address payable public owner;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You do not have permission for withdraw!"
        );
        _;
    }

    constructor() payable ERC20("LPToken", "LP") {
        owner = payable(msg.sender);
        // _mint(owner, initialAmount);
        _mint(owner, 0);
    }

    receive() external payable {}

    function LPToEth(uint256 amount) public pure returns (uint256) {
        // 1Eth = 1000 LP
        return (amount * 10**18) / 1000;
    }

    function EthToLP(uint256 amount) public pure returns (uint256) {
        return (amount * 1000) / 10**18;
    }

    // Function to buy LP
    function mint() public payable {
        require(msg.value >= 10 * 10**14);
        bool success = payable(address(this)).send(msg.value);
        require(success, "Call Failed");
        _mint(msg.sender, EthToLP(msg.value));
    }

    // Function to get back Eth
    function refund(uint256 LP_amount) public payable {
        require(balanceOf(msg.sender) >= LP_amount);
        // _transfer(msg.sender, address(this), LP_amount);
        _burn(msg.sender, LP_amount);
        (bool success, ) = payable(msg.sender).call{value: LPToEth(LP_amount)}(
            ""
        );
        require(success, "Call Failed");
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
