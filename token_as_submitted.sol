// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.6;

/**
 * Users can buy, sell and transfer tokens using the respective functions.
 * When users buy, they must upload multiples of 1 Gwei (token price), or lose the excess funds.
 * If you sell your tokens, you are given their value and they are removed from the overall supply.
 * totalSupply is the number of tokens available for purchase, initialSupply is the minted totalSupply
 * To find your token balance, use getBalance with your wallet adddress.
**/

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";

contract newToken {
    using SafeMath for uint256;

    //Variables
    uint256 public tokenPrice;
    uint256 private totalSupply; //total token pool remaining
    uint256 public initialSupply; //total tokens minted
    uint256 private burntTokens;
    address private owner; //person who deployed contract
    string public symbol; //simple symbol of currency
    
    //Private Variables
    address private buyer; //buyers address
    uint256 private amount; //number of tokens, not wei!
    bool private successBuy; //flag to show if a buy has happened

    //Mappings
    mapping(address => uint256) balance; //tokens owned by each user

    //Events
    event Purchase(address indexed buyer, uint256 amount);
    event Transfer(address indexed sender, address indexed receiver, uint256 amount);
    event Sell(address indexed seller, uint256 amount);
    event Price(uint256 price);

    constructor() public {
        assert(1 ether == 1e18);
        tokenPrice = 1e9; // price 1Gwei arbitrarily
        owner = msg.sender; //owner is the person who deploys contract on network
        symbol = "MT"; 
        initialSupply = 1000; //arbitrarily set total supply to 1000 - contract raises total 1ETH
        burntTokens = 0; //total tokens taken out of circulation by sales
        totalSupply = initialSupply; //number available to buy is total minted at the beginning.
    }
    
    function buyToken(uint256 _amount) public payable returns(bool success){
        require(msg.value >= tokenPrice.mul(_amount), "You dont have enough ETH to buy this many tokens.");
        require(_amount > 0, "you must buy >0 tokens!");
        
        balance[msg.sender] += _amount; // add tokens to owner balance
        totalSupply = totalSupply.sub(_amount); //remove these from total supply
        emit Purchase(msg.sender,amount); // add this to ledger (mapping)
        successBuy = true;
        return true;
    }
    
    function transfer(address _recipient, uint256 _amount) public payable returns(bool){
        require(_recipient != address(0), "You cannot sent to the zero address." );
        require(balance[msg.sender] >= _amount, "Your token balance is too low.");
        require(_recipient != msg.sender, "You cannot transfer tokens to yourself.");
        
        balance[msg.sender] = balance[msg.sender].sub(_amount);
        balance[_recipient] = balance[_recipient].add(_amount);
        emit Transfer(msg.sender, _recipient, _amount);
        return true;
        
    }
    
    function sellToken(uint256 _amount) public payable returns(bool){
        require(balance[msg.sender] >= _amount, "You dont have enough tokens to sell this amount.");
        require(_amount > 0, "you must sell >0 tokens!");
        
        balance[msg.sender] = balance[msg.sender].sub(_amount); // remove amount from balance
        // totalSupply = totalSupply.add(_amount); //return tokens to totalSupply
        // burn tokens by not returning them to total supply
        burntTokens += _amount; 
        
        msg.sender.transfer(tokenPrice.mul(_amount)); //pay person for their token return
        emit Sell(msg.sender, _amount);
        return true;
    }
    
    // allow the token price to be changed by owner only - this is arbitrary but can be doubled easily
    function changePrice(uint256 price) payable public returns(bool){
        require(msg.sender == owner, "Only the owner can change price.");
        require(successBuy == true,'No tokens have yet been bought. Cannot change price.');
        
        // total outstanding tokens = total minted - totalsold - burntTokens 
        require(((msg.value + contractBalance()) >= price.mul(initialSupply-totalSupply-burntTokens)),
                                                                    'Not enough funds to change price.');
        
        tokenPrice = price;
        //priceChange += 1; //counter of how many times price has changed
        return true;
    }
    
    //a view that returns the amount of tokens that the user owns
    function getBalance(address _user) public view returns(uint256){
        return(balance[_user]);
    }
    
    function contractBalance() public view returns(uint256){
        require(msg.sender == owner, "Owner only can view contract balance");
        
        return address(this).balance;
    }
    
}



