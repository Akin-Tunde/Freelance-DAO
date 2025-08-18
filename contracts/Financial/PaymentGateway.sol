// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PaymentGateway is Ownable {
    address public feeRecipient; // Treasury or DAO controlled address
    uint256 public platformFeeBps; // Fee in basis points (e.g., 250 = 2.5%)

    // This contract will need to be authorized to be called by Escrow contracts.
    mapping(address => bool) public isAuthorizedCaller;

    event FeeTaken(address indexed source, address indexed token, uint256 amount);
    event FeeUpdated(uint256 newFeeBps);
    event RecipientUpdated(address newRecipient);
    event AuthorityUpdated(address indexed caller, bool authorized);

    constructor(address initialOwner, address _initialFeeRecipient, uint256 _initialFeeBps) Ownable(initialOwner) {
        require(_initialFeeRecipient != address(0), "Recipient cannot be zero address");
        // Sanity check for fee percentage (e.g., max 10%)
        require(_initialFeeBps <= 1000, "Fee cannot exceed 10%");
        
        feeRecipient = _initialFeeRecipient;
        platformFeeBps = _initialFeeBps;
    }

    /**
     * @notice Called by an authorized contract (e.g., Escrow) to take the platform fee.
     * @param _token The address of the token being used for payment.
     * @param _from The address holding the funds (the Escrow contract).
     * @param _totalAmount The total project budget from which the fee is calculated.
     */
    function takeFee(address _token, address _from, uint256 _totalAmount) external {
        require(isAuthorizedCaller[msg.sender], "PaymentGateway: Not an authorized caller");

        uint256 fee = (_totalAmount * platformFeeBps) / 10000;
        if (fee > 0) {
            // NOTE: The _from contract must have approved this PaymentGateway
            // to spend its tokens. This is a critical integration step.
            IERC20(_token).transferFrom(_from, feeRecipient, fee);
            emit FeeTaken(msg.sender, _token, fee);
        }
    }

    // --- ADMIN / GOVERNANCE FUNCTIONS ---

    function setFeeBps(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 1000, "Fee cannot exceed 10%");
        platformFeeBps = _newFeeBps;
        emit FeeUpdated(_newFeeBps);
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Cannot set recipient to zero address");
        feeRecipient = _newRecipient;
        emit RecipientUpdated(_newRecipient);
    }
    
    function setCallerAuthority(address _caller, bool _authorized) external onlyOwner {
        isAuthorizedCaller[_caller] = _authorized;
        emit AuthorityUpdated(_caller, _authorized);
    }
}