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
    struct SongMetadata {
        string title;
        uint256 principalArtistId;
        uint256[] artistIDs;
        string mediaURI;
        string metadataURI;
        bool canBePurchased;
        uint256 price;
        uint256 timesBought;
    }

    mapping(uint256 Id => mapping(uint256 userId => bool)) isBoughtByUserId;
    mapping(uint256 Id => SongMetadata) private songs;

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
            title: title,
            principalArtistId: principalArtistId,
            artistIDs: artistIDs,
            mediaURI: mediaURI,
            metadataURI: metadataURI,
            canBePurchased: canBePurchased,
            price: price,
            timesBought: 0
        });

        return idAssigned;
    }

    function purchase(
        uint256 id,
        uint256 userId
    ) external onlyOwner returns (bool) {
        if (!songs[id].canBePurchased) revert();
        if (isBoughtByUserId[id][userId]) revert();

        isBoughtByUserId[id][userId] = true;
        songs[id].timesBought++;

        return true;
    }

    function refund(
        uint256 id,
        uint256 userId
    ) external onlyOwner returns (bool) {
        if (!songs[id].canBePurchased) revert();
        if (!isBoughtByUserId[id][userId]) revert();

        isBoughtByUserId[id][userId] = false;
        songs[id].timesBought--;

        return true;
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
    ) external onlyOwner {
        songs[id] = SongMetadata({
            title: title,
            principalArtistId: principalArtistId,
            artistIDs: artistIDs,
            mediaURI: mediaURI,
            metadataURI: metadataURI,
            canBePurchased: canBePurchased,
            price: price,
            timesBought: songs[id].timesBought
        });
    }

    function changePurchaseability(
        uint256 id,
        bool canBePurchased
    ) external onlyOwner {
        songs[id].canBePurchased = canBePurchased;
    }

    function changePrice(uint256 id, uint256 price) external onlyOwner {
        songs[id].price = price;
    }

    function getSongMetadata(
        uint256 id
    ) external view returns (SongMetadata memory) {
        return songs[id];
    }

    function hasUserPurchasedSong(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }
}
