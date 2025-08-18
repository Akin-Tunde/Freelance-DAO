// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Escrow.sol";
import "../utils/Proposal.sol";

/**
 * @title Project
 * @dev Represents a single freelance job on the platform. This contract manages the project's
 * lifecycle from proposal submissions to hiring, review, and completion or dispute.
 * Each project is a self-contained state machine.
 */
contract Project {
    enum ProjectStatus { Open, InProgress, Review, Completed, Canceled, InDispute }

    // --- State Variables ---
    address public immutable owner;          // The client who created the project.
    address public freelancer;               // The freelancer hired for the project.
    address public immutable paymentToken;   // The ERC20 token for payment.
    address public escrowContract;           // The address of the associated Escrow contract.
    
    string public title;
    uint256 public budget;
    ProjectStatus public status;

    // A mapping from a freelancer's address to their deployed Proposal contract.
    mapping(address => Proposal) public proposals;
    
    // --- Events ---
    event ProjectCreated(string title, string description, uint256 budget);
    event ProposalSubmitted(address indexed freelancer, address proposalContract);
    event FreelancerHired(address indexed freelancer, address indexed escrowContract);
    event WorkSubmitted(address indexed freelancer);
    event WorkAccepted(address indexed owner);
    event Disputed(address indexed initiator);

    constructor(address _owner, string memory _title, string memory _description, uint256 _budget, address _tokenAddress) {
        owner = _owner;
        title = _title;
        budget = _budget;
        paymentToken = _tokenAddress;
        status = ProjectStatus.Open;

        // The description is emitted in an event to make it available to off-chain
        // services without consuming expensive contract storage.
        emit ProjectCreated(_title, _description, _budget);
    }

    /**
     * @notice Allows any user to submit a proposal for this project.
     * @param _details A string describing the freelancer's plan for the project.
     * @param _proposedCost The freelancer's bid for the project.
     */
    function submitProposal(string memory _details, uint256 _proposedCost) external {
        require(status == ProjectStatus.Open, "Project: Not open for proposals");
        require(address(proposals[msg.sender]) == address(0), "Project: Proposal already submitted");

        Proposal newProposal = new Proposal(msg.sender, _details, _proposedCost, address(this));
        
        proposals[msg.sender] = newProposal;
        emit ProposalSubmitted(msg.sender, address(newProposal));
    }

    /**
     * @notice Allows the project owner to hire a freelancer who has submitted a proposal.
     * @dev This action creates a new Escrow contract to secure the project funds.
     * @param _freelancer The address of the freelancer to hire.
     */
    function hireFreelancer(address _freelancer) external {
        require(msg.sender == owner, "Project: Only owner can hire");
        require(status == ProjectStatus.Open, "Project: Project not open");
        require(address(proposals[_freelancer]) != address(0), "Project: No proposal from this address");

        freelancer = _freelancer;
        status = ProjectStatus.InProgress;

        Escrow newEscrow = new Escrow(paymentToken, owner, freelancer, budget);
        escrowContract = address(newEscrow);
        
        emit FreelancerHired(freelancer, escrowContract);
    }

    /**
     * @notice Allows the hired freelancer to signal that the work is ready for review.
     */
    function submitWork() external {
        require(msg.sender == freelancer, "Project: Only freelancer can submit");
        require(status == ProjectStatus.InProgress, "Project: Not in progress");
        status = ProjectStatus.Review;
        emit WorkSubmitted(freelancer);
    }

    /**
     * @notice Allows the project owner to accept the submitted work and release payment.
     * @dev This is the final step in a successful project, triggering the Escrow contract.
     */
    function acceptWork() external {
        require(msg.sender == owner, "Project: Only owner can accept");
        require(status == ProjectStatus.Review, "Project: Work not in review");

        Escrow(escrowContract).release();
        
        status = ProjectStatus.Completed;
        emit WorkAccepted(owner);
    }
    
    /**
     * @notice Allows either the owner or the freelancer to raise a dispute.
     * @dev This freezes the funds in Escrow and transitions the project to the InDispute state.
     */
    function raiseDispute() external {
        require(msg.sender == owner || msg.sender == freelancer, "Project: Not a party to the project");
        require(status == ProjectStatus.InProgress || status == ProjectStatus.Review, "Project: Invalid state for dispute");
        
        Escrow(escrowContract).lockForDispute();
        status = ProjectStatus.InDispute;
        emit Disputed(msg.sender);
    }
}