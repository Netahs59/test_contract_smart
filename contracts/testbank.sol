// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VulnerableBank - A Deliberately Vulnerable Smart Contract for Testing
 * @dev WARNING: This contract contains multiple security vulnerabilities
 * DO NOT USE IN PRODUCTION - FOR EDUCATIONAL/TESTING PURPOSES ONLY
 * 
 * Vulnerabilities included:
 * 1. Reentrancy attacks
 * 2. Integer overflow/underflow
 * 3. Access control issues
 * 4. Timestamp manipulation
 * 5. Front-running vulnerabilities
 * 6. Denial of Service attacks
 * 7. Race conditions
 * 8. Unprotected selfdestruct
 * 9. Weak randomness
 * 10. Gas griefing
 * 11. Storage collision
 * 12. Unchecked external calls
 */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Vulnerable interface for external calls
interface IVulnerableToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract VulnerableBank {
    
    // State variables with potential issues
    mapping(address => uint256) public balances;
    mapping(address => uint256) public depositTimestamps;
    mapping(address => bool) public isVIP;
    mapping(address => uint256) public loanAmounts;
    mapping(address => uint256) private secretNumbers;
    
    address public owner;
    address public admin;
    uint256 public totalDeposits;
    uint256 public interestRate = 5; // 5%
    uint256 public minimumDeposit = 1 ether;
    uint256 public maxWithdrawal = 10 ether;
    bool public emergencyStop = false;
    
    // Vulnerable: Public array that can cause DoS
    address[] public depositors;
    uint256[] public largeArray;
    
    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event LoanTaken(address indexed user, uint256 amount);
    event InterestPaid(address indexed user, uint256 amount);
    event VIPStatusChanged(address indexed user, bool status);
    
    // Modifiers with vulnerabilities
    modifier onlyOwner() {
        // Vulnerable: tx.origin instead of msg.sender
        require(tx.origin == owner, "Not owner");
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }
    
    // Vulnerable: No access control
    modifier notInEmergency() {
        require(!emergencyStop, "Emergency stop activated");
        _;
    }
    
    modifier validAmount(uint256 amount) {
        // Vulnerable: No check for zero amount
        require(amount > 0, "Amount must be positive");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        admin = msg.sender;
        // Vulnerable: Predictable initial state
        secretNumbers[msg.sender] = block.timestamp;
    }
    
    // Vulnerable deposit function - Reentrancy possible
    function deposit() external payable notInEmergency validAmount(msg.value) {
        // Vulnerable: State changes after external call
        require(msg.value >= minimumDeposit, "Below minimum deposit");
        
        // Vulnerable: Integer overflow possible (though less likely in 0.8+)
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        depositTimestamps[msg.sender] = block.timestamp;
        
        // Vulnerable: DoS by pushing to unbounded array
        if (balances[msg.sender] == msg.value) {
            depositors.push(msg.sender);
        }
        
        // Vulnerable: External call without checks
        if (msg.value > 5 ether) {
            isVIP[msg.sender] = true;
            emit VIPStatusChanged(msg.sender, true);
        }
        
        emit Deposit(msg.sender, msg.value);
        
        // Vulnerable: Reentrancy - state changes before this point
        if (msg.value > 10 ether) {
            payable(msg.sender).call{value: msg.value / 100}(""); // 1% bonus
        }
    }
    
    // Vulnerable withdrawal - Classic reentrancy
    function withdraw(uint256 amount) external notInEmergency {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount <= maxWithdrawal, "Exceeds maximum withdrawal");
        
