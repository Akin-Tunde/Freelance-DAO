// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title PlatformToken
 * @author The Architect Team
 * @dev The governance token for the platform, compatible with OpenZeppelin v5.
 * It correctly composes ERC20, Ownable, ERC20Permit, and ERC20Votes.
 */
contract PlatformToken is ERC20, Ownable, ERC20Permit, ERC20Votes {
    
    constructor(address initialOwner)
        ERC20("Architect Token", "ARCH")
        Ownable(initialOwner)
        ERC20Permit("Architect Token")
    {
        _mint(initialOwner, 1_000_000_000 * 10**decimals());
    }

    /**
     * @notice Mints new tokens. Can only be called by the contract owner.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // --- FIX: Override the correct functions as required by the compiler ---

    /**
     * @dev Overrides the _update function to resolve the conflict between ERC20 and ERC20Votes.
     * This is the central hook that ensures voting power snapshots are updated
     * correctly on every transfer, mint, or burn.
     */
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    /**
     * @dev Overrides the nonces function to resolve the conflict between ERC20Permit and its Nonces dependency.
     */
    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}