// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

interface IAlbumDB {
    struct Metadata {
        string Title;
        uint256 PrincipalArtistId;
        string MetadataURI;
        uint256[] MusicIds;
        uint256 Price;
        uint256 TimesBought;
        bool CanBePurchased;
        bool IsASpecialEdition;
        string SpecialEditionName;
        uint256 MaxSupplySpecialEdition;
        bool IsBanned;
    }

    error AlbumCannotHaveZeroSongs();
    error AlbumDoesNotExist();
    error AlbumIsBanned();
    error AlbumMaxSupplyReached();
    error AlbumNotPurchasable();
    error AlreadyInitialized();
    error NewOwnerIsZeroAddress();
    error NoHandoverRequest();
    error Unauthorized();
    error UserAlreadyOwns();
    error UserNotOwnedAlbum();

    event OwnershipHandoverCanceled(address indexed pendingOwner);
    event OwnershipHandoverRequested(address indexed pendingOwner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    function cancelOwnershipHandover() external payable;
    function change(
        uint256 id,
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory musicIds,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external;
    function changePrice(uint256 id, uint256 price) external;
    function changePurchaseability(uint256 id, bool canBePurchased) external;
    function checkIsBanned(uint256 id) external view returns (bool);
    function completeOwnershipHandover(address pendingOwner) external payable;
    function exists(uint256 id) external view returns (bool);
    function getCurrentId() external view returns (uint256);
    function getMetadata(uint256 id) external view returns (Metadata memory);
    function getPrice(uint256 id) external view returns (uint256);
    function getPrincipalArtistId(uint256 id) external view returns (uint256);
    function getTotalSupply(uint256 id) external view returns (uint256);
    function gift(uint256 id, uint256 userId) external returns (uint256[] memory);
    function isAnSpecialEdition(uint256 id) external view returns (bool);
    function isPurchasable(uint256 id) external view returns (bool);
    function isUserOwner(uint256 id, uint256 userId) external view returns (bool);
    function owner() external view returns (address result);
    function ownershipHandoverExpiresAt(address pendingOwner) external view returns (uint256 result);
    function peekNextId() external view returns (uint256);
    function purchase(uint256 id, uint256 userId) external returns (uint256[] memory);
    function refund(uint256 id, uint256 userId) external returns (uint256[] memory, uint256);
    function register(
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory songIDs,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external returns (uint256);
    function renounceOwnership() external payable;
    function requestOwnershipHandover() external payable;
    function setBannedStatus(uint256 id, bool isBanned) external;
    function transferOwnership(address newOwner) external payable;
    function userOwnershipStatus(uint256 id, uint256 userId) external view returns (bytes1);
}
