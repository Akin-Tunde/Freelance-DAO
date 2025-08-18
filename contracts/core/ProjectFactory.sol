
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./Project.sol";
contract ProjectFactory {
    address[] public deployedProjects;
    address public governanceAddress;
    event ProjectCreated(address indexed projectContract, address indexed owner, uint256 budget);
    modifier onlyGovernance() { require(msg.sender == governanceAddress, "ProjectFactory: Caller is not the governor"); _; }
    constructor(address _governanceAddress) { governanceAddress = _governanceAddress; }
    function createProject(string memory _title, string memory _description, uint256 _budget, address _tokenAddress) external returns (address) {
        Project newProject = new Project(msg.sender, _title, _description, _budget, _tokenAddress);
        deployedProjects.push(address(newProject));
        emit ProjectCreated(address(newProject), msg.sender, _budget);
        return address(newProject);
    }
    function getDeployedProjects() external view returns (address[] memory) { return deployedProjects; }
    function setGovernanceAddress(address _newAddress) external onlyGovernance { governanceAddress = _newAddress; }
}