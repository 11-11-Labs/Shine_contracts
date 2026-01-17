// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

interface IUserDB {
    struct Metadata {
        string Username;
        string MetadataURI;
        address Address;
        uint256[] PurchasedSongIds;
        uint256 Balance;
        bool IsBanned;
    }

    error AlreadyInitialized();
    error NewOwnerIsZeroAddress();
    error NoHandoverRequest();
    error Unauthorized();
    error UserDoesNotExist();
    error UserIsBanned();
    error UsernameIsEmpty();

    event OwnershipHandoverCanceled(address indexed pendingOwner);
    event OwnershipHandoverRequested(address indexed pendingOwner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    function addBalance(uint256 userId, uint256 amount) external;
    function addSong(uint256 userId, uint256 songId) external;
    function addSongs(uint256 userId, uint256[] memory songIds) external;
    function cancelOwnershipHandover() external payable;
    function changeAddress(uint256 id, address newAddress) external;
    function changeBasicData(uint256 id, string memory username, string memory metadataURI) external;
    function completeOwnershipHandover(address pendingOwner) external payable;
    function deductBalance(uint256 userId, uint256 amount) external;
    function deleteSong(uint256 userId, uint256 songId) external;
    function deleteSongs(uint256 userId, uint256[] memory songIdsToDelete) external;
    function exists(uint256 id) external view returns (bool);
    function getAddress(uint256 id) external view returns (address);
    function getBalance(uint256 userId) external view returns (uint256);
    function getCurrentId() external view returns (uint256);
    function getId(address userAddress) external view returns (uint256);
    function getMetadata(uint256 id) external view returns (Metadata memory);
    function getPurchasedSong(uint256 userId) external view returns (uint256[] memory);
    function owner() external view returns (address result);
    function ownershipHandoverExpiresAt(address pendingOwner) external view returns (uint256 result);
    function peekNextId() external view returns (uint256);
    function register(string memory username, string memory metadataURI, address userAddress) external returns (uint256);
    function renounceOwnership() external payable;
    function requestOwnershipHandover() external payable;
    function setBannedStatus(uint256 id, bool isBanned) external;
    function transferOwnership(address newOwner) external payable;
}
