// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Financial/PlatformToken.sol";

contract Governance is Ownable {
    
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed, Canceled }
    
    struct Proposal {
        uint id;
        address proposer;
        address[] targets;          // Contracts to call
        uint[] values;              // ETH to send with calls
        bytes[] calldatas;          // Function calls to encode
        uint voteStart;             // Block number when voting starts
        uint voteEnd;               // Block number when voting ends
        uint forVotes;
        uint againstVotes;
        bool canceled;
        bool executed;
    }

    PlatformToken public immutable token;
    
    uint public votingDelay;    // Blocks to wait before voting starts
    uint public votingPeriod;   // Blocks for which voting is active
    uint public proposalThreshold; // Minimum tokens required to create a proposal

    uint public proposalCount;
    mapping(uint => Proposal) public proposals;
    mapping(uint => mapping(address => bool)) public hasVoted;

    event ProposalCreated(uint indexed proposalId, address indexed proposer, address[] targets, string description);
    event VoteCast(address indexed voter, uint indexed proposalId, bool inFavor, uint weight);

    constructor(address _tokenAddress, address _initialOwner, uint _votingDelay, uint _votingPeriod, uint _proposalThreshold) Ownable(_initialOwner) {
        token = PlatformToken(_tokenAddress);
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
    }

    function propose(address[] memory _targets, uint[] memory _values, bytes[] memory _calldatas, string memory _description) external returns (uint) {
        require(token.getVotes(msg.sender) >= proposalThreshold, "Governance: Proposer has insufficient voting power");
        require(_targets.length == _values.length && _targets.length == _calldatas.length, "Governance: Invalid proposal parameters");

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.targets = _targets;
        newProposal.values = _values;
        newProposal.calldatas = _calldatas;
        newProposal.voteStart = block.number + votingDelay;
        newProposal.voteEnd = block.number + votingDelay + votingPeriod;
        
        emit ProposalCreated(proposalCount, msg.sender, _targets, _description);
        return proposalCount;
    }

    function castVote(uint _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(getState(_proposalId) == ProposalState.Active, "Governance: Voting is not active");
        require(!hasVoted[_proposalId][msg.sender], "Governance: Voter has already voted");

        uint voteWeight = token.getVotes(msg.sender);
        require(voteWeight > 0, "Governance: No voting power");

        if (_support) {
            proposal.forVotes += voteWeight;
        } else {
            proposal.againstVotes += voteWeight;
        }

        hasVoted[_proposalId][msg.sender] = true;
        emit VoteCast(msg.sender, _proposalId, _support, voteWeight);
    }
    
    function execute(uint _proposalId) external payable {
        Proposal storage proposal = proposals[_proposalId];
        require(getState(_proposalId) == ProposalState.Succeeded, "Governance: Proposal not successful");
        
        proposal.executed = true;
        
        for (uint i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{value: proposal.values[i]}(proposal.calldatas[i]);
            require(success, "Governance: Execution failed");
        }
    }
    
    function getState(uint _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (proposal.canceled) {
            return ProposalState.Canceled;
        }
        if (block.number <= proposal.voteStart) {
            return ProposalState.Pending;
        }
        if (block.number <= proposal.voteEnd) {
            return ProposalState.Active;
        }
        // NOTE: Quorum logic would be needed here for a robust system
        if (proposal.forVotes > proposal.againstVotes) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }
}