// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

// The "owner" of this contract will be the Project contract that deploys it.
contract Proposal is Ownable {
    // These are value types and can be immutable for gas savings.
    address public immutable submitter;
    uint256 public immutable proposedCost;

    // FIX: 'immutable' has been removed. A string is a dynamic type and cannot be immutable.
    string public details; 
    
    bool public isAccepted;

    event Accepted();

    constructor(
        address _submitter,
        string memory _details,
        uint256 _proposedCost,
        address _projectContract // This sets the Project contract as the owner
    ) Ownable(_projectContract) {
        submitter = _submitter;
        proposedCost = _proposedCost;
        
        // The _details parameter is now assigned to the 'details' state variable.
        details = _details; 
    }

    /**
     * @notice Marks the proposal as accepted.
     * @dev Can only be called by the parent Project contract (the owner).
     */
    function accept() external onlyOwner {
        require(!isAccepted, "Proposal: Already accepted");
        isAccepted = true;
        emit Accepted();
    }
}