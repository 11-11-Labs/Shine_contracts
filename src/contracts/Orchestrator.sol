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
    struct DataBaseList {
        address album;
        address artist;
        address song;
        address user;
    }

    uint256 constant ADMIN_ROLE = 1;
    uint256 constant API_ROLE = 2;

    DataBaseList private dbAddress;

    bytes16 breakerAddressSetup;
    bytes16 breakerShop;

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

    function _setDatabaseAddresses(
        address _dbalbum,
        address _dbartist,
        address _dbsong,
        address _dbuser
    ) external onlyOwner {
        if (breakerAddressSetup != bytes16(0)) revert();
        dbAddress.album = _dbalbum;
        dbAddress.artist = _dbartist;
        dbAddress.song = _dbsong;
        dbAddress.user = _dbuser;
        breakerAddressSetup = bytes16(hex"00000000000000000000000000000001");
    }

    function registerArtist(
        string memory name,
        string memory metadataURI,
        address artistAddress
    ) external onlyRoles(API_ROLE) returns (uint256 id) {
        id = ArtistDB(dbAddress.artist).register(name, metadataURI, artistAddress);
    }

    function chnageDataOfArtist(
        uint256 artistId,
        string memory name,
        string memory metadataURI,
        address artistAddress
    ) external onlyRoles(API_ROLE) {
        if (!ArtistDB(dbAddress.artist).exists(artistId)) revert();
        ArtistDB(dbAddress.artist).changeBasicData(artistId, name, metadataURI);

        if (ArtistDB(dbAddress.artist).getAddress(artistId) != artistAddress) {
            ArtistDB(dbAddress.artist).changeAddress(artistId, artistAddress);
        }
    }

    function registerUser(
        string memory username,
        string memory metadataURI,
        address userAddress
    ) external onlyRoles(API_ROLE) returns (uint256) {
        return UserDB(dbAddress.user).register(username, metadataURI, userAddress);
    }

    function changeDataOfUser(
        uint256 userId,
        string memory username,
        string memory metadataURI,
        address userAddress
    ) external onlyRoles(API_ROLE) {
        if (!UserDB(dbAddress.user).exists(userId)) revert();
        UserDB(dbAddress.user).changeBasicData(userId, username, metadataURI);

        if (UserDB(dbAddress.user).getAddress(userId) != userAddress) {
            UserDB(dbAddress.user).changeAddress(userId, userAddress);
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
        if (!ArtistDB(dbAddress.artist).exists(artistId)) revert();

        return
            SongDB(dbAddress.song).register(
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
        if (!SongDB(dbAddress.song).exists(songId)) revert();
        if (
            SongDB(dbAddress.song).getPrincipalArtistId(songId) !=
            principalArtistId
        ) revert();

        SongDB(dbAddress.song).change(
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
        if (!SongDB(dbAddress.song).exists(songId)) revert();

        SongDB(dbAddress.song).changePurchaseability(songId, canBePurchased);
        SongDB(dbAddress.song).changePrice(songId, price);
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
        if (!ArtistDB(dbAddress.artist).exists(artistId)) revert();
        for (uint256 i = 0; i < songIDs.length; i++) {
            if (!SongDB(dbAddress.song).exists(songIDs[i])) revert();
        }

        return
            AlbumDB(dbAddress.album).register(
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
        if (!AlbumDB(dbAddress.album).exists(albumId)) revert();

        if (
            AlbumDB(dbAddress.artist).getPrincipalArtistId(principalArtistId) !=
            principalArtistId
        ) revert();

        for (uint256 i = 0; i < songIDs.length; i++) {
            if (!SongDB(dbAddress.song).exists(songIDs[i])) revert();
        }

        AlbumDB(dbAddress.album).change(
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
        if (!AlbumDB(dbAddress.album).exists(albumId)) revert();

        AlbumDB(dbAddress.album).changePurchaseability(albumId, canBePurchased);
        AlbumDB(dbAddress.album).changePrice(albumId, price);
    }

    function buySong(
        uint256 songId,
        uint256 userId
    ) external onlyRoles(API_ROLE) {
        if (!SongDB(dbAddress.song).exists(songId)) revert();
        if (!UserDB(dbAddress.user).exists(userId)) revert();
        if (!SongDB(dbAddress.album).hasUserPurchased(songId, userId)) revert();
        if (SongDB(dbAddress.song).canUserBuy(songId, userId)) revert();

        uint256 price = SongDB(dbAddress.song).getPrice(songId);
        if (UserDB(dbAddress.user).getBalance(userId) < price) revert();

        uint256 principalArtistId = SongDB(dbAddress.song).getPrincipalArtistId(
            songId
        );

        UserDB(dbAddress.user).deductBalance(userId, price);
        ArtistDB(dbAddress.artist).addBalance(principalArtistId, price);
        SongDB(dbAddress.song).purchase(songId, userId);
        UserDB(dbAddress.user).addSong(userId, songId);

        emit SongPurchased(songId, userId, price);
    }

    function buyAlbum(
        uint256 albumId,
        uint256 userId
    ) external onlyRoles(API_ROLE) {
        if (!AlbumDB(dbAddress.album).exists(albumId)) revert();
        if (!UserDB(dbAddress.user).exists(userId)) revert();
        if (AlbumDB(dbAddress.album).hasUserPurchased(albumId, userId)) revert();
        if (AlbumDB(dbAddress.album).canUserBuy(albumId, userId)) revert();

        uint256 price = AlbumDB(dbAddress.album).getPrice(albumId);
        if (UserDB(dbAddress.user).getBalance(userId) < price) revert();

        uint256 principalArtistId = AlbumDB(dbAddress.album).getPrincipalArtistId(
            albumId
        );

        UserDB(dbAddress.user).deductBalance(userId, price);
        ArtistDB(dbAddress.artist).addBalance(principalArtistId, price);
        uint256[] memory songIds = AlbumDB(dbAddress.album).purchase(albumId, userId);

        UserDB(dbAddress.user).addSongs(userId, songIds);

        emit AlbumPurchased(albumId, userId, price);
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

    function migrateOrchestrator(
        address newOrchestratorAddress
    ) external onlyOwner {
        if (newOrchestratorAddress == address(0)) revert();
        AlbumDB(dbAddress.album).transferOwnership(newOrchestratorAddress);
        ArtistDB(dbAddress.artist).transferOwnership(newOrchestratorAddress);
        SongDB(dbAddress.song).transferOwnership(newOrchestratorAddress);
        UserDB(dbAddress.user).transferOwnership(newOrchestratorAddress);
    }
}
