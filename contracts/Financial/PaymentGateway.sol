// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title PaymentGateway
 * @dev This contract is responsible for collecting platform fees from transactions,
 * such as when an Escrow contract successfully releases funds. It is owned by the
 * DAO/governance, which can update the fee percentage and the recipient address.
 */
contract PaymentGateway is Ownable {
    // The address where collected fees are sent (e.g., the DAO treasury).
    address public feeRecipient;
    // The platform fee, represented in basis points (1/100th of a percent). E.g., 250 bps = 2.5%.
    uint256 public platformFeeBps;

    // A mapping to control which contracts (e.g., Escrow implementations) can call `takeFee`.
    mapping(address => bool) public isAuthorizedCaller;

    // --- Events ---
    event FeeTaken(address indexed source, address indexed token, uint256 amount);
    event FeeUpdated(uint256 newFeeBps);
    event RecipientUpdated(address newRecipient);
    event AuthorityUpdated(address indexed caller, bool authorized);

    /**
     * @param initialOwner The address of the DAO's Timelock or multisig.
     * @param _initialFeeRecipient The initial address for the treasury.
     * @param _initialFeeBps The initial platform fee in basis points.
     */
    constructor(address initialOwner, address _initialFeeRecipient, uint256 _initialFeeBps) Ownable(initialOwner) {
        require(_initialFeeRecipient != address(0), "Recipient cannot be zero address");
        // A sanity check to prevent setting an unreasonably high fee.
        require(_initialFeeBps <= 1000, "Fee cannot exceed 10%");
        
        feeRecipient = _initialFeeRecipient;
        platformFeeBps = _initialFeeBps;
    }

    /**
     * @notice Called by an authorized contract (e.g., Escrow) to take the platform fee.
     * @param _token The address of the token being used for payment.
     * @param _from The address holding the funds (e.g., the Escrow contract).
     * @param _totalAmount The total project budget from which the fee is calculated.
     */
    function takeFee(address _token, address _from, uint256 _totalAmount) external {
        require(isAuthorizedCaller[msg.sender], "PaymentGateway: Not an authorized caller");

        uint256 fee = (_totalAmount * platformFeeBps) / 10000;
        if (fee > 0) {
            // NOTE: For this to work, the `_from` contract must have approved this PaymentGateway
            // to spend `fee` amount of its tokens. This is a crucial integration step.
            IERC20(_token).transferFrom(_from, feeRecipient, fee);
            emit FeeTaken(msg.sender, _token, fee);
        }
    }

    // --- ADMIN / GOVERNANCE FUNCTIONS ---

    /**
     * @notice Updates the platform fee. Can only be called by governance.
     * @param _newFeeBps The new fee in basis points.
     */
    function setFeeBps(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 1000, "Fee cannot exceed 10%");
        platformFeeBps = _newFeeBps;
        emit FeeUpdated(_newFeeBps);
    }

    /**
     * @notice Updates the treasury address. Can only be called by governance.
     * @param _newRecipient The new address for the fee recipient.
     */
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Cannot set recipient to zero address");
        feeRecipient = _newRecipient;
        emit RecipientUpdated(_newRecipient);
    }
    
    /**
     * @notice Authorizes or de-authorizes a contract to call the `takeFee` function.
     * @dev Can only be called by governance. This is a security measure to ensure only
     *      trusted system contracts can trigger fee collection.
     * @param _caller The address of the contract to authorize/de-authorize.
     * @param _authorized The authorization status.
     */
    function setCallerAuthority(address _caller, bool _authorized) external onlyOwner {
        isAuthorizedCaller[_caller] = _authorized;
        emit AuthorityUpdated(_caller, _authorized);
    }
}