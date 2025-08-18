// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Messaging
 * @dev Facilitates off-chain messaging by logging events with pointers to encrypted data.
 * This contract does NOT store any message content, ensuring privacy and low gas costs.
 */
contract Messaging {
    event MessageSent(address indexed from, address indexed to, bytes ipfsHash);

    /**
     * @notice Sends a message by emitting an event with its off-chain location.
     * @param _to The recipient of the message.
     * @param _ipfsHash The content identifier (CID) of the encrypted message data on IPFS.
     */
    function sendMessage(address _to, bytes memory _ipfsHash) external {
        // Any on-chain logic here would be minimal. For example, you could require
        // that both sender and recipient are registered users in the UserIdentity contract.
        // The primary purpose is to create a verifiable, timestamped log of communication.
        emit MessageSent(msg.sender, _to, _ipfsHash);
    }
}