// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSig {
    address public owner;
    address[] public signers;
    uint256 public requiredNum;
    uint256 public txCount;

    address public nextOwner;

    struct Transaction {
        uint256 id;
        uint256 amount;
        address receiver;
        uint256 signersCount;
        bool isExecuted;
        address txCreator;
    }

    Transaction[] public allTransactions;

    // Mapping of transaction id to signer address returning bool:
    mapping(uint256 => mapping(address => bool)) public hasSigned;

    mapping(address => bool) public isValidSigner;

    constructor(address[] memory _validSigners, uint256 _requiredNum) {
        owner = msg.sender;
        signers = _validSigners;
        requiredNum = _requiredNum;

        for (uint256 i = 0; i < _validSigners.length; i++) {
            isValidSigner[_validSigners[i]] = true;
        }
    }

    function initiateTransaction(uint256 _amount, address _receiver) external {
        // Check if the sender is a valid signer
        require(isValidSigner[msg.sender], "not valid signer");

        // Validate input parameters
        require(msg.sender != address(0), "Zero address detected");
        require(_amount > 0, "no zero value allowed");

        // Increment transaction count to generate unique ID
        uint256 _txId = txCount + 1;

        // Create a new transaction and store it in the allTransactions array
        Transaction storage tns = allTransactions[_txId];
        tns.id = _txId;
        tns.amount = _amount;
        tns.receiver = _receiver;
        tns.signersCount = 1;
        tns.txCreator = msg.sender;

        // Add the sender to the list of signers for this transaction
        hasSigned[_txId][msg.sender] = true;

        // Increment transaction count
        txCount++;
    }

    function approveTransaction(uint256 _txId) external {
        // Check if the sender is a valid signer
        require(isValidSigner[msg.sender], "not valid signer");

        // Validate input parameters
        require(msg.sender != address(0), "Zero address detected");
        require(_txId <= txCount, "Invalid transaction id");
        require(!hasSigned[_txId][msg.sender], "Can't sign twice");

        // Get the transaction object from storage
        Transaction storage tns = allTransactions[_txId];

        // Perform various checks before approving the transaction
        require(
            address(this).balance >= tns.amount,
            "Insufficient contract balance"
        );
        require(!tns.isExecuted, "transaction already executed");
        require(tns.signersCount < requiredNum, "required number reached");

        // Increment the signers count for this transaction
        tns.signersCount++;

        // Mark the sender as having signed this transaction
        hasSigned[_txId][msg.sender] = true;

        // If enough signers have approved the transaction, execute it
        if (tns.signersCount == requiredNum) {
            tns.isExecuted = true;
            payable(tns.receiver).transfer(tns.amount);
        }
    }

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "not owner");
        nextOwner = _newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == nextOwner, "not next owner");
        owner = msg.sender;
        nextOwner = address(0);
    }

    function addValidSigner(address _newSigner) external {
        require(msg.sender == owner, "not owner");
        require(!isValidSigner[_newSigner], "signer already exists");
        isValidSigner[_newSigner] = true;
        signers.push(_newSigner);
    }

    function getAllTransactions() external view returns (Transaction[] memory) {
        return allTransactions;
    }

    receive() external payable {}

    fallback() external payable {}
}
