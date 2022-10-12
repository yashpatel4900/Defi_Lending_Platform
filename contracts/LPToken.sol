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
            "You do not have permission to mint these tokens!"
        );
        _;
    }

    constructor(uint256 initialSupply) payable ERC20("LPToken", "LP") {
        owner = payable(msg.sender);
        _mint(owner, initialSupply);
    }

    function mint(address recipient, uint256 amount) public onlyOwner {
        _mint(recipient, amount);
    }
}
