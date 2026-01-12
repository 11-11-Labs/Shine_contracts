// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
                                                            
 * @title Shine ISongDB
 * @author 11:11 Labs 
 * @notice This contract manages song metadata, user purchases, 
 *         and admin functionalities for the Shine platform.
 */

library EventsLib {
    event SongPurchased(
        uint256 indexed songId,
        uint256 indexed userId,
        uint256 price
    );

    event AlbumPurchased(
        uint256 indexed albumId,
        uint256 indexed userId,
        uint256 price
    );
}