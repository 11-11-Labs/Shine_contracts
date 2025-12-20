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

contract AlbumDB is IdUtils, Ownable {
    struct SongMetadata {
        string title;
        uint256 principalArtistId;
        string metadataURI;
        uint256[] musicIds;
        uint256 price;
        uint256 timesBought;
        bool canBePurchased;
        bool isASpecialEdition;
        string specialEditionName;
        uint256 maxSupplySpecialEdition;
    }

    mapping(uint256 Id => mapping(uint256 userId => bool)) isBoughtByUserId;
    mapping(uint256 Id => SongMetadata) private albums;

    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    function register(
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory musicIds,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external onlyOwner returns (uint256) {
        if (musicIds.length == 0) revert();

        uint256 idAssigned = _getNextId();

        albums[idAssigned] = SongMetadata({
            title: title,
            principalArtistId: principalArtistId,
            metadataURI: metadataURI,
            musicIds: musicIds,
            price: price,
            timesBought: 0,
            canBePurchased: canBePurchased,
            isASpecialEdition: isASpecialEdition,
            specialEditionName: specialEditionName,
            maxSupplySpecialEdition: maxSupplySpecialEdition
        });

        return idAssigned;
    }

    function purchase(
        uint256 id,
        uint256 userId
    ) external onlyOwner returns (uint256[] memory) {
        if (isBoughtByUserId[id][userId]) revert();

        if (!albums[id].canBePurchased) revert();

        isBoughtByUserId[id][userId] = true;
        albums[id].timesBought++;

        return albums[id].musicIds;
    }

    function refund(
        uint256 id,
        uint256 userId
    ) external onlyOwner returns (uint256[] memory, uint256) {
        if (!isBoughtByUserId[id][userId]) revert();

        isBoughtByUserId[id][userId] = false;
        albums[id].timesBought--;

        return (albums[id].musicIds, albums[id].price);
    }

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
    ) external onlyOwner {
        if (musicIds.length == 0) revert();

        albums[id] = SongMetadata({
            title: title,
            principalArtistId: principalArtistId,
            metadataURI: metadataURI,
            musicIds: musicIds,
            price: price,
            timesBought: albums[id].timesBought,
            canBePurchased: canBePurchased,
            isASpecialEdition: isASpecialEdition,
            specialEditionName: specialEditionName,
            maxSupplySpecialEdition: maxSupplySpecialEdition
        });
    }

    function changePurchaseability(
        uint256 id,
        bool canBePurchased
    ) external onlyOwner {
        albums[id].canBePurchased = canBePurchased;
    }

    function changePrice(uint256 id, uint256 price) external onlyOwner {
        albums[id].price = price;
    }

    function getAlbumMetadata(
        uint256 id
    ) external view returns (SongMetadata memory) {
        return albums[id];
    }

    function hasUserPurchasedAlbum(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }
}
