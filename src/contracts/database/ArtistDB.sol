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
    struct Artist {
        string name;
        string metadataURI;
        address artistAddress;
        uint256 totalEarnings;
        uint256 accumulatedRoyalties;
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
        uint256 idAssigned = _getNextId();

        artists[idAssigned] = Artist({
            name: name,
            metadataURI: metadataURI,
            artistAddress: artistAddress,
            totalEarnings: 0,
            accumulatedRoyalties: 0
        });

        return idAssigned;
    }

    function changeBasicData(
        uint256 id,
        string memory name,
        string memory metadataURI
    ) external onlyOwner {
        if (bytes(artists[id].name).length == 0) {
            revert();
        }

        artists[id].name = name;
        artists[id].metadataURI = metadataURI;
    }

    function changeArtistAddress(
        uint256 id,
        address newArtistAddress
    ) external onlyOwner {
        if (bytes(artists[id].name).length == 0) {
            revert();
        }

        addressArtist[artists[id].artistAddress] = 0;
        artists[id].artistAddress = newArtistAddress;
        addressArtist[newArtistAddress] = id;
    }

    function addEarnings(uint256 artistId, uint256 amount) external onlyOwner {
        artists[artistId].totalEarnings += amount;
    }

    function deductEarnings(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner {
        artists[artistId].totalEarnings -= amount;
    }

    function addAccumulatedRoyalties(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner {
        artists[artistId].accumulatedRoyalties += amount;
    }

    function deductAccumulatedRoyalties(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner {
        artists[artistId].accumulatedRoyalties -= amount;
    }

    function getArtist(uint256 id) external view returns (Artist memory) {
        return artists[id];
    }

    function exists(uint256 id) external view returns (bool) {
        return
            bytes(artists[id].name).length != 0 &&
            artists[id].artistAddress != address(0);
    }

    function getArtistAddress(uint256 id) external view returns (address) {
        return artists[id].artistAddress;
    }

    function getArtistId(
        address artistAddress
    ) external view returns (uint256) {
        return addressArtist[artistAddress];
    }
}
