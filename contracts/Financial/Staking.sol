// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Staking
 * @dev A contract that allows users to stake the PlatformToken (ARCH).
 * Staking can be used for multiple purposes, such as earning rewards, gaining
 * eligibility to become a dispute resolution juror, or getting reduced platform fees.
 * This contract uses the ReentrancyGuard to prevent re-entrancy attacks on staking/unstaking.
 */
contract Staking is ReentrancyGuard {
    // The token that users will stake (ARCH).
    IERC20 public immutable stakingToken;
    // The token that will be distributed as rewards (can also be ARCH).
    IERC20 public immutable rewardsToken;

    // A mapping from a user's address to their staked balance.
    mapping(address => uint256) public stakedBalance;
    // The total amount of tokens currently staked in the contract.
    uint256 public totalStaked;
    
    // --- Events ---
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    /**
     * @dev Sets the immutable token addresses for staking and rewards.
     * @param _stakingTokenAddress The address of the PlatformToken.
     * @param _rewardsTokenAddress The address of the token for rewards distribution.
     */
    constructor(address _stakingTokenAddress, address _rewardsTokenAddress) {
        stakingToken = IERC20(_stakingTokenAddress);
        rewardsToken = IERC20(_rewardsTokenAddress);
    }

    /**
     * @notice Stakes a specified amount of the staking token.
     * @dev The user must first call `approve` on the staking token contract to authorize
     *      this contract to manage their tokens. `nonReentrant` modifier prevents re-entrancy attacks.
     * @param _amount The amount of tokens to stake.
     */
    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Staking: Cannot stake 0");
        
        // Update user and total staked balances.
        stakedBalance[msg.sender] += _amount;
        totalStaked += _amount;
        
        // Pull the approved tokens from the user's wallet into this contract.
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        
        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Unstakes a specified amount of the staking token.
     * @dev `nonReentrant` modifier prevents re-entrancy attacks.
     * @param _amount The amount of tokens to unstake.
     */
    function unstake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Staking: Cannot unstake 0");
        require(stakedBalance[msg.sender] >= _amount, "Staking: Insufficient staked balance");

        // Update user and total staked balances.
        stakedBalance[msg.sender] -= _amount;
        totalStaked -= _amount;
        
        // Transfer the tokens from this contract back to the user.
        stakingToken.transfer(msg.sender, _amount);
        
        emit Unstaked(msg.sender, _amount);
    }

    // NOTE: A full rewards mechanism is complex and beyond the scope of this core contract.
    // It would typically involve calculating rewards per block based on a distribution schedule
    // and allowing users to claim accrued rewards.
}