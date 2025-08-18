// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUserIdentity.sol";
contract UserIdentity is Ownable {
    mapping(address => IUserIdentity.UserProfile) public profiles;
    mapping(string => address) private usernames;
    address public reputationContractAddress;
    address public projectAuthorityAddress;
    event ProfileCreated(address indexed user, string username);
    event ProfileUpdated(address indexed user);
    event AuthorizedContractSet(string indexed role, address indexed contractAddress);
    error UsernameTaken(string username);
    error UserNotFound(address user);
    error Unauthorized();
    constructor(address initialOwner) Ownable(initialOwner) {}
    modifier onlyAuthorized(address authority) { if (msg.sender != authority) revert Unauthorized(); _; }
    function createProfile(string memory _username, string memory _skills, bytes memory _ipfsPortfolioHash) external {
        if (profiles[msg.sender].userAddress != address(0)) revert("User already exists");
        if (usernames[_username] != address(0)) revert UsernameTaken(_username);
        profiles[msg.sender] = IUserIdentity.UserProfile({ userAddress: msg.sender, username: _username, skills: _skills, ipfsPortfolioHash: _ipfsPortfolioHash, reputationScore: 100, projectsCompleted: 0 });
        usernames[_username] = msg.sender;
        emit ProfileCreated(msg.sender, _username);
    }
    function updateProfile(string memory _skills, bytes memory _ipfsPortfolioHash) external {
        if (profiles[msg.sender].userAddress == address(0)) revert UserNotFound(msg.sender);
        profiles[msg.sender].skills = _skills;
        profiles[msg.sender].ipfsPortfolioHash = _ipfsPortfolioHash;
        emit ProfileUpdated(msg.sender);
    }
    function getProfile(address _user) external view returns (IUserIdentity.UserProfile memory) {
        if (profiles[_user].userAddress == address(0)) revert UserNotFound(_user);
        return profiles[_user];
    }
    function updateReputation(address _user, uint256 _newScore) external onlyAuthorized(reputationContractAddress) { profiles[_user].reputationScore = _newScore; }
    function incrementProjectsCompleted(address _user) external onlyAuthorized(projectAuthorityAddress) { profiles[_user].projectsCompleted++; }
    function setReputationContract(address _address) external onlyOwner { reputationContractAddress = _address; emit AuthorizedContractSet("Reputation", _address); }
    function setProjectAuthority(address _address) external onlyOwner { projectAuthorityAddress = _address; emit AuthorizedContractSet("ProjectAuthority", _address); }
}