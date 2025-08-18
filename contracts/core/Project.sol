// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./Escrow.sol";
import "../utils/Proposal.sol";
contract Project {
    enum ProjectStatus { Open, InProgress, Review, Completed, Canceled, InDispute }
    address public immutable owner;
    address public freelancer;
    address public immutable paymentToken;
    address public escrowContract;
    string public title;
    uint256 public budget;
    ProjectStatus public status;
    mapping(address => Proposal) public proposals;
    event ProjectCreated(string title, string description, uint256 budget);
    event ProposalSubmitted(address indexed freelancer, address proposalContract);
    event FreelancerHired(address indexed freelancer, address indexed escrowContract);
    event WorkSubmitted(address indexed freelancer);
    event WorkAccepted(address indexed owner);
    event Disputed(address indexed initiator);
    constructor(address _owner, string memory _title, string memory _description, uint256 _budget, address _tokenAddress) {
        owner = _owner; title = _title; budget = _budget; paymentToken = _tokenAddress; status = ProjectStatus.Open;
        emit ProjectCreated(_title, _description, _budget);
    }
    function submitProposal(string memory _details, uint256 _proposedCost) external {
        require(status == ProjectStatus.Open, "Project: Not open for proposals");
        require(address(proposals[msg.sender]) == address(0), "Project: Proposal already submitted");
        Proposal newProposal = new Proposal(msg.sender, _details, _proposedCost, address(this));
        proposals[msg.sender] = newProposal;
        emit ProposalSubmitted(msg.sender, address(newProposal));
    }
    function hireFreelancer(address _freelancer) external {
        require(msg.sender == owner, "Project: Only owner can hire");
        require(status == ProjectStatus.Open, "Project: Project not open");
        require(address(proposals[_freelancer]) != address(0), "Project: No proposal from this address");
        freelancer = _freelancer; status = ProjectStatus.InProgress;
        Escrow newEscrow = new Escrow(paymentToken, owner, freelancer, budget);
        escrowContract = address(newEscrow);
        emit FreelancerHired(freelancer, escrowContract);
    }
    function submitWork() external { require(msg.sender == freelancer, "Project: Only freelancer can submit"); require(status == ProjectStatus.InProgress, "Project: Not in progress"); status = ProjectStatus.Review; emit WorkSubmitted(freelancer); }
    function acceptWork() external { require(msg.sender == owner, "Project: Only owner can accept"); require(status == ProjectStatus.Review, "Project: Work not in review"); Escrow(escrowContract).release(); status = ProjectStatus.Completed; emit WorkAccepted(owner); }
    function raiseDispute() external { require(msg.sender == owner || msg.sender == freelancer, "Project: Not a party to the project"); require(status == ProjectStatus.InProgress || status == ProjectStatus.Review, "Project: Invalid state for dispute"); Escrow(escrowContract).lockForDispute(); status = ProjectStatus.InDispute; emit Disputed(msg.sender); }
}