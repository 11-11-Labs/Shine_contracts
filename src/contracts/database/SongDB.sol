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

import {IdUtils} from "@shine/library/IdUtils.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract SongDB is IdUtils, Ownable {
    error SongDoesNotExist();
    error SongIsBanned();
    error SongCannotBePurchased();
    error UserAlreadyBought();
    error UserHasNotBought();

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

    mapping(uint256 Id => mapping(uint256 userId => bool))
        private isBoughtByUserId;
    mapping(uint256 Id => SongMetadata) private songs;

    modifier onlyIfExist(uint256 id) {
        if (!exists(id)) revert SongDoesNotExist();
        _;
    }

    modifier onlyIfNotBanned(uint256 id) {
        if (songs[id].IsBanned) revert SongIsBanned();
        _;
    }

    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    function register(
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external onlyOwner returns (uint256) {
        uint256 idAssigned = _getNextId();

        songs[idAssigned] = SongMetadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            ArtistIDs: artistIDs,
            MediaURI: mediaURI,
            MetadataURI: metadataURI,
            CanBePurchased: canBePurchased,
            Price: price,
            TimesBought: 0,
            IsBanned: false
        });

        return idAssigned;
    }

    function change(
        uint256 id,
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        songs[id] = SongMetadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            ArtistIDs: artistIDs,
            MediaURI: mediaURI,
            MetadataURI: metadataURI,
            CanBePurchased: canBePurchased,
            Price: price,
            TimesBought: songs[id].TimesBought,
            IsBanned: songs[id].IsBanned
        });
    }

    function purchase(
        uint256 id,
        uint256 userId
    ) external onlyOwner onlyIfExist(id) onlyIfNotBanned(id) {
        if (!songs[id].CanBePurchased) revert SongCannotBePurchased();
        if (isBoughtByUserId[id][userId]) revert UserAlreadyBought();

        isBoughtByUserId[id][userId] = true;
        songs[id].TimesBought++;
    }

    function refund(
        uint256 id,
        uint256 userId
    ) external onlyOwner onlyIfExist(id) returns (bool) {
        if (!isBoughtByUserId[id][userId]) revert UserHasNotBought();

        isBoughtByUserId[id][userId] = false;
        songs[id].TimesBought--;

        return true;
    }

    function changePurchaseability(
        uint256 id,
        bool canBePurchased
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        songs[id].CanBePurchased = canBePurchased;
    }

    function changePrice(
        uint256 id,
        uint256 price
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        songs[id].Price = price;
    }

    function setBannedStatus(
        uint256 id,
        bool isBanned
    ) external onlyOwner onlyIfExist(id) {
        songs[id].IsBanned = isBanned;
    }

    function isBoughtByUser(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }

    function canUserBuy(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }

    function hasUserPurchased(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }

    function getPrice(uint256 id) external view returns (uint256) {
        return songs[id].Price;
    }

    function getPrincipalArtistId(uint256 id) external view returns (uint256) {
        return songs[id].PrincipalArtistId;
    }

    function isPurchasable(uint256 id) external view returns (bool) {
        return songs[id].CanBePurchased;
    }

    function checkIsBanned(uint256 id) external view returns (bool) {
        return songs[id].IsBanned;
    }

    function getMetadata(
        uint256 id
    ) external view returns (SongMetadata memory) {
        return songs[id];
    }
}
