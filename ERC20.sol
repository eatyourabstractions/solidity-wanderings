// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol"; 

contract ERC20 is IERC20 {
    uint public totalSupply = 1000;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "TestToken";
    string public symbol = "TEST";
    uint8 public decimals = 18;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address recipient, uint amount) external returns (bool) {
         balanceOf[msg.sender] -= amount;
    balanceOf[recipient] += amount;
    emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
            allowance[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        
    allowance[sender][msg.sender] -= amount;

    balanceOf[sender] -= amount;
    balanceOf[recipient] += amount;
    emit Transfer(sender, recipient, amount);
    return true;
    }

    function mint(uint amount) external {
        // code
        balanceOf[msg.sender] += amount;
    totalSupply += amount;
    emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        // code
        balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    emit Transfer(msg.sender, address(0), amount);
    }
}
