// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Escrow {
    enum EscrowState { AwaitingFunding, Funded, Released, Refunded, Locked }
    address public immutable depositor; address public immutable beneficiary; address public immutable token; uint256 public immutable amount;
    EscrowState public state; address public disputeResolver;
    event Funded(uint256 amount); event Released(address indexed to, uint256 amount); event Refunded(address indexed to, uint256 amount); event LockedForDispute(); event DisputeResolved(address winner);
    constructor(address _token, address _depositor, address _beneficiary, uint256 _amount) {
        token = _token; depositor = _depositor; beneficiary = _beneficiary; amount = _amount; state = EscrowState.AwaitingFunding;
    }
    function fund() external { require(state == EscrowState.AwaitingFunding, "Escrow: Not awaiting funds"); IERC20(token).transferFrom(depositor, address(this), amount); state = EscrowState.Funded; emit Funded(amount); }
    function release() external { require(msg.sender == depositor, "Escrow: Caller is not the depositor"); require(state == EscrowState.Funded, "Escrow: Not in a releasable state"); state = EscrowState.Released; IERC20(token).transfer(beneficiary, amount); emit Released(beneficiary, amount); }
    function lockForDispute() external { require(msg.sender == depositor || msg.sender == beneficiary, "Escrow: Not a party to the contract"); require(state == EscrowState.Funded, "Escrow: Can only lock funded escrow"); state = EscrowState.Locked; emit LockedForDispute(); }
    function resolveDispute(address winner) external { require(msg.sender == disputeResolver, "Escrow: Caller is not the dispute resolver"); require(state == EscrowState.Locked, "Escrow: Not locked for dispute"); if (winner == beneficiary) { state = EscrowState.Released; IERC20(token).transfer(beneficiary, amount); } else { state = EscrowState.Refunded; IERC20(token).transfer(depositor, amount); } emit DisputeResolved(winner); }
    function setDisputeResolver(address _resolver) external { require(msg.sender == depositor, "Escrow: Not depositor"); require(disputeResolver == address(0), "Escrow: Resolver already set"); disputeResolver = _resolver; }
}