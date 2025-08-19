
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: contracts/core/Escrow.sol


pragma solidity ^0.8.20;

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
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/utils/Proposal.sol


pragma solidity ^0.8.20;

contract Proposal is Ownable {
    address public immutable submitter; uint256 public immutable proposedCost; string public details; bool public isAccepted;
    event Accepted();
    constructor(address _submitter, string memory _details, uint256 _proposedCost, address _projectContract) Ownable(_projectContract) {
        submitter = _submitter; proposedCost = _proposedCost; details = _details;
    }
    function accept() external onlyOwner { require(!isAccepted, "Proposal: Already accepted"); isAccepted = true; emit Accepted(); }
}
// File: contracts/core/Project.sol


pragma solidity ^0.8.20;


contract Project {
    enum ProjectStatus { Open, InProgress, Review, Completed, Canceled, InDispute }
    address public immutable owner;
    address public freelancer;
    address public immutable paymentToken;
    address public escrowContract;
    string public title;
    uint256 public budget;
    ProjectStatus public status;
    mapping(address => Proposal) public proposals;
    event ProjectCreated(string title, string description, uint256 budget);
    event ProposalSubmitted(address indexed freelancer, address proposalContract);
    event FreelancerHired(address indexed freelancer, address indexed escrowContract);
    event WorkSubmitted(address indexed freelancer);
    event WorkAccepted(address indexed owner);
    event Disputed(address indexed initiator);
    constructor(address _owner, string memory _title, string memory _description, uint256 _budget, address _tokenAddress) {
        owner = _owner; title = _title; budget = _budget; paymentToken = _tokenAddress; status = ProjectStatus.Open;
        emit ProjectCreated(_title, _description, _budget);
    }
    function submitProposal(string memory _details, uint256 _proposedCost) external {
        require(status == ProjectStatus.Open, "Project: Not open for proposals");
        require(address(proposals[msg.sender]) == address(0), "Project: Proposal already submitted");
        Proposal newProposal = new Proposal(msg.sender, _details, _proposedCost, address(this));
        proposals[msg.sender] = newProposal;
        emit ProposalSubmitted(msg.sender, address(newProposal));
    }
    function hireFreelancer(address _freelancer) external {
        require(msg.sender == owner, "Project: Only owner can hire");
        require(status == ProjectStatus.Open, "Project: Project not open");
        require(address(proposals[_freelancer]) != address(0), "Project: No proposal from this address");
        freelancer = _freelancer; status = ProjectStatus.InProgress;
        Escrow newEscrow = new Escrow(paymentToken, owner, freelancer, budget);
        escrowContract = address(newEscrow);
        emit FreelancerHired(freelancer, escrowContract);
    }
    function submitWork() external { require(msg.sender == freelancer, "Project: Only freelancer can submit"); require(status == ProjectStatus.InProgress, "Project: Not in progress"); status = ProjectStatus.Review; emit WorkSubmitted(freelancer); }
    function acceptWork() external { require(msg.sender == owner, "Project: Only owner can accept"); require(status == ProjectStatus.Review, "Project: Work not in review"); Escrow(escrowContract).release(); status = ProjectStatus.Completed; emit WorkAccepted(owner); }
    function raiseDispute() external { require(msg.sender == owner || msg.sender == freelancer, "Project: Not a party to the project"); require(status == ProjectStatus.InProgress || status == ProjectStatus.Review, "Project: Invalid state for dispute"); Escrow(escrowContract).lockForDispute(); status = ProjectStatus.InDispute; emit Disputed(msg.sender); }
}
// File: contracts/core/ProjectFactory.sol


pragma solidity ^0.8.20;

contract ProjectFactory {
    address[] public deployedProjects;
    address public governanceAddress;
    event ProjectCreated(address indexed projectContract, address indexed owner, uint256 budget);
    modifier onlyGovernance() { require(msg.sender == governanceAddress, "ProjectFactory: Caller is not the governor"); _; }
    constructor(address _governanceAddress) { governanceAddress = _governanceAddress; }
    function createProject(string memory _title, string memory _description, uint256 _budget, address _tokenAddress) external returns (address) {
        Project newProject = new Project(msg.sender, _title, _description, _budget, _tokenAddress);
        deployedProjects.push(address(newProject));
        emit ProjectCreated(address(newProject), msg.sender, _budget);
        return address(newProject);
    }
    function getDeployedProjects() external view returns (address[] memory) { return deployedProjects; }
    function setGovernanceAddress(address _newAddress) external onlyGovernance { governanceAddress = _newAddress; }
}