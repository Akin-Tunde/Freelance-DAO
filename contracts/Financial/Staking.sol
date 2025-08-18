// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard {
    IERC20 public immutable stakingToken; // The ARCH token
    IERC20 public immutable rewardsToken; // Could be ARCH or another token

    mapping(address => uint256) public stakedBalance;
    uint256 public totalStaked;
    
    // NOTE: A full rewards implementation is complex. This contract focuses on the core staking logic.
    // A production system would add logic for calculating and distributing rewards over time.

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    constructor(address _stakingTokenAddress, address _rewardsTokenAddress) {
        stakingToken = IERC20(_stakingTokenAddress);
        rewardsToken = IERC20(_rewardsTokenAddress);
    }

    /**
     * @notice Stakes a specified amount of the staking token.
     * @dev The user must first approve this contract to spend their tokens.
     * @param _amount The amount of tokens to stake.
     */
    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Staking: Cannot stake 0");
        
        stakedBalance[msg.sender] += _amount;
        totalStaked += _amount;
        
        // Pulls the approved tokens from the user's wallet to this contract.
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        
        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Unstakes a specified amount of the staking token.
     * @param _amount The amount of tokens to unstake.
     */
    function unstake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Staking: Cannot unstake 0");
        require(stakedBalance[msg.sender] >= _amount, "Staking: Insufficient staked balance");

        stakedBalance[msg.sender] -= _amount;
        totalStaked -= _amount;
        
        // Transfers the tokens from this contract back to the user.
        stakingToken.transfer(msg.sender, _amount);
        
        emit Unstaked(msg.sender, _amount);
    }
}