        // Vulnerable: External call before state change
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        // Vulnerable: State change after external call
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        
        emit Withdrawal(msg.sender, amount);
    }
    
    // Vulnerable: Timestamp manipulation
    function calculateInterest(address user) public view returns (uint256) {
        if (depositTimestamps[user] == 0) return 0;
        
        // Vulnerable: Using block.timestamp for critical logic
        uint256 timeHeld = block.timestamp - depositTimestamps[user];
        uint256 interest = (balances[user] * interestRate * timeHeld) / (365 days * 100);
        
        return interest;
    }
    
    // Vulnerable: Front-running opportunity
    function claimInterest() external {
        uint256 interest = calculateInterest(msg.sender);
        require(interest > 0, "No interest to claim");
        
        // Vulnerable: No reentrancy protection
        depositTimestamps[msg.sender] = block.timestamp;
        balances[msg.sender] += interest;
        
        emit InterestPaid(msg.sender, interest);
    }
    
    // Vulnerable loan system
    function takeLoan(uint256 amount) external {
        // Vulnerable: No proper collateral check
        require(balances[msg.sender] > 0, "Must have deposit");
        require(amount <= balances[msg.sender] * 2, "Loan too large");
        
        loanAmounts[msg.sender] += amount;
        
        // Vulnerable: Unchecked external call
        payable(msg.sender).call{value: amount}("");
        
        emit LoanTaken(msg.sender, amount);
    }
    
    // Vulnerable: Weak access control
    function setVIPStatus(address user, bool status) external {
        // Vulnerable: Anyone can call this
        isVIP[user] = status;
        emit VIPStatusChanged(user, status);
    }
    
    // Vulnerable: DoS through gas limit
    function distributeRewards() external onlyAdmin {
        // Vulnerable: Unbounded loop
        for (uint256 i = 0; i < depositors.length; i++) {
            address user = depositors[i];
            uint256 reward = balances[user] / 1000; // 0.1% reward
            balances[user] += reward;
        }
    }
    
    // Vulnerable: Weak randomness
    function generateSecretNumber() external {
        // Vulnerable: Predictable randomness
        uint256 secretNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender
        ))) % 1000;
        
        secretNumbers[msg.sender] = secretNumber;
    }
    
    // Vulnerable: Race condition in lottery
    uint256 public lotteryPool;
    mapping(address => bool) public lotteryParticipants;
    address[] public lotteryPlayers;
    
    function joinLottery() external payable {
        require(msg.value == 0.1 ether, "Must pay 0.1 ETH");
        require(!lotteryParticipants[msg.sender], "Already joined");
        
        lotteryParticipants[msg.sender] = true;
        lotteryPlayers.push(msg.sender);
        lotteryPool += msg.value;
    }
    
    // Vulnerable: Miner manipulation
    function drawLottery() external {
        require(lotteryPlayers.length > 0, "No participants");
        
        // Vulnerable: Miner can influence this
        uint256 winnerIndex = uint256(blockhash(block.number - 1)) % lotteryPlayers.length;
        address winner = lotteryPlayers[winnerIndex];
        
        uint256 prize = lotteryPool;
        lotteryPool = 0;
        
        // Reset lottery
        for (uint256 i = 0; i < lotteryPlayers.length; i++) {
            lotteryParticipants[lotteryPlayers[i]] = false;
        }
        delete lotteryPlayers;
        
        // Vulnerable: Unchecked send
        payable(winner).call{value: prize}("");
    }
    
    // Vulnerable: Storage collision through delegatecall
    address public implementation;
    
    function upgrade(address newImplementation) external onlyOwner {
        implementation = newImplementation;
    }
    
    // Vulnerable: Arbitrary delegatecall
    function executeUpgrade(bytes calldata data) external onlyOwner {
        (bool success, ) = implementation.delegatecall(data);
        require(success, "Upgrade failed");
    }
    
    // Vulnerable: Unprotected selfdestruct
    function emergencyShutdown() external onlyOwner {
        selfdestruct(payable(owner));
    }
    
    // Vulnerable: Gas griefing
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        
        // Vulnerable: No gas limit on external calls
        for (uint256 i = 0; i < recipients.length; i++) {
            require(balances[msg.sender] >= amounts[i], "Insufficient balance");
            balances[msg.sender] -= amounts[i];
            balances[recipients[i]] += amounts[i];
            
            // Vulnerable: External call in loop
            payable(recipients[i]).call{value: amounts[i]}("");
        }
    }
    
    // Vulnerable: Integer underflow (even in 0.8+, logic error)
    function emergencyWithdraw() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");
        
        // Vulnerable: Setting to 0 before checks
        balances[msg.sender] = 0;
        
        // If this fails, balance is already 0
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) {
            // Vulnerable: No revert, balance remains 0
            return;
        }
        
        totalDeposits -= balance;
    }
    
    // Vulnerable: Price manipulation
    mapping(address => uint256) public tokenRates;
    
    function setTokenRate(address token, uint256 rate) external {
        // Vulnerable: No access control
        tokenRates[token] = rate;
    }
    
    function exchangeToken(address token, uint256 amount) external {
        IVulnerableToken(token).transfer(address(this), amount);
        
        uint256 ethAmount = (amount * tokenRates[token]) / 1e18;
        require(address(this).balance >= ethAmount, "Insufficient ETH");
        
        // Vulnerable: No slippage protection
        payable(msg.sender).call{value: ethAmount}("");
    }
    
    // Vulnerable: Unchecked array access
    function getLargeArrayElement(uint256 index) external view returns (uint256) {
        // Vulnerable: No bounds checking
        return largeArray[index];
    }
    
    function addToLargeArray(uint256 value) external {
        largeArray.push(value);
    }
    
    // Vulnerable: Signature replay
    mapping(bytes32 => bool) public usedSignatures;
    
    function withdrawWithSignature(
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, amount, nonce));
        
        // Vulnerable: No signature verification
        require(!usedSignatures[hash], "Signature already used");
        usedSignatures[hash] = true;
        
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        
        payable(msg.sender).call{value: amount}("");
    }
    
    // Admin functions with vulnerabilities
    function setOwner(address newOwner) external onlyAdmin {
        // Vulnerable: Admin can change owner
        owner = newOwner;
    }
    
    function setAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }
    
    function setEmergencyStop(bool stop) external {
        // Vulnerable: Anyone can call
        emergencyStop = stop;
    }
    
    function setInterestRate(uint256 rate) external onlyAdmin {
        // Vulnerable: No bounds checking
        interestRate = rate;
    }
    
    // View functions that may leak information
    function getSecretNumber(address user) external view returns (uint256) {
        // Vulnerable: "Secret" number is readable
        return secretNumbers[user];
    }
    
    function getAllDepositors() external view returns (address[] memory) {
        // Vulnerable: Privacy leak
        return depositors;
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Fallback and receive functions
    receive() external payable {
        // Vulnerable: Automatically credits sender
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }
    
    fallback() external payable {
        // Vulnerable: Catches all calls
        revert("Function not found");
    }
}

// Additional vulnerable contract for testing interactions
contract VulnerableToken is IVulnerableToken {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string public name = "VulnToken";
    string public symbol = "VULN";
    
    constructor() {
        _totalSupply = 1000000 * 10**18;
        _balances[msg.sender] = _totalSupply;
    }
    
    function transfer(address to, uint256 amount) external override returns (bool) {
        // Vulnerable: No checks
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    // Vulnerable mint function
    function mint(address to, uint256 amount) external {
        // Vulnerable: Anyone can mint
        _balances[to] += amount;
        _totalSupply += amount;
    }
}