// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";
contract PlatformToken is ERC20, Ownable, ERC20Permit, ERC20Votes {
    constructor(address initialOwner)
        ERC20("Architect Token", "ARCH")
        Ownable(initialOwner)
        ERC20Permit("Architect Token")
    {
        _mint(initialOwner, 1_000_000_000 * 10**decimals());
    }
    function mint(address to, uint256 amount) external onlyOwner { _mint(to, amount); }
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) { super._update(from, to, value); }
    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) { return super.nonces(owner); }
}