// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
                                                            
 * @title Shine ArtistDB Contract
 * @author 11:11 Labs 
 * @notice This contract manages artist registrations and their associated data.
 */

import {IdUtils} from "@shine/library/IdUtils.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract ArtistDB is IdUtils, Ownable {
    error ArtistIsBanned();
    error NameShouldNotBeEmpty();
    error ArtistIdDoesNotExist();

    struct Artist {
        string Name;
        string MetadataURI;
        address Address;
        uint256 Balance;
        uint256 AccumulatedRoyalties;
        bool isBanned;
    }

    mapping(address artistAddress => uint256 id) private addressArtist;
    mapping(uint256 id => Artist) private artists;

    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    function register(
        string memory name,
        string memory metadataURI,
        address artistAddress
    ) external onlyOwner returns (uint256) {
        if (bytes(name).length == 0) revert NameShouldNotBeEmpty();
        uint256 idAssigned = _getNextId();

        artists[idAssigned] = Artist({
            Name: name,
            MetadataURI: metadataURI,
            Address: artistAddress,
            Balance: 0,
            AccumulatedRoyalties: 0,
            isBanned: false
        });

        return idAssigned;
    }

    function changeBasicData(
        uint256 id,
        string memory name,
        string memory metadataURI
    ) external onlyOwner {
        if (bytes(name).length == 0) revert NameShouldNotBeEmpty();
        if (bytes(artists[id].Name).length == 0) revert ArtistIdDoesNotExist();
        if (artists[id].isBanned) revert ArtistIsBanned();

        artists[id].Name = name;
        artists[id].MetadataURI = metadataURI;
    }

    function changeAddress(
        uint256 id,
        address newArtistAddress
    ) external onlyOwner {
        if (bytes(artists[id].Name).length == 0) revert ArtistIdDoesNotExist();
        if (artists[id].isBanned) revert ArtistIsBanned();

        addressArtist[artists[id].Address] = 0;
        artists[id].Address = newArtistAddress;
        addressArtist[newArtistAddress] = id;
    }

    function addBalance(uint256 artistId, uint256 amount) external onlyOwner {
        artists[artistId].Balance += amount;
    }

    function deductBalance(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner {
        artists[artistId].Balance -= amount;
    }

    function addAccumulatedRoyalties(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner {
        artists[artistId].AccumulatedRoyalties += amount;
    }

    function deductAccumulatedRoyalties(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner {
        artists[artistId].AccumulatedRoyalties -= amount;
    }

    function setBannedStatus(uint256 artistId, bool action) external onlyOwner {
        artists[artistId].isBanned = action;
    }

    function getMetadata(uint256 id) external view returns (Artist memory) {
        return artists[id];
    }

    function exists(uint256 id) external view returns (bool) {
        return
            bytes(artists[id].Name).length != 0 &&
            artists[id].Address != address(0);
    }

    function getAddress(uint256 id) external view returns (address) {
        return artists[id].Address;
    }

    function getId(address artistAddress) external view returns (uint256) {
        return addressArtist[artistAddress];
    }

    function getBalance(uint256 artistId) external view returns (uint256) {
        return artists[artistId].Balance;
    }
}
