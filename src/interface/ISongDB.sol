// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.0;

interface ISongDB {
    struct SongMetadata {
        string Title;
        uint256 PrincipalArtistId;
        uint256[] ArtistIDs;
        string MediaURI;
        string MetadataURI;
        bool CanBePurchased;
        uint256 Price;
        uint256 TimesBought;
        bool IsBanned;
    }

    error AlreadyInitialized();
    error NewOwnerIsZeroAddress();
    error NoHandoverRequest();
    error SongCannotBePurchased();
    error SongDoesNotExist();
    error SongIsBanned();
    error Unauthorized();
    error UserAlreadyBought();
    error UserHasNotBought();

    event OwnershipHandoverCanceled(address indexed pendingOwner);
    event OwnershipHandoverRequested(address indexed pendingOwner);
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    function canUserBuy(
        uint256 id,
        uint256 userId
    ) external view returns (bool);
    function cancelOwnershipHandover() external payable;
    function change(
        uint256 id,
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external;
    function changePrice(uint256 id, uint256 price) external;
    function changePurchaseability(uint256 id, bool canBePurchased) external;
    function checkIsBanned(uint256 id) external view returns (bool);
    function completeOwnershipHandover(address pendingOwner) external payable;
    function exists(uint256 id) external view returns (bool);
    function getCurrentId() external view returns (uint256);
    function getMetadata(
        uint256 id
    ) external view returns (SongMetadata memory);
    function getPrice(uint256 id) external view returns (uint256);
    function getPrincipalArtistId(uint256 id) external view returns (uint256);
    function hasUserPurchased(
        uint256 id,
        uint256 userId
    ) external view returns (bool);
    function isBoughtByUser(
        uint256 id,
        uint256 userId
    ) external view returns (bool);
    function isPurchasable(uint256 id) external view returns (bool);
    function owner() external view returns (address result);
    function ownershipHandoverExpiresAt(
        address pendingOwner
    ) external view returns (uint256 result);
    function peekNextId() external view returns (uint256);
    function purchase(uint256 id, uint256 userId) external;
    function refund(uint256 id, uint256 userId) external returns (bool);
    function register(
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external returns (uint256);
    function renounceOwnership() external payable;
    function requestOwnershipHandover() external payable;
    function setBannedStatus(uint256 id, bool isBanned) external;
    function transferOwnership(address newOwner) external payable;
}
