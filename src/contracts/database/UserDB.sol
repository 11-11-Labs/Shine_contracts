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
        address userAddress;
        uint256[] purchasedSongIds;
        uint256 balance;
    }

    mapping(address userAddress => uint256 id) private addressUser;
    mapping(uint256 Id => User) private users;

    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    function register(
        string memory username,
        string memory metadataURI,
        address userAddress
    ) external onlyOwner returns (uint256) {
        uint256 idAssigned = _getNextId();

        users[idAssigned] = User({
            username: username,
            metadataURI: metadataURI,
            userAddress: userAddress,
            purchasedSongIds: new uint256[](0),
            balance: 0
        });

        addressUser[userAddress] = idAssigned;

        return idAssigned;
    }

    function changeBasicData(
        uint256 id,
        string memory username,
        string memory metadataURI
    ) external onlyOwner {
        if (bytes(users[id].username).length == 0) {
            revert();
        }
        users[id].username = username;
        users[id].metadataURI = metadataURI;
    }

    function changeAddress(
        uint256 id,
        address newUserAddress
    ) external onlyOwner {
        if (bytes(users[id].username).length == 0) {
            revert();
        }

        addressUser[users[id].userAddress] = 0;
        users[id].userAddress = newUserAddress;
        addressUser[newUserAddress] = id;
    }

    function addSong(uint256 userId, uint256 songId) external onlyOwner {
        users[userId].purchasedSongIds.push(songId);
    }

    function deleteSong(uint256 userId, uint256 songId) external onlyOwner {
        uint256[] storage songIds = users[userId].purchasedSongIds;
        uint256 len = songIds.length;

        for (uint256 i; i < len; ) {
            if (songIds[i] == songId) {
                for (uint256 j = i; j < len - 1; ) {
                    songIds[j] = songIds[j + 1];
                    unchecked {
                        ++j;
                    }
                }
                songIds.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function addSongs(
        uint256 userId,
        uint256[] calldata songIds
    ) external onlyOwner {
        uint256 len = songIds.length;
        for (uint256 i; i < len; ) {
            users[userId].purchasedSongIds.push(songIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function deleteSongs(
        uint256 userId,
        uint256[] calldata songIdsToDelete
    ) external onlyOwner {
        uint256[] storage arr = users[userId].purchasedSongIds;
        uint256 len = arr.length;
        uint256 dlen = songIdsToDelete.length;

        // primera pasada: contar conservados
        uint256 keepCount;
        for (uint256 i; i < len; ) {
            bool shouldDelete;
            for (uint256 j; j < dlen; ) {
                if (arr[i] == songIdsToDelete[j]) {
                    shouldDelete = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (!shouldDelete) ++keepCount;
            unchecked {
                ++i;
            }
        }

        // crear array en memoria con tamaño exacto
        uint256[] memory kept = new uint256[](keepCount);
        uint256 idx;
        for (uint256 i; i < len; ) {
            bool shouldDelete;
            for (uint256 j; j < dlen; ) {
                if (arr[i] == songIdsToDelete[j]) {
                    shouldDelete = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (!shouldDelete) {
                kept[idx++] = arr[i];
            }
            unchecked {
                ++i;
            }
        }

        // reasignar (copia memoria -> storage en una sola asignación)
        users[userId].purchasedSongIds = kept;
    }

    function addBalance(uint256 userId, uint256 amount) external onlyOwner {
        users[userId].balance += amount;
    }

    function deductBalance(uint256 userId, uint256 amount) external onlyOwner {
        users[userId].balance -= amount;
    }

    function getMetadata(uint256 id) external view returns (User memory) {
        return users[id];
    }

    function getPurchasedSong(
        uint256 userId
    ) external view returns (uint256[] memory) {
        return users[userId].purchasedSongIds;
    }

    function exists(uint256 id) external view returns (bool) {
        return
            bytes(users[id].username).length != 0 &&
            users[id].userAddress != address(0);
    }

    function getAddress(uint256 id) external view returns (address) {
        return users[id].userAddress;
    }

    function getId(address userAddress) external view returns (uint256) {
        return addressUser[userAddress];
    }

    function getBalance(uint256 userId) external view returns (uint256) {
        return users[userId].balance;
    }
}
