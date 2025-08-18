// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlatformToken is ERC20, Ownable {
    // The constructor calls both parent constructors:
    // ERC20() with the token's name and symbol.
    // Ownable() with the deployer's address as the initial owner.
    constructor(address initialOwner) ERC20("Architect Token", "ARCH") Ownable(initialOwner) {
        // Mint an initial supply to the contract deployer (who is also the owner).
        // This address can be a treasury, a DAO, or a multisig wallet.
        _mint(msg.sender, 1_000_000_000 * 10**decimals());
    }

    /**
     * @notice Allows the owner to mint new tokens.
     * @dev This is a privileged action and should be controlled by governance.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}