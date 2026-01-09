// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
                                                            
 * @title Shine ISongDB
 * @author 11:11 Labs 
 * @notice This contract manages song metadata, user purchases, 
 *         and admin functionalities for the Shine platform.
 */

import {ISongDB} from "@shine/interface/ISongDB.sol";
import {IAlbumDB} from "@shine/interface/IAlbumDB.sol";
import {IArtistDB} from "@shine/interface/IArtistDB.sol";
import {IUserDB} from "@shine/interface/IUserDB.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract Orchestrator is Ownable {
    struct DataBaseList {
        address album;
        address artist;
        address song;
        address user;
    }

    struct Breakers {
        bytes1 addressSetup;
        bytes1 shop;
    }

    address private newOrchestratorAddress;

    DataBaseList private dbAddress;

    Breakers private breaker;

    uint16 private percentageFee;

    uint256 amountCollectedInFees;

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

    constructor(address initialOwner) {
        _initializeOwner(initialOwner);
    }

    function _setDatabaseAddresses(
        address _dbalbum,
        address _dbartist,
        address _dbsong,
        address _dbuser
    ) external onlyOwner {
        if (breaker.addressSetup != bytes1(0x00)) revert();
        dbAddress.album = _dbalbum;
        dbAddress.artist = _dbartist;
        dbAddress.song = _dbsong;
        dbAddress.user = _dbuser;
        breaker.addressSetup = bytes1(0x01);
    }

    function register(
        bool isArtist,
        string memory name,
        string memory metadataURI,
        address artistAddress
    ) external returns (uint256) {
        if (isArtist) {
            return
                IArtistDB(dbAddress.artist).register(
                    name,
                    metadataURI,
                    artistAddress
                );
        } else {
            return
                IUserDB(dbAddress.user).register(
                    name,
                    metadataURI,
                    artistAddress
                );
        }
    }

    function chnageBasicData(
        bool isArtist,
        uint256 id,
        string memory name,
        string memory metadataURI
    ) external {
        if (isArtist) {
            if (IArtistDB(dbAddress.artist).getAddress(id) != msg.sender)
                revert();
            IArtistDB(dbAddress.artist).changeBasicData(id, name, metadataURI);
        } else {
            if (IUserDB(dbAddress.user).getAddress(id) != msg.sender) revert();
            IUserDB(dbAddress.user).changeBasicData(id, name, metadataURI);
        }
    }

    function changeAddress(
        bool isArtist,
        uint256 id,
        address newAddress
    ) external {
        if (isArtist) {
            if (IArtistDB(dbAddress.artist).getAddress(id) != msg.sender)
                revert();
            IArtistDB(dbAddress.artist).changeAddress(id, newAddress);
        } else {
            if (IUserDB(dbAddress.user).getAddress(id) != msg.sender) revert();
            IUserDB(dbAddress.user).changeAddress(id, newAddress);
        }
    }

    function registerSong(
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external returns (uint256) {
        if (!IArtistDB(dbAddress.artist).exists(principalArtistId)) revert();
        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert();
        if (artistIDs.length > 0) {
            for (uint256 i = 0; i < artistIDs.length; i++) {
                if (!IArtistDB(dbAddress.artist).exists(artistIDs[i])) revert();
            }
        }
        if (bytes(title).length == 0) revert();
        return
            ISongDB(dbAddress.song).register(
                title,
                principalArtistId,
                artistIDs,
                mediaURI,
                metadataURI,
                canBePurchased,
                price
            );
    }

    function changeSongFullData(
        uint256 id,
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external {
        if (!IArtistDB(dbAddress.artist).exists(principalArtistId)) revert();
        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert();

        if (!ISongDB(dbAddress.song).exists(id)) revert();
        if (
            ISongDB(dbAddress.song).getPrincipalArtistId(id) !=
            principalArtistId
        ) revert();
        ISongDB(dbAddress.song).change(
            id,
            title,
            principalArtistId,
            artistIDs,
            mediaURI,
            metadataURI,
            canBePurchased,
            price
        );
    }

    function changeSongPurchaseability(
        uint256 id,
        bool canBePurchased
    ) external {
        uint256 principalArtistId = ISongDB(dbAddress.song)
            .getPrincipalArtistId(id);
        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert();
        ISongDB(dbAddress.song).changePurchaseability(id, canBePurchased);
    }

    function changeSongPrice(uint256 id, uint256 price) external {
        uint256 principalArtistId = ISongDB(dbAddress.song)
            .getPrincipalArtistId(id);
        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert();

        
        ISongDB(dbAddress.song).changePrice(id, price);
    }

    function purchaseSong(uint256 songId) external payable {
        uint256 userID = IUserDB(dbAddress.user).getId(msg.sender);
        if (userID == 0) revert();
        ISongDB(dbAddress.song).purchase(songId, userID);
        _executePayment(
            userID,
            ISongDB(dbAddress.song).getPrincipalArtistId(songId),
            songId
        );

        emit SongPurchased(
            songId,
            userID,
            ISongDB(dbAddress.song).getPrice(songId)
        );
    }

    function registerAlbum(
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory songIDs,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external returns (uint256) {
        if (!IArtistDB(dbAddress.artist).exists(principalArtistId)) revert();
        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert();
        if (bytes(title).length == 0) revert();
        for (uint256 i = 0; i < songIDs.length; i++) {
            if (!ISongDB(dbAddress.song).exists(songIDs[i])) revert();
            if (
                ISongDB(dbAddress.song).getPrincipalArtistId(songIDs[i]) !=
                principalArtistId
            ) revert();
        }
        return
            IAlbumDB(dbAddress.album).register(
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

    function _executePayment(
        uint256 userId,
        uint256 artistId,
        uint256 songId
    ) internal {
        uint256 price = ISongDB(dbAddress.song).getPrice(songId);

        if (price != 0) {

            uint256 userBalance = IUserDB(dbAddress.user).getBalance(userId);
            (uint256 totalPrice, uint256 calculatedFee) = getPriceWithFee(price);
            if (userBalance < totalPrice) revert();

            IUserDB(dbAddress.user).deductBalance(userId, totalPrice);
            IUserDB(dbAddress.user).addBalance(artistId, price);
            amountCollectedInFees += calculatedFee;
        }
    }

    function getPriceWithFee(
        uint256 netPrice
    ) public view returns (uint256 totalPrice, uint256 fee) {
        if (netPrice == 0) return (0, 0);
        fee = (netPrice * uint256(percentageFee)) / 10000;
        return (netPrice + fee, fee);
    }

    function addPercentageFee(uint16 _percentageFee) external onlyOwner {
        /// @dev percentage fee is in basis points (100 = 1%)
        if (_percentageFee > 10000) revert(); // max 100%
        percentageFee = _percentageFee;
    }

    function migrateOrchestrator(
        address orchestratorAddressToMigrate
    ) external onlyOwner {
        if (orchestratorAddressToMigrate == address(0)) revert();
        IAlbumDB(dbAddress.album).transferOwnership(
            orchestratorAddressToMigrate
        );
        IArtistDB(dbAddress.artist).transferOwnership(
            orchestratorAddressToMigrate
        );
        ISongDB(dbAddress.song).transferOwnership(orchestratorAddressToMigrate);
        IUserDB(dbAddress.user).transferOwnership(orchestratorAddressToMigrate);
        newOrchestratorAddress = orchestratorAddressToMigrate;
    }
}
/*
You like snooping around code, don't you?
⠄⠄⢸⠃⠄⠛⠉⠄⣤⣤⣤⣤⣤⣄⠉⠙⠻⣿⣿⣿⣿⡇⣶⡄⢢⢻⣿⣿⣮⡛
⠄⠄⠘⢀⣠⣾⠄⠘⠋⠉⠉⠛⠻⢿⣦⡲⣄⠈⠻⣿⣇⣣⠹⣯⣄⣦⡙⢿⣿⣿
⢀⡎⠄⣾⠋⠄⠄⠄⣠⣤⣤⣤⣤⣄⠈⠙⣍⢳⠄⠘⣿⡐⠁⢉⣁⣀⡀⠄⠙⠿
⡼⠄⡆⡇⢀⣤⡆⣿⣿⣿⣿⣿⣿⣿⣷⡘⣿⣷⣄⡀⢹⡇⣾⣿⣿⣿⣿⡇⣄⢠
⡇⠄⢿⡔⢿⣿⡇⢿⣿⣿⣿⠿⠿⢿⣿⠇⣿⣿⣿⠇⢈⣁⡻⢿⣿⣀⠈⣱⢏⣾
⢣⠄⢆⢩⣮⣿⣿⣄⠻⣿⣷⣤⣤⡴⢋⣴⣿⣿⡟⠄⢸⣿⣿⣷⣶⣶⠾⢫⣪⠅
⠘⣆⠈⢑⣘⣿⣿⣿⣷⣶⣤⣤⣴⣾⣿⣿⣿⣿⠃⢀⣿⣿⣿⣿⣿⣿⣿⣿⢇⣴
⠄⠘⢦⡈⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⢁⣀⣉⣉⣹⣿⣿⣿⣿⠿⡃⠪⣶
⠄⠄⠄⠙⠢⢄⡈⠛⠻⠿⠿⠿⠟⠛⠋⣀⠰⣿⣿⣿⣿⡿⠿⡛⠉⡄⠄⠄⠄⣀
⠄⠄⠄⠄⢀⡾⢉⣁⠄⠄⠄⠲⠂⢂⠋⠄⠛⠒⠉⠉⠑⠒⠉⠒⠒⡧⠤⠖⢋⣡
 */
