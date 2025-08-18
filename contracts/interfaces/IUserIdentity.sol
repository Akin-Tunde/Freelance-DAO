// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUserIdentity
 * @dev Interface for the UserIdentity contract.
 * Defines the external functions that other contracts can call to interact with user profiles.
 */
interface IUserIdentity {
    /**
     * @notice A struct to hold all public information about a user.
     */
    struct UserProfile {
        address userAddress;
        string username;
        string skills;
        bytes ipfsPortfolioHash; // Link to off-chain data (e.g., portfolio JSON on IPFS)
        uint256 reputationScore;
        uint256 projectsCompleted;
    }

    /**
     * @notice Updates the reputation score for a given user.
     * @dev MUST only be callable by the authorized Reputation contract.
     * @param _user The address of the user whose score is being updated.
     * @param _newScore The user's newly calculated reputation score.
     */
    function updateReputation(address _user, uint256 _newScore) external;

    /**
     * @notice Increments the completed projects counter for a user.
     * @dev MUST only be callable by an authorized contract (e.g., Project or Escrow).
     * @param _user The address of the user who completed a project.
     */
    function incrementProjectsCompleted(address _user) external;
    
    /**
     * @notice Fetches the profile for a given user address.
     * @param _user The address of the user.
     * @return UserProfile A struct containing the user's profile data.
     */
    function getProfile(address _user) external view returns (UserProfile memory);
}