// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
                                                            
 * @title Shine SongDB
 * @author 11:11 Labs 
 * @notice This contract manages song metadata, user purchases, 
 *         and admin functionalities for the Shine platform.
 */

import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {ArtistDB} from "@shine/contracts/database/ArtistDB.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";
import {OwnableRoles} from "@solady/auth/OwnableRoles.sol";

contract Orchestrator is OwnableRoles {
    uint256 constant ADMIN_ROLE = 1;
    uint256 constant API_ROLE = 2;

    address private albumDbAddress;
    address private artistDbAddress;
    address private songDbAddress;
    address private userDbAddress;

    bytes1 breakerAddressSetup;
    bytes1 breakerShop;

    event SongPurchased(
        uint256 indexed songId,
        uint256 indexed userId,
        uint256 price
    );

    event AlbumPurchased(
        uint256 indexed albumId,
        uint256 indexed userId,
        uint256 price
    );

    constructor(
        address initialOwner,
        address initialAdminAddress,
        address initialAPIAddress
    ) {
        _initializeOwner(initialOwner);
        _grantRoles(initialAdminAddress, ADMIN_ROLE);
        _grantRoles(initialAPIAddress, API_ROLE);
    }

    function buySong(
        uint256 songId,
        uint256 userId
    ) external onlyRoles(API_ROLE) {
        if (!SongDB(songDbAddress).exists(songId)) revert();
        if (!UserDB(userDbAddress).exists(userId)) revert();
        if (!SongDB(albumDbAddress).hasUserPurchased(songId, userId)) revert();
        if (SongDB(songDbAddress).canUserBuy(songId, userId)) revert();

        uint256 price = SongDB(songDbAddress).getPrice(songId);
        if (UserDB(userDbAddress).getBalance(userId) < price) revert();

        uint256 principalArtistId = SongDB(songDbAddress).getPrincipalArtistId(
            songId
        );

        UserDB(userDbAddress).deductBalance(userId, price);
        ArtistDB(artistDbAddress).addBalance(principalArtistId, price);
        SongDB(songDbAddress).purchase(songId, userId);
        UserDB(userDbAddress).addSong(userId, songId);

        emit SongPurchased(songId, userId, price);
    }

    function buyAlbum(
        uint256 albumId,
        uint256 userId
    ) external onlyRoles(API_ROLE) {
        if (!AlbumDB(albumDbAddress).exists(albumId)) revert();
        if (!UserDB(userDbAddress).exists(userId)) revert();
        if (AlbumDB(albumDbAddress).hasUserPurchased(albumId, userId)) revert();
        if (AlbumDB(albumDbAddress).canUserBuy(albumId, userId)) revert();

        uint256 price = AlbumDB(albumDbAddress).getPrice(albumId);
        if (UserDB(userDbAddress).getBalance(userId) < price) revert();

        uint256 principalArtistId = AlbumDB(albumDbAddress)
            .getPrincipalArtistId(albumId);

        UserDB(userDbAddress).deductBalance(userId, price);
        ArtistDB(artistDbAddress).addBalance(principalArtistId, price);
        uint256[] memory songIds = AlbumDB(albumDbAddress).purchase(
            albumId,
            userId
        );

        UserDB(userDbAddress).addSongs(userId, songIds);

        emit AlbumPurchased(albumId, userId, price);
    }

    function registerArtist(
        string memory name,
        string memory metadataURI,
        address payable artistAddress
    ) external onlyRoles(API_ROLE) returns (uint256) {
        return
            ArtistDB(artistDbAddress).register(
                name,
                metadataURI,
                artistAddress
            );
    }

    function chnageDataOfArtist(
        uint256 artistId,
        string memory name,
        string memory metadataURI,
        address payable artistAddress
    ) external onlyRoles(API_ROLE) {
        if (!ArtistDB(artistDbAddress).exists(artistId)) revert();
        ArtistDB(artistDbAddress).changeBasicData(artistId, name, metadataURI);

        if (ArtistDB(artistDbAddress).getAddress(artistId) != artistAddress) {
            ArtistDB(artistDbAddress).changeAddress(artistId, artistAddress);
        }
    }

    function registerUser(
        string memory username,
        string memory metadataURI,
        address payable userAddress
    ) external onlyRoles(API_ROLE) returns (uint256) {
        return
            UserDB(userDbAddress).register(username, metadataURI, userAddress);
    }

    function changeDataOfUser(
        uint256 userId,
        string memory username,
        string memory metadataURI,
        address payable userAddress
    ) external onlyRoles(API_ROLE) {
        if (!UserDB(userDbAddress).exists(userId)) revert();
        UserDB(userDbAddress).changeBasicData(userId, username, metadataURI);

        if (UserDB(userDbAddress).getAddress(userId) != userAddress) {
            UserDB(userDbAddress).changeAddress(userId, userAddress);
        }
    }

    function registerSong(
        uint256 artistId,
        string memory title,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external onlyRoles(API_ROLE) returns (uint256) {
        if (!ArtistDB(artistDbAddress).exists(artistId)) revert();

        return
            SongDB(songDbAddress).register(
                title,
                artistId,
                artistIDs,
                mediaURI,
                metadataURI,
                canBePurchased,
                price
            );
    }

    function changeDataOfSong(
        uint256 songId,
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external onlyRoles(API_ROLE) {
        if (!SongDB(songDbAddress).exists(songId)) revert();
        if (
            SongDB(artistDbAddress).getPrincipalArtistId(principalArtistId) !=
            principalArtistId
        ) revert();

        SongDB(songDbAddress).change(
            songId,
            title,
            principalArtistId,
            artistIDs,
            mediaURI,
            metadataURI,
            canBePurchased,
            price
        );
    }

    function changePurchaseabilityAndPriceOfSong(
        uint256 songId,
        bool canBePurchased,
        uint256 price
    ) external onlyRoles(API_ROLE) {
        if (!SongDB(songDbAddress).exists(songId)) revert();

        SongDB(songDbAddress).changePurchaseability(songId, canBePurchased);
        SongDB(songDbAddress).changePrice(songId, price);
    }

    function registerAlbum(
        uint256 artistId,
        string memory title,
        string memory metadataURI,
        uint256[] memory songIDs,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external onlyRoles(API_ROLE) returns (uint256) {
        if (!ArtistDB(artistDbAddress).exists(artistId)) revert();
        for (uint256 i = 0; i < songIDs.length; i++) {
            if (!SongDB(songDbAddress).exists(songIDs[i])) revert();
        }

        return
            AlbumDB(albumDbAddress).register(
                title,
                artistId,
                metadataURI,
                songIDs,
                price,
                canBePurchased,
                isASpecialEdition,
                specialEditionName,
                maxSupplySpecialEdition
            );
    }

    function changeDataOfAlbum(
        uint256 albumId,
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory songIDs,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external onlyRoles(API_ROLE) {
        if (!AlbumDB(albumDbAddress).exists(albumId)) revert();

        if (
            AlbumDB(artistDbAddress).getPrincipalArtistId(principalArtistId) !=
            principalArtistId
        ) revert();

        for (uint256 i = 0; i < songIDs.length; i++) {
            if (!SongDB(songDbAddress).exists(songIDs[i])) revert();
        }

        AlbumDB(albumDbAddress).change(
            albumId,
            title,
            principalArtistId,
            metadataURI,
            songIDs,
            price,
            canBePurchased,
            isASpecialEdition,
            specialEditionName,
            maxSupplySpecialEdition
        );
    }

    function changePurchaseabilityAndPriceOfAlbum(
        uint256 albumId,
        bool canBePurchased,
        uint256 price
    ) external onlyRoles(API_ROLE) {
        if (!AlbumDB(albumDbAddress).exists(albumId)) revert();

        AlbumDB(albumDbAddress).changePurchaseability(albumId, canBePurchased);
        AlbumDB(albumDbAddress).changePrice(albumId, price);
    }

    function setAPIRole(
        address apiAddress
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        _grantRoles(apiAddress, API_ROLE);
    }

    function revokeApiRole(
        address apiAddress
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        _removeRoles(apiAddress, API_ROLE);
    }

    function setAdminRole(address adminAddress) external onlyOwner {
        _grantRoles(adminAddress, ADMIN_ROLE);
    }

    function revokeAdminRole(address adminAddress) external onlyOwner {
        _removeRoles(adminAddress, ADMIN_ROLE);
    }
}
