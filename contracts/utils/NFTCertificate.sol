// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
contract NFTCertificate is ERC721, ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter; address public minterAddress;
    event CertificateMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event MinterUpdated(address indexed newMinter);
    constructor(address initialOwner, string memory name, string memory symbol) ERC721(name, symbol) Ownable(initialOwner) {}
    function safeMint(address _freelancer, string memory _tokenURI) external {
        require(msg.sender == minterAddress, "NFTCertificate: Caller is not the authorized minter");
        uint256 newItemId = ++_tokenIdCounter;
        _safeMint(_freelancer, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        emit CertificateMinted(_freelancer, newItemId, _tokenURI);
    }
    function setMinter(address _minter) external onlyOwner { minterAddress = _minter; emit MinterUpdated(_minter); }
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) { return super.tokenURI(tokenId); }
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) { return super.supportsInterface(interfaceId); }
}