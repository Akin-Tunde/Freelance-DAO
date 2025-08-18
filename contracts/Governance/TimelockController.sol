// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/TimelockController.sol";

// This is the contract that will be the ultimate "owner" of other contracts.
// The Governance contract will be its PROPOSER.
contract Timelock is TimelockController {
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
        // The admin of the timelock can be renounced after setup for full decentralization
    ) TimelockController(minDelay, proposers, executors, msg.sender) {}
}