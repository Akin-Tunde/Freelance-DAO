// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract PaymentGateway is Ownable {
    address public feeRecipient; uint256 public platformFeeBps;
    mapping(address => bool) public isAuthorizedCaller;
    event FeeTaken(address indexed source, address indexed token, uint256 amount); event FeeUpdated(uint256 newFeeBps); event RecipientUpdated(address newRecipient); event AuthorityUpdated(address indexed caller, bool authorized);
    constructor(address initialOwner, address _initialFeeRecipient, uint256 _initialFeeBps) Ownable(initialOwner) { require(_initialFeeRecipient != address(0), "Recipient cannot be zero address"); require(_initialFeeBps <= 1000, "Fee cannot exceed 10%"); feeRecipient = _initialFeeRecipient; platformFeeBps = _initialFeeBps; }
    function takeFee(address _token, address _from, uint256 _totalAmount) external { require(isAuthorizedCaller[msg.sender], "PaymentGateway: Not an authorized caller"); uint256 fee = (_totalAmount * platformFeeBps) / 10000; if (fee > 0) { IERC20(_token).transferFrom(_from, feeRecipient, fee); emit FeeTaken(msg.sender, _token, fee); } }
    function setFeeBps(uint256 _newFeeBps) external onlyOwner { require(_newFeeBps <= 1000, "Fee cannot exceed 10%"); platformFeeBps = _newFeeBps; emit FeeUpdated(_newFeeBps); }
    function setFeeRecipient(address _newRecipient) external onlyOwner { require(_newRecipient != address(0), "Cannot set recipient to zero address"); feeRecipient = _newRecipient; emit RecipientUpdated(_newRecipient); }
    function setCallerAuthority(address _caller, bool _authorized) external onlyOwner { isAuthorizedCaller[_caller] = _authorized; emit AuthorityUpdated(_caller, _authorized); }
}