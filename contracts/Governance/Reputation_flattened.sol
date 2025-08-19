
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

// File: contracts/interfaces/IUserIdentity.sol


pragma solidity ^0.8.20;

/**
 * @title IUserIdentity
 * @dev This interface defines the essential functions of the UserIdentity contract
 * that other contracts in the ecosystem need to interact with. It allows for
 * decoupled architecture, where contracts can communicate without having the full
 * source code of the other, preventing circular dependencies and improving modularity.
 */
interface IUserIdentity {
    /**
     * @dev A struct to hold all public-facing information about a user's profile.
     */
    struct UserProfile {
        address userAddress;      // The user's wallet address.
        string username;          // A unique, human-readable username.
        string skills;            // A string of user-defined skills, e.g., "Solidity,React,UI/UX".
        bytes ipfsPortfolioHash;  // An IPFS content identifier (CID) pointing to a JSON file with portfolio details.
        uint256 reputationScore;  // A numerical score representing the user's reputation.
        uint256 projectsCompleted; // A counter for successfully completed projects.
    }

    /**
     * @notice Updates the reputation score for a given user.
     * @dev This is a protected function that should only be callable by the authorized Reputation contract.
     * @param _user The address of the user whose score is being updated.
     * @param _newScore The user's newly calculated reputation score.
     */
    function updateReputation(address _user, uint256 _newScore) external;

    /**
     * @notice Increments the completed projects counter for a user.
     * @dev This is a protected function that should only be callable by an authorized contract
     *      (e.g., the Project contract upon successful completion).
     * @param _user The address of the user who completed a project.
     */
    function incrementProjectsCompleted(address _user) external;

    /**
     * @notice Fetches the full profile for a given user address.
     * @param _user The address of the user.
     * @return UserProfile A struct containing all of the user's profile data.
     */
    function getProfile(address _user) external view returns (UserProfile memory);
}
// File: contracts/Governance/Reputation.sol


pragma solidity ^0.8.20;


contract Reputation is Ownable {
    IUserIdentity public immutable userIdentity;
    address public projectAuthority;
    event RatingSubmitted(address indexed rater, address indexed ratee, uint256 score);
    event AuthorityUpdated(address indexed newAuthority);
    constructor(address _initialOwner, address _userIdentityAddress) Ownable(_initialOwner) { userIdentity = IUserIdentity(_userIdentityAddress); }
    modifier onlyAuthorized() { require(msg.sender == projectAuthority, "Reputation: Not an authorized caller"); _; }
    function submitRating(address _rater, address _ratee, uint256 _score) external onlyAuthorized {
        require(_score >= 1 && _score <= 5, "Reputation: Score must be between 1 and 5");
        IUserIdentity.UserProfile memory profile = userIdentity.getProfile(_ratee);
        uint256 scaledScore = _score * 100; uint256 newScore;
        if (profile.projectsCompleted == 0) { newScore = scaledScore; } else { newScore = ((profile.reputationScore * profile.projectsCompleted) + scaledScore) / (profile.projectsCompleted + 1); }
        userIdentity.updateReputation(_ratee, newScore);
        emit RatingSubmitted(_rater, _ratee, _score);
    }
    function setProjectAuthority(address _authority) external onlyOwner { projectAuthority = _authority; emit AuthorityUpdated(_authority); }
}