// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

interface IArtistDB {
    struct Metadata {
        string Name;
        string MetadataURI;
        address Address;
        uint256 Balance;
        uint256 AccumulatedRoyalties;
        bool IsBanned;
    }

    error AlreadyInitialized();
    error ArtistDoesNotExist();
    error ArtistIsBanned();
    error NameShouldNotBeEmpty();
    error NewOwnerIsZeroAddress();
    error NoHandoverRequest();
    error Unauthorized();

    event OwnershipHandoverCanceled(address indexed pendingOwner);
    event OwnershipHandoverRequested(address indexed pendingOwner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    function addAccumulatedRoyalties(uint256 artistId, uint256 amount) external;
    function addBalance(uint256 artistId, uint256 amount) external;
    function cancelOwnershipHandover() external payable;
    function changeAddress(uint256 id, address newArtistAddress) external;
    function changeBasicData(uint256 id, string memory name, string memory metadataURI) external;
    function checkIsBanned(uint256 id) external view returns (bool);
    function completeOwnershipHandover(address pendingOwner) external payable;
    function deductAccumulatedRoyalties(uint256 artistId, uint256 amount) external;
    function deductBalance(uint256 artistId, uint256 amount) external;
    function exists(uint256 id) external view returns (bool);
    function getAddress(uint256 id) external view returns (address);
    function getBalance(uint256 artistId) external view returns (uint256);
    function getCurrentId() external view returns (uint256);
    function getId(address artistAddress) external view returns (uint256);
    function getMetadata(uint256 id) external view returns (Metadata memory);
    function owner() external view returns (address result);
    function ownershipHandoverExpiresAt(address pendingOwner) external view returns (uint256 result);
    function peekNextId() external view returns (uint256);
    function register(string memory name, string memory metadataURI, address artistAddress) external returns (uint256);
    function renounceOwnership() external payable;
    function requestOwnershipHandover() external payable;
    function setBannedStatus(uint256 artistId, bool action) external;
    function transferOwnership(address newOwner) external payable;
}
