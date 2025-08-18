// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUserIdentity.sol";

/**
 * @title UserIdentity
 * @author The Architect Team
 * @dev This contract serves as the central registry for all user profiles on the platform.
 * It manages usernames, skills, reputation, and project history. It is Ownable so that
 * authorized contract addresses can be set by a governance process.
 */
contract UserIdentity is Ownable {
    // A mapping from a user's address to their on-chain profile.
    mapping(address => IUserIdentity.UserProfile) public profiles;
    // A mapping from a username string to an address to enforce username uniqueness.
    mapping(string => address) private usernames;

    // The address of the Reputation contract, which is the only one authorized to update scores.
    address public reputationContractAddress;
    // The address of a contract (e.g., a master Project handler) authorized to increment project counts.
    address public projectAuthorityAddress;

    // --- Events ---
    event ProfileCreated(address indexed user, string username);
    event ProfileUpdated(address indexed user);
    event AuthorizedContractSet(string indexed role, address indexed contractAddress);

    // --- Errors ---
    error UsernameTaken(string username);
    error UserNotFound(address user);
    error Unauthorized();

    /**
     * @dev Sets the initial owner of the contract. The owner is responsible for setting
     *      the initial authorized contract addresses.
     * @param initialOwner The address of the deployer, DAO, or multisig wallet.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev A modifier to restrict function access to specific authorized contract addresses.
     * @param authority The required address of the authorized contract.
     */
    modifier onlyAuthorized(address authority) {
        if (msg.sender != authority) revert Unauthorized();
        _;
    }

    /**
     * @notice Allows a new user to create their on-chain profile.
     * @dev A user can only create one profile. Usernames must be unique.
     * @param _username A unique name for the profile.
     * @param _skills A comma-separated string of skills.
     * @param _ipfsPortfolioHash An IPFS CID pointing to detailed portfolio information.
     */
    function createProfile(string memory _username, string memory _skills, bytes memory _ipfsPortfolioHash) external {
        if (profiles[msg.sender].userAddress != address(0)) revert("User already exists");
        if (usernames[_username] != address(0)) revert UsernameTaken(_username);

        profiles[msg.sender] = IUserIdentity.UserProfile({
            userAddress: msg.sender,
            username: _username,
            skills: _skills,
            ipfsPortfolioHash: _ipfsPortfolioHash,
            reputationScore: 100, // All users start with a base reputation score.
            projectsCompleted: 0
        });
        usernames[_username] = msg.sender;

        emit ProfileCreated(msg.sender, _username);
    }

    /**
     * @notice Allows a user to update their mutable profile information.
     * @param _skills The user's updated skills string.
     * @param _ipfsPortfolioHash The user's updated IPFS portfolio CID.
     */
    function updateProfile(string memory _skills, bytes memory _ipfsPortfolioHash) external {
        if (profiles[msg.sender].userAddress == address(0)) revert UserNotFound(msg.sender);
        
        profiles[msg.sender].skills = _skills;
        profiles[msg.sender].ipfsPortfolioHash = _ipfsPortfolioHash;

        emit ProfileUpdated(msg.sender);
    }

    /**
     * @notice Public function to retrieve a user's profile.
     */
    function getProfile(address _user) external view returns (IUserIdentity.UserProfile memory) {
        if (profiles[_user].userAddress == address(0)) revert UserNotFound(_user);
        return profiles[_user];
    }
    
    // --- AUTHORIZED FUNCTIONS ---

    /**
     * @notice Updates a user's reputation score.
     * @dev Can only be called by the official Reputation contract.
     */
    function updateReputation(address _user, uint256 _newScore) external onlyAuthorized(reputationContractAddress) {
        profiles[_user].reputationScore = _newScore;
    }

    /**
     * @notice Increments a user's completed project count.
     * @dev Can only be called by the designated project authority contract.
     */
    function incrementProjectsCompleted(address _user) external onlyAuthorized(projectAuthorityAddress) {
        profiles[_user].projectsCompleted++;
    }

    // --- ADMIN FUNCTIONS ---

    /**
     * @notice Sets the address of the Reputation contract.
     * @dev Can only be called by the owner (governance).
     */
    function setReputationContract(address _address) external onlyOwner {
        reputationContractAddress = _address;
        emit AuthorizedContractSet("Reputation", _address);
    }

    /**
     * @notice Sets the address of the contract authorized to confirm project completions.
     * @dev Can only be called by the owner (governance).
     */
    function setProjectAuthority(address _address) external onlyOwner {
        projectAuthorityAddress = _address;
        emit AuthorizedContractSet("ProjectAuthority", _address);
    }
}