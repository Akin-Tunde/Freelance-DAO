// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Project.sol";

/**
 * @title ProjectFactory
 * @dev A factory contract responsible for creating and deploying new Project contracts.
 * This pattern keeps the core logic consistent for all projects and allows the platform
 * to track every project created in the ecosystem.
 */
contract ProjectFactory {
    // An array to store the addresses of all created Project contracts.
    address[] public deployedProjects;
    // The address of the DAO's Governance contract.
    address public governanceAddress;

    event ProjectCreated(address indexed projectContract, address indexed owner, uint256 budget);

    /**
     * @dev A modifier to restrict functions to be callable only by the governance contract.
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "ProjectFactory: Caller is not the governor");
        _;
    }

    /**
     * @param _governanceAddress The address of the main Governance contract.
     */
    constructor(address _governanceAddress) {
        governanceAddress = _governanceAddress;
    }

    /**
     * @notice Deploys a new Project contract with the given parameters.
     * @param _title The title of the project.
     * @param _description A brief description of the project scope.
     * @param _budget The total budget for the project in the smallest unit of the token.
     * @param _tokenAddress The address of the ERC20 token to be used for payment.
     * @return The address of the newly created Project contract.
     */
    function createProject(
        string memory _title,
        string memory _description,
        uint256 _budget,
        address _tokenAddress
    ) external returns (address) {
        // ARCHITECTURE NOTE: For gas efficiency in a production environment, this `new Project(...)`
        // call would be replaced by a minimal proxy clone (EIP-1167) pattern.
        Project newProject = new Project(
            msg.sender, // The project owner is the caller of this function.
            _title,
            _description,
            _budget,
            _tokenAddress
        );
        
        deployedProjects.push(address(newProject));
        emit ProjectCreated(address(newProject), msg.sender, _budget);
        return address(newProject);
    }

    /**
     * @notice Retrieves the list of all project addresses created by this factory.
     */
    function getDeployedProjects() external view returns (address[] memory) {
        return deployedProjects;
    }
    
    /**
     * @notice Allows governance to update its own address if it ever needs to be migrated.
     */
    function setGovernanceAddress(address _newAddress) external onlyGovernance {
        governanceAddress = _newAddress;
    }
}