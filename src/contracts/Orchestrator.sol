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

import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {ArtistDB} from "@shine/contracts/database/ArtistDB.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";
import {OwnableRoles} from "@solady/auth/OwnableRoles.sol";

contract Orchestrator is OwnableRoles {
    uint256 constant ADMIN_ROLE = 1;
    uint256 constant API_ROLE = 2;

    constructor(
        address initialOwner,
        address initialAdminAddress,
        address initialAPIAddress
    ) {
        _initializeOwner(initialOwner);
        _grantRoles(initialAdminAddress, ADMIN_ROLE);
        _grantRoles(initialAPIAddress, API_ROLE);
    }

    


    function setAPIRole(address apiAddress) external onlyOwner {
        _grantRoles(apiAddress, API_ROLE);
    }

    function setApiRole(address apiAddress) external onlyOwner {
        _grantRoles(apiAddress, API_ROLE);
    }

    function revokeApiRole(address apiAddress) external onlyOwner {
        _removeRoles(apiAddress, API_ROLE);
    }

    function revokeAPIRole(address apiAddress) external onlyOwner {
        _removeRoles(apiAddress, API_ROLE);
    }

}