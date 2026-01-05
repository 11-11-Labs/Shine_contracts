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
    error UserBoughtAlbum();
    error AlbumNotPurchasable();
    error AlbumNotSpecialEdition();
    error AlbumMaxSupplyReached();
    error UserNotBoughtAlbum();
    error AlbumCannotHaveZeroSongs();

    struct SongMetadata {
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
        uint256[] memory songIDs,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external onlyOwner returns (uint256) {
        uint256 idAssigned = _getNextId();

        albums[idAssigned] = SongMetadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            MetadataURI: metadataURI,
            MusicIds: songIDs,
            Price: price,
            TimesBought: 0,
            CanBePurchased: canBePurchased,
            IsASpecialEdition: isASpecialEdition,
            SpecialEditionName: specialEditionName,
            MaxSupplySpecialEdition: maxSupplySpecialEdition
        });

        return idAssigned;
    }

    function purchase(
        uint256 id,
        uint256 userId
    ) external onlyOwner returns (uint256[] memory) {
        if (isBoughtByUserId[id][userId]) revert UserBoughtAlbum();

        if (!albums[id].CanBePurchased) revert AlbumNotPurchasable();

        isBoughtByUserId[id][userId] = true;
        albums[id].TimesBought++;

        return albums[id].MusicIds;
    }

    function purchaseSpecialEdition(
        uint256 id,
        uint256 userId
    ) external onlyOwner returns (uint256[] memory) {
        if (isBoughtByUserId[id][userId]) revert UserBoughtAlbum();

        if (!albums[id].CanBePurchased) revert AlbumNotPurchasable();

        if (!albums[id].IsASpecialEdition) revert AlbumNotSpecialEdition();

        if (albums[id].TimesBought >= albums[id].MaxSupplySpecialEdition)
            revert AlbumMaxSupplyReached();

        isBoughtByUserId[id][userId] = true;
        albums[id].TimesBought++;
        return albums[id].MusicIds;
    }

    function refund(
        uint256 id,
        uint256 userId
    ) external onlyOwner returns (uint256[] memory, uint256) {
        if (!isBoughtByUserId[id][userId]) revert UserNotBoughtAlbum();

        isBoughtByUserId[id][userId] = false;
        albums[id].TimesBought--;

        return (albums[id].MusicIds, albums[id].Price);
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
        if (musicIds.length == 0) revert AlbumCannotHaveZeroSongs();

        albums[id] = SongMetadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            MetadataURI: metadataURI,
            MusicIds: musicIds,
            Price: price,
            TimesBought: albums[id].TimesBought,
            CanBePurchased: canBePurchased,
            IsASpecialEdition: isASpecialEdition,
            SpecialEditionName: specialEditionName,
            MaxSupplySpecialEdition: maxSupplySpecialEdition
        });
    }

    function changePurchaseability(
        uint256 id,
        bool canBePurchased
    ) external onlyOwner {
        albums[id].CanBePurchased = canBePurchased;
    }

    function changePrice(uint256 id, uint256 price) external onlyOwner {
        albums[id].Price = price;
    }

    function exists(uint256 id) external view returns (bool) {
        return bytes(albums[id].Title).length != 0;
    }

    function canUserBuy(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }

    function getPrice(uint256 id) external view returns (uint256) {
        return albums[id].Price;
    }

    function isPurschaseable(uint256 id) external view returns (bool) {
        return albums[id].CanBePurchased;
    }

    function hasUserPurchased(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }

    function getPrincipalArtistId(uint256 id) external view returns (uint256) {
        return albums[id].PrincipalArtistId;
    }

    function getMetadata(
        uint256 id
    ) external view returns (SongMetadata memory) {
        return albums[id];
    }
}
