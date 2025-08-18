// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Escrow
 * @dev This contract acts as a neutral third party to hold funds for a specific project.
 * It is created by a Project contract when a freelancer is hired. Its logic is simple and
 * focused: receive funds, hold them, and release them only upon proper authorization or
 * after a dispute resolution.
 */
contract Escrow {
    enum EscrowState { AwaitingFunding, Funded, Released, Refunded, Locked }

    // --- State Variables ---
    address public immutable depositor;     // The project owner's address.
    address public immutable beneficiary;   // The freelancer's address.
    address public immutable token;         // The ERC20 token used for payment.
    uint256 public immutable amount;        // The total amount to be held in escrow.

    EscrowState public state;
    address public disputeResolver; // The single address authorized to resolve disputes.

    // --- Events ---
    event Funded(uint256 amount);
    event Released(address indexed to, uint256 amount);
    event Refunded(address indexed to, uint256 amount);
    event LockedForDispute();
    event DisputeResolved(address winner);

    constructor(address _token, address _depositor, address _beneficiary, uint256 _amount) {
        token = _token;
        depositor = _depositor;
        beneficiary = _beneficiary;
        amount = _amount;
        state = EscrowState.AwaitingFunding;
    }

    /**
     * @notice The first step where the project owner funds the escrow.
     * @dev This function uses `transferFrom`, meaning the depositor must have first
     *      called `approve` on the token contract to allow this Escrow contract
     *      to pull the funds from their wallet.
     */
    function fund() external {
        require(state == EscrowState.AwaitingFunding, "Escrow: Not awaiting funds");
        IERC20(token).transferFrom(depositor, address(this), amount);
        state = EscrowState.Funded;
        emit Funded(amount);
    }

    /**
     * @notice Releases the funds to the beneficiary (freelancer).
     * @dev This function can only be called by the depositor (owner), which in our
     *      system is triggered by the `acceptWork` function in the Project contract.
     */
    function release() external {
        require(msg.sender == depositor, "Escrow: Caller is not the depositor");
        require(state == EscrowState.Funded, "Escrow: Not in a releasable state");
        
        state = EscrowState.Released;
        IERC20(token).transfer(beneficiary, amount);
        emit Released(beneficiary, amount);
    }

    /**
     * @notice Locks the funds if a dispute is raised in the Project contract.
     */
    function lockForDispute() external {
        require(msg.sender == depositor || msg.sender == beneficiary, "Escrow: Not a party to the contract");
        require(state == EscrowState.Funded, "Escrow: Can only lock funded escrow");
        state = EscrowState.Locked;
        emit LockedForDispute();
    }
    
    /**
     * @notice The final resolution of a dispute, called only by the official DisputeResolution contract.
     * @param winner The address of the party who won the dispute.
     */
    function resolveDispute(address winner) external {
        require(msg.sender == disputeResolver, "Escrow: Caller is not the dispute resolver");
        require(state == EscrowState.Locked, "Escrow: Not locked for dispute");

        if (winner == beneficiary) {
            state = EscrowState.Released;
            IERC20(token).transfer(beneficiary, amount);
        } else {
            // If the winner is not the beneficiary, the funds are refunded to the depositor.
            state = EscrowState.Refunded;
            IERC20(token).transfer(depositor, amount);
        }
        emit DisputeResolved(winner);
    }

    /**
     * @notice Allows the depositor to set the address of the DisputeResolution contract.
     * @dev This is a critical step that connects the escrow to the platform's judiciary system.
     *      It can only be set once.
     */
    function setDisputeResolver(address _resolver) external {
        require(msg.sender == depositor, "Escrow: Not depositor");
        require(disputeResolver == address(0), "Escrow: Resolver already set");
        disputeResolver = _resolver;
    }
}