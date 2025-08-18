// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../core/Escrow.sol";

contract DisputeResolution is Ownable {
    
    enum DisputeStatus { Open, Voting, Resolved }
    enum Verdict { Unresolved, Plaintiff, Defendant }

    struct Dispute {
        uint id;
        address escrowContract;
        address plaintiff;
        address defendant;
        uint plaintiffVotes;
        uint defendantVotes;
        DisputeStatus status;
        Verdict verdict;
    }

    // Juror management would be more complex
    mapping(address => bool) public isJuror;
    uint public disputeCount;

    mapping(uint => Dispute) public disputes;
    mapping(uint => mapping(address => bool)) public hasJurorVoted;

    event DisputeOpened(uint indexed disputeId, address indexed escrowContract);
    event VoteCast(uint indexed disputeId, address indexed juror, Verdict vote);
    event DisputeResolved(uint indexed disputeId, Verdict verdict);

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    function openDispute(uint _disputeId, address _escrowContract, address _plaintiff, address _defendant) external {
        // In a real system, this would be access controlled, likely callable by a Project contract
        disputes[_disputeId] = Dispute({
            id: _disputeId,
            escrowContract: _escrowContract,
            plaintiff: _plaintiff,
            defendant: _defendant,
            plaintiffVotes: 0,
            defendantVotes: 0,
            status: DisputeStatus.Voting,
            verdict: Verdict.Unresolved
        });
        emit DisputeOpened(_disputeId, _escrowContract);
    }

    function castVote(uint _disputeId, Verdict _vote) external {
        require(isJuror[msg.sender], "DisputeResolution: Not a juror");
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Voting, "DisputeResolution: Voting not active");
        require(!hasJurorVoted[_disputeId][msg.sender], "DisputeResolution: Juror has already voted");
        require(_vote == Verdict.Plaintiff || _vote == Verdict.Defendant, "DisputeResolution: Invalid vote");

        if (_vote == Verdict.Plaintiff) {
            dispute.plaintiffVotes++;
        } else {
            dispute.defendantVotes++;
        }

        hasJurorVoted[_disputeId][msg.sender] = true;
        emit VoteCast(_disputeId, msg.sender, _vote);
    }

    function resolveDispute(uint _disputeId) external onlyOwner {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Voting, "DisputeResolution: Dispute not in voting");
        // NOTE: A real system would have a voting deadline.

        Verdict finalVerdict;
        if (dispute.plaintiffVotes > dispute.defendantVotes) {
            finalVerdict = Verdict.Plaintiff;
        } else {
            // Ties go to the defendant/freelancer for simplicity here
            finalVerdict = Verdict.Defendant;
        }

        dispute.status = DisputeStatus.Resolved;
        dispute.verdict = finalVerdict;

        // Determine the winner's address and execute on the Escrow contract
        address winner = (finalVerdict == Verdict.Plaintiff) ? dispute.plaintiff : dispute.defendant;
        Escrow(dispute.escrowContract).resolveDispute(winner);
        
        emit DisputeResolved(_disputeId, finalVerdict);
    }
    
    function addJuror(address _juror) external onlyOwner {
        isJuror[_juror] = true;
    }
    
    function removeJuror(address _juror) external onlyOwner {
        isJuror[_juror] = false;
    }
}