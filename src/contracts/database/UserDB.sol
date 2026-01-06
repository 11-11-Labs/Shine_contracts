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
    error UserIsBanned();
    error UserDoesNotExist();
    error UsernameIsEmpty();
    error UserAddressIsEmpty();

    struct User {
        string Username;
        string MetadataURI;
        address UserAddress;
        uint256[] PurchasedSongIds;
        uint256 Balance;
        bool IsBanned;
    }

    mapping(address userAddress => uint256 id) private addressUser;
    mapping(uint256 Id => User) private users;

    modifier onlyIfExist(uint256 id) {
        if (!exists(id)) revert UserDoesNotExist();
        _;
    }

    modifier onlyIfNotBanned(uint256 id) {
        if (users[id].IsBanned) revert UserIsBanned();
        _;
    }

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
            Username: username,
            MetadataURI: metadataURI,
            UserAddress: userAddress,
            PurchasedSongIds: new uint256[](0),
            Balance: 0,
            IsBanned: false
        });

        addressUser[userAddress] = idAssigned;

        return idAssigned;
    }

    function changeBasicData(
        uint256 id,
        string memory username,
        string memory metadataURI
    ) external onlyOwner onlyIfExist(id) onlyIfNotBanned(id) {
        if (bytes(username).length == 0) revert UsernameIsEmpty();

        users[id].Username = username;
        users[id].MetadataURI = metadataURI;
    }

    function changeAddress(
        uint256 id,
        address newUserAddress
    ) external onlyOwner onlyIfExist(id) onlyIfNotBanned(id) {
        if (newUserAddress == address(0)) revert UserAddressIsEmpty();

        addressUser[users[id].UserAddress] = 0;
        users[id].UserAddress = newUserAddress;
        addressUser[newUserAddress] = id;
    }

    function addSong(
        uint256 userId,
        uint256 songId
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        users[userId].PurchasedSongIds.push(songId);
    }

    function deleteSong(
        uint256 userId,
        uint256 songId
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        uint256[] storage songIds = users[userId].PurchasedSongIds;
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
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        uint256 len = songIds.length;
        for (uint256 i; i < len; ) {
            users[userId].PurchasedSongIds.push(songIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function deleteSongs(
        uint256 userId,
        uint256[] calldata songIdsToDelete
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        uint256[] storage songIds = users[userId].PurchasedSongIds;
        uint256 len = songIds.length;
        uint256 deleteLen = songIdsToDelete.length;

        uint256 writeIndex;

        for (uint256 i; i < len; ) {
            bool shouldDelete;

            // Verificar si el songId actual está en la lista de eliminación
            for (uint256 j; j < deleteLen; ) {
                if (songIds[i] == songIdsToDelete[j]) {
                    shouldDelete = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }

            // Si no se debe eliminar, mantenerlo
            if (!shouldDelete) {
                if (writeIndex != i) {
                    songIds[writeIndex] = songIds[i];
                }
                unchecked {
                    ++writeIndex;
                }
            }

            unchecked {
                ++i;
            }
        }

        // Remover los elementos sobrantes al final
        while (songIds.length > writeIndex) {
            songIds.pop();
        }
    }

    function addBalance(
        uint256 userId,
        uint256 amount
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        users[userId].Balance += amount;
    }

    function deductBalance(
        uint256 userId,
        uint256 amount
    ) external onlyOwner onlyIfExist(userId) onlyIfNotBanned(userId) {
        users[userId].Balance -= amount;
    }

    function getMetadata(uint256 id) external view returns (User memory) {
        return users[id];
    }

    function getPurchasedSong(
        uint256 userId
    ) external view returns (uint256[] memory) {
        return users[userId].PurchasedSongIds;
    }

    function getAddress(uint256 id) external view returns (address) {
        return users[id].UserAddress;
    }

    function getId(address userAddress) external view returns (uint256) {
        return addressUser[userAddress];
    }

    function getBalance(uint256 userId) external view returns (uint256) {
        return users[userId].Balance;
    }
}
