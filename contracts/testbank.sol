pragma solidity ^0.8.0;

contract InsecureContract {
    address public owner;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    
    constructor() {
        owner = msg.sender;
        totalSupply = 1000000;
        balances[owner] = totalSupply;
    }
    
    // Missing access control - anyone can mint tokens
    function mint(address to, uint256 amount) public {
        balances[to] += amount;
        totalSupply += amount;
    }
    
    // Weak access control
    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }
    
    // No access control at all
    function emergencyWithdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}
