// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
 * @title Shine EventsLib
 * @author 11:11 Labs 
 * @notice Library containing all event definitions for the Orchestrator contract.
 *         These events track important state changes including purchases, gifts, and donations
 *         to enable off-chain indexing and monitoring of platform activity.
 * @dev Emitted by the Orchestrator when processing transactions involving songs, albums, and artists.
 */

library EventsLib {
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Song Events 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    
    /// @notice Emitted when a user successfully purchases a song
    /// @param songId The ID of the purchased song
    /// @param userId The ID of the user who purchased the song
    /// @param price The net price paid for the song (before fees)
    event SongPurchased(
        uint256 indexed songId,
        uint256 indexed userId,
        uint256 price
    );

    /// @notice Emitted when a song is gifted to a user (no payment required)
    /// @param songId The ID of the gifted song
    /// @param toUserId The ID of the user receiving the gift
    event SongGifted(
        uint256 indexed songId,
        uint256 indexed toUserId
    );

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Album Events 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    
    /// @notice Emitted when a user successfully purchases an album
    /// @param albumId The ID of the purchased album
    /// @param userId The ID of the user who purchased the album
    /// @param price The net price paid for the album (before fees)
    event AlbumPurchased(
        uint256 indexed albumId,
        uint256 indexed userId,
        uint256 price
    );

    /// @notice Emitted when an album is gifted to a user (no payment required)
    /// @param albumId The ID of the gifted album
    /// @param toUserId The ID of the user receiving the gift
    event AlbumGifted(
        uint256 indexed albumId,
        uint256 indexed toUserId
    );

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Artist Support Events 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    
    /// @notice Emitted when a user makes a direct donation to an artist
    /// @param userId The ID of the user making the donation
    /// @param artistId The ID of the artist receiving the donation
    /// @param amount The donation amount in stablecoin units
    event DonationMade(
        uint256 indexed userId,
        uint256 indexed artistId,
        uint256 amount
    );
}