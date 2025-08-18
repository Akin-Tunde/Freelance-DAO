// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IUserIdentity.sol";

contract Reputation {
    IUserIdentity public immutable userIdentity;
    address public projectAuthority; // The contract authorized to trigger ratings

    event RatingSubmitted(address indexed rater, address indexed ratee, uint256 score);

    modifier onlyAuthorized() {
        require(msg.sender == projectAuthority, "Reputation: Not an authorized caller");
        _;
    }

    constructor(address _userIdentityAddress) {
        userIdentity = IUserIdentity(_userIdentityAddress);
    }

    /**
     * @notice Submits a rating for a user after a project is completed.
     * @dev This should be called by an authorized contract (e.g., Project).
     * @param _rater The address of the user giving the rating.
     * @param _ratee The address of the user being rated.
     * @param _score A score from 1 to 5.
     */
    function submitRating(address _rater, address _ratee, uint256 _score) external onlyAuthorized {
        require(_score >= 1 && _score <= 5, "Reputation: Score must be between 1 and 5");
        
        IUserIdentity.UserProfile memory profile = userIdentity.getProfile(_ratee);
        uint256 currentScore = profile.reputationScore;
        uint256 projectsCompleted = profile.projectsCompleted;

        // A simple weighted average calculation. 
        // Scales the 1-5 score to a 100-500 scale to give it more weight.
        uint256 scaledScore = _score * 100;
        
        // If this is the first project, the new score is just the scaled score.
        // Otherwise, calculate the new weighted average.
        uint256 newScore;
        if (projectsCompleted == 0) {
            newScore = scaledScore;
        } else {
            newScore = ((currentScore * projectsCompleted) + scaledScore) / (projectsCompleted + 1);
        }
        
        userIdentity.updateReputation(_ratee, newScore);
        
        emit RatingSubmitted(_rater, _ratee, _score);
    }

    /**
     * @notice Sets the authorized address that can trigger rating updates.
     * @dev Should be owned/controlled by governance.
     */
    function setProjectAuthority(address _authority) external {
        // NOTE: This should have access control (e.g., Ownable)
        projectAuthority = _authority;
    }
}