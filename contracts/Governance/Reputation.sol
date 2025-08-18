// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUserIdentity.sol";
contract Reputation is Ownable {
    IUserIdentity public immutable userIdentity;
    address public projectAuthority;
    event RatingSubmitted(address indexed rater, address indexed ratee, uint256 score);
    event AuthorityUpdated(address indexed newAuthority);
    constructor(address _initialOwner, address _userIdentityAddress) Ownable(_initialOwner) { userIdentity = IUserIdentity(_userIdentityAddress); }
    modifier onlyAuthorized() { require(msg.sender == projectAuthority, "Reputation: Not an authorized caller"); _; }
    function submitRating(address _rater, address _ratee, uint256 _score) external onlyAuthorized {
        require(_score >= 1 && _score <= 5, "Reputation: Score must be between 1 and 5");
        IUserIdentity.UserProfile memory profile = userIdentity.getProfile(_ratee);
        uint256 scaledScore = _score * 100; uint256 newScore;
        if (profile.projectsCompleted == 0) { newScore = scaledScore; } else { newScore = ((profile.reputationScore * profile.projectsCompleted) + scaledScore) / (profile.projectsCompleted + 1); }
        userIdentity.updateReputation(_ratee, newScore);
        emit RatingSubmitted(_rater, _ratee, _score);
    }
    function setProjectAuthority(address _authority) external onlyOwner { projectAuthority = _authority; emit AuthorityUpdated(_authority); }
}