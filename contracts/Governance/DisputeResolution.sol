// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../core/Escrow.sol";
contract DisputeResolution is Ownable {
    enum DisputeStatus { Voting, Resolved } enum Verdict { Unresolved, ForPlaintiff, ForDefendant }
    struct Dispute { address escrowContract; address plaintiff; address defendant; uint plaintiffVotes; uint defendantVotes; DisputeStatus status; Verdict verdict; }
    mapping(address => bool) public isJuror; uint public disputeCount; mapping(uint => Dispute) public disputes; mapping(uint => mapping(address => bool)) public hasJurorVoted;
    event DisputeOpened(uint indexed disputeId, address indexed escrowContract); event VoteCast(uint indexed disputeId, address indexed juror, Verdict vote); event DisputeResolved(uint indexed disputeId, Verdict verdict);
    constructor(address _initialOwner) Ownable(_initialOwner) {}
    function openDispute(address _escrowContract, address _plaintiff, address _defendant) external onlyOwner {
        disputeCount++; uint id = disputeCount;
        disputes[id] = Dispute({ escrowContract: _escrowContract, plaintiff: _plaintiff, defendant: _defendant, plaintiffVotes: 0, defendantVotes: 0, status: DisputeStatus.Voting, verdict: Verdict.Unresolved });
        emit DisputeOpened(id, _escrowContract);
    }
    function castVote(uint _disputeId, Verdict _vote) external {
        require(isJuror[msg.sender], "Dispute: Not a juror"); Dispute storage dispute = disputes[_disputeId]; require(dispute.status == DisputeStatus.Voting, "Dispute: Voting not active"); require(!hasJurorVoted[_disputeId][msg.sender], "Dispute: Juror has already voted"); require(_vote == Verdict.ForPlaintiff || _vote == Verdict.ForDefendant, "Dispute: Invalid vote");
        if (_vote == Verdict.ForPlaintiff) { dispute.plaintiffVotes++; } else { dispute.defendantVotes++; }
        hasJurorVoted[_disputeId][msg.sender] = true; emit VoteCast(_disputeId, msg.sender, _vote);
    }
    function resolveDispute(uint _disputeId) external onlyOwner {
        Dispute storage dispute = disputes[_disputeId]; require(dispute.status == DisputeStatus.Voting, "Dispute: Not in voting");
        Verdict finalVerdict = (dispute.plaintiffVotes > dispute.defendantVotes) ? Verdict.ForPlaintiff : Verdict.ForDefendant;
        dispute.status = DisputeStatus.Resolved; dispute.verdict = finalVerdict;
        address winner = (finalVerdict == Verdict.ForPlaintiff) ? dispute.plaintiff : dispute.defendant;
        Escrow(dispute.escrowContract).resolveDispute(winner);
        emit DisputeResolved(_disputeId, finalVerdict);
    }
    function addJuror(address _juror) external onlyOwner { isJuror[_juror] = true; }
    function removeJuror(address _juror) external onlyOwner { isJuror[_juror] = false; }
}