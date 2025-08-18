// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUserIdentity
 * @dev This interface defines the essential functions of the UserIdentity contract
 * that other contracts in the ecosystem need to interact with. It allows for
 * decoupled architecture, where contracts can communicate without having the full
 * source code of the other, preventing circular dependencies and improving modularity.
 */
interface IUserIdentity {
    /**
     * @dev A struct to hold all public-facing information about a user's profile.
     */
    struct UserProfile {
        address userAddress;      // The user's wallet address.
        string username;          // A unique, human-readable username.
        string skills;            // A string of user-defined skills, e.g., "Solidity,React,UI/UX".
        bytes ipfsPortfolioHash;  // An IPFS content identifier (CID) pointing to a JSON file with portfolio details.
        uint256 reputationScore;  // A numerical score representing the user's reputation.
        uint256 projectsCompleted; // A counter for successfully completed projects.
    }

    /**
     * @notice Updates the reputation score for a given user.
     * @dev This is a protected function that should only be callable by the authorized Reputation contract.
     * @param _user The address of the user whose score is being updated.
     * @param _newScore The user's newly calculated reputation score.
     */
    function updateReputation(address _user, uint256 _newScore) external;

    /**
     * @notice Increments the completed projects counter for a user.
     * @dev This is a protected function that should only be callable by an authorized contract
     *      (e.g., the Project contract upon successful completion).
     * @param _user The address of the user who completed a project.
     */
    function incrementProjectsCompleted(address _user) external;

    /**
     * @notice Fetches the full profile for a given user address.
     * @param _user The address of the user.
     * @return UserProfile A struct containing all of the user's profile data.
     */
    function getProfile(address _user) external view returns (UserProfile memory);
}