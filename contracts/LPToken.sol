// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import './PriceConverter.sol';

//Define a contract named 'LPToken' that inherits the OpenZeppelin `ERC20` and `ERC20Detailed` contracts.
//solidity
contract LPToken is ERC20 {
    address payable public owner;

    using PriceConverter for uint256;

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

    receive() external payable{
    }

    // // // // // // // //
    // Mapping of address to LP Tokens which were just transfered and not freshly minted
    // This variable will be used for Saving LPs which are need to get back to contract in 
    // order to repay an Invester
    mapping(address => uint256) public addressToTransferableLP;

    // // // // // // // //

    function LPToEth(uint256 amount) public pure returns(uint256){
        // 1Eth = 1000 LP = $1299
        // i.e 1LP = $1.299
        return amount*10**18/1000;
    }

    function EthToLP(uint256 amount) public pure returns(uint256){
        return amount*1000/10**18;
    }

    // Function to buy LP
    function mint() public payable{
        require(msg.value>= 10* 10**14);
        bool success = payable(address(this)).send(msg.value);
        require(success, "Call Failed to mint inside");
        if(balanceOf(address(this)) >= EthToLP(msg.value)){
            _transfer(address(this), msg.sender, EthToLP(msg.value));
            addressToTransferableLP[msg.sender] = addressToTransferableLP[msg.sender] + EthToLP(msg.value);
        } else {
            // _mint(msg.sender, EthToLP(msg.value));

            uint256 remainingTransfer;
            remainingTransfer = EthToLP(msg.value) - balanceOf(address(this));

            // Transfer all LPs from Smart Contract to requesting Person
            addressToTransferableLP[msg.sender] = addressToTransferableLP[msg.sender] + (EthToLP(msg.value) - remainingTransfer);
            _transfer(address(this), msg.sender, EthToLP(msg.value) - remainingTransfer);

            // Mint remaining LPs
            _mint(msg.sender, remainingTransfer);            
        }
    }

    function mint(uint256 eth) public payable{
        require(eth>= 10* 10**14);
        bool success = payable(address(this)).send(eth);
        require(success, "Call Failed");
        // _mint(msg.sender, EthToLP(eth));
        // if(balanceOf(address(this)) > EthToLP(msg.value)){
        //     _transfer(address(this), msg.sender, EthToLP(msg.value));
        // } else {
        //     _mint(msg.sender, EthToLP(eth));
        // }
        if(balanceOf(address(this)) >= EthToLP(eth)){
            _transfer(address(this), msg.sender, EthToLP(eth));
            addressToTransferableLP[msg.sender] = addressToTransferableLP[msg.sender] + EthToLP(eth);
        } else {

            uint256 remainingTransfer;
            remainingTransfer = EthToLP(eth) - balanceOf(address(this));

            // Transfer all LPs from Smart Contract to requesting Person
            addressToTransferableLP[msg.sender] = addressToTransferableLP[msg.sender] + (EthToLP(eth) - remainingTransfer);
            _transfer(address(this), msg.sender, (EthToLP(eth) - remainingTransfer));

            // Mint remaining LPs
            _mint(msg.sender, remainingTransfer);            
        }
    }

    // Function to get back Eth
    function refund(uint256 LP_amount) public payable {
        require(balanceOf(msg.sender) >= LP_amount);

        uint256 differenceOfLPToBurnAfterTransfer;

        if(addressToTransferableLP[msg.sender] >= LP_amount){
            _transfer(msg.sender, address(this), LP_amount);
            addressToTransferableLP[msg.sender] = addressToTransferableLP[msg.sender] - LP_amount;
        } else {
            differenceOfLPToBurnAfterTransfer = LP_amount - addressToTransferableLP[msg.sender];
            _transfer(msg.sender, address(this), addressToTransferableLP[msg.sender]);
            addressToTransferableLP[msg.sender] = 0;
            // _transfer(msg.sender, address(this), LP_amount);
            _burn(msg.sender, differenceOfLPToBurnAfterTransfer);

        }

        // // _transfer(msg.sender, address(this), LP_amount);
        // _burn(msg.sender, LP_amount);
        
        (bool success, ) = payable(msg.sender).call{value: LPToEth(LP_amount)}("");
        require(success, "Call Failed");
    }

    // Function to Deposit
    function addContractFunds() public payable {
        (bool success, ) = payable(address(this)).call{value: msg.value}("");
        require(success, "Failed to deposit");
    }

    // Function to withdraw all Contract Balance
    function withdrawEthAndLP() public payable onlyOwner {
        _transfer(address(this), owner, balanceOf(address(this)));
        // bool success = payable(owner).send(address(this).balance);
        // require(success, "Failed to withdraw amount");
    }
}
