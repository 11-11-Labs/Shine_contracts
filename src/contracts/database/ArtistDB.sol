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
        address payable artistAddress;
        uint256 totalEarnings;
        uint256 accumulatedRoyalties;
    }

    mapping(uint256 Id => Artist) private artists;

    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    function register(
        string memory name,
        string memory metadataURI,
        address payable artistAddress
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

    function change(
        uint256 id,
        string memory name,
        string memory metadataURI,
        address payable artistAddress
    ) external onlyOwner {
        artists[id] = Artist({
            name: name,
            metadataURI: metadataURI,
            artistAddress: artistAddress,
            totalEarnings: artists[id].totalEarnings,
            accumulatedRoyalties: artists[id].accumulatedRoyalties
        });
    }

    function getArtist(uint256 id) external view returns (Artist memory) {
        return artists[id];
    }

    function hasArtist(uint256 id) external view returns (bool) {
        return bytes(artists[id].name).length != 0;
    }

    function getArtistAddress(
        uint256 id
    ) external view returns (address payable) {
        return artists[id].artistAddress;
    }
}
