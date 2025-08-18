// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
contract Proposal is Ownable {
    address public immutable submitter; uint256 public immutable proposedCost; string public details; bool public isAccepted;
    event Accepted();
    constructor(address _submitter, string memory _details, uint256 _proposedCost, address _projectContract) Ownable(_projectContract) {
        submitter = _submitter; proposedCost = _proposedCost; details = _details;
    }
    function accept() external onlyOwner { require(!isAccepted, "Proposal: Already accepted"); isAccepted = true; emit Accepted(); }
}