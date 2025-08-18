// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract Messaging {
    event MessageSent(address indexed from, address indexed to, bytes ipfsHash);
    function sendMessage(address _to, bytes memory _ipfsHash) external { emit MessageSent(msg.sender, _to, _ipfsHash); }
}