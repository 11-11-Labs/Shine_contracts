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

contract UserDB is IdUtils, Ownable {
    struct User {
        string username;
        string metadataURI;
        address payable userAddress;
        uint256[] purchasedSongIds;
    }

    mapping(uint256 Id => User) private users;

    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    function register(
        string memory username,
        string memory metadataURI,
        address payable userAddress
    ) external onlyOwner returns (uint256) {
        uint256 idAssigned = _getNextId();

        users[idAssigned] = User({
            username: username,
            metadataURI: metadataURI,
            userAddress: userAddress,
            purchasedSongIds: new uint256[](0)
        });

        return idAssigned;
    }

    function change(
        uint256 id,
        string memory username,
        string memory metadataURI,
        address payable userAddress
    ) external onlyOwner {
        users[id] = User({
            username: username,
            metadataURI: metadataURI,
            userAddress: userAddress,
            purchasedSongIds: users[id].purchasedSongIds
        });
    }

    function addSongIdToUser(
        uint256 userId,
        uint256 songId
    ) external onlyOwner {
        users[userId].purchasedSongIds.push(songId);
    }

    function deleteSongIdFromUser(
        uint256 userId,
        uint256 songId
    ) external onlyOwner {
        uint256[] storage songIds = users[userId].purchasedSongIds;
        for (uint256 i = 0; i < songIds.length; i++) {
            if (songIds[i] == songId) {
                songIds[i] = songIds[songIds.length - 1];
                songIds.pop();
                break;
            }
        }
    }

    function getUser(
        uint256 id
    ) external view returns (User memory) {
        return users[id];
    }

    function getPurchasedSongIds(
        uint256 userId
    ) external view returns (uint256[] memory) {
        return users[userId].purchasedSongIds;
    }

    function hasUser(uint256 id) external view returns (bool) {
        return bytes(users[id].username).length != 0;
    }

    function getUserAddress(
        uint256 id
    ) external view returns (address payable) {
        return users[id].userAddress;
    }
    
}
