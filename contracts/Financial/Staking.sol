// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
contract Staking is ReentrancyGuard {
    IERC20 public immutable stakingToken; IERC20 public immutable rewardsToken;
    mapping(address => uint256) public stakedBalance; uint256 public totalStaked;
    event Staked(address indexed user, uint256 amount); event Unstaked(address indexed user, uint256 amount);
    constructor(address _stakingTokenAddress, address _rewardsTokenAddress) { stakingToken = IERC20(_stakingTokenAddress); rewardsToken = IERC20(_rewardsTokenAddress); }
    function stake(uint256 _amount) external nonReentrant { require(_amount > 0, "Staking: Cannot stake 0"); stakedBalance[msg.sender] += _amount; totalStaked += _amount; stakingToken.transferFrom(msg.sender, address(this), _amount); emit Staked(msg.sender, _amount); }
    function unstake(uint256 _amount) external nonReentrant { require(_amount > 0, "Staking: Cannot unstake 0"); require(stakedBalance[msg.sender] >= _amount, "Staking: Insufficient staked balance"); stakedBalance[msg.sender] -= _amount; totalStaked -= _amount; stakingToken.transfer(msg.sender, _amount); emit Unstaked(msg.sender, _amount); }
}