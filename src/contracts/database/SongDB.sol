// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
 * @title Shine SongDB
 * @author 11:11 Labs 
 * @notice This contract serves as a database for storing and managing song metadata,
 *         including song information, purchases, and administrative controls
 *         for the Shine music platform.
 * @dev Inherits from IdUtils for unique ID generation and Ownable for access control.
 *      Only the Orchestrator contract (owner) can modify state.
 */

import {IdUtils} from "@shine/library/IdUtils.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract SongDB is IdUtils, Ownable {
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /// @dev Thrown when attempting to access a song that does not exist
    error SongDoesNotExist();
    /// @dev Thrown when attempting to interact with a banned song
    error SongIsBanned();
    /// @dev Thrown when attempting to purchase a song that is not available for sale
    error SongCannotBePurchased();
    /// @dev Thrown when a user tries to purchase a song they already own
    error UserAlreadyBought();
    /// @dev Thrown when trying to refund a song the user has not purchased
    error UserHasNotBought();

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Structs 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Stores all metadata associated with a song
     * @dev Used to track song information, artists, pricing, and purchase status
     * @param Title The display name of the song
     * @param PrincipalArtistId The unique identifier of the main artist
     * @param ArtistIDs Array of all artist IDs involved in the song
     * @param MediaURI URI pointing to the song media file (e.g., IPFS)
     * @param MetadataURI URI pointing to off-chain metadata (e.g., IPFS)
     * @param CanBePurchased Flag indicating if the song is available for sale
     * @param Price The net purchase price for this song (in wei or token units). 
     *              Does not include platform fees or taxes.
     * @param TimesBought Counter tracking total number of purchases
     * @param IsBanned Flag indicating if the song has been banned from the platform
     */
    struct SongMetadata {
        string Title;
        uint256 PrincipalArtistId;
        uint256[] ArtistIDs;
        string MediaURI;
        string MetadataURI;
        bool CanBePurchased;
        uint256 Price;
        uint256 TimesBought;
        bool IsBanned;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Mappings 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /// @notice Tracks whether a user has purchased a specific song
    /// @dev Mapping: songId => userId => hasPurchased
    mapping(uint256 Id => mapping(uint256 userId => bool))
        private isBoughtByUserId;

    /// @notice Stores all song metadata indexed by song ID
    /// @dev Private mapping to prevent direct external access
    mapping(uint256 Id => SongMetadata) private songs;

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Modifiers 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Ensures the song exists before executing the function
     * @dev Reverts with SongDoesNotExist if the song ID is not registered
     * @param id The song ID to validate
     */
    modifier onlyIfExist(uint256 id) {
        if (!exists(id)) revert SongDoesNotExist();
        _;
    }

    /**
     * @notice Ensures the song is not banned before executing the function
     * @dev Reverts with SongIsBanned if the song has been banned
     * @param id The song ID to validate
     */
    modifier onlyIfNotBanned(uint256 id) {
        if (songs[id].IsBanned) revert SongIsBanned();
        _;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Constructor 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Initializes the SongDB contract
     * @dev Sets the Orchestrator contract as the owner for access control
     * @param _orchestratorAddress Address of the Orchestrator contract that will manage 
     *                             this database
     */
    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Registration 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Registers a new song in the database
     * @dev Only callable by the Orchestrator (owner). Assigns a unique ID automatically.
     * @param title The display name of the song
     * @param principalArtistId The unique ID of the main artist
     * @param artistIDs Array of all artist IDs involved in the song
     * @param mediaURI URI pointing to the song media file
     * @param metadataURI URI pointing to off-chain metadata
     * @param canBePurchased Whether the song is available for purchase
     * @param price The net purchase price for this song. 
     *              Additional fees and taxes may apply separately.
     * @return The newly assigned song ID
     */
    function register(
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external onlyOwner returns (uint256) {
        uint256 idAssigned = _getNextId();

        songs[idAssigned] = SongMetadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            ArtistIDs: artistIDs,
            MediaURI: mediaURI,
            MetadataURI: metadataURI,
            CanBePurchased: canBePurchased,
            Price: price,
            TimesBought: 0,
            IsBanned: false
        });

        return idAssigned;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Purchases 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Processes a song purchase for a user
     * @dev Only callable by owner. Reverts if user already owns it or song is not 
     *      purchasable/banned.
     * @param id The song ID to purchase
     * @param userId The unique identifier of the purchasing user
     */
    function purchase(
        uint256 id,
        uint256 userId
    ) external onlyOwner onlyIfExist(id) onlyIfNotBanned(id) {
        if (!songs[id].CanBePurchased) revert SongCannotBePurchased();
        if (isBoughtByUserId[id][userId]) revert UserAlreadyBought();

        isBoughtByUserId[id][userId] = true;
        songs[id].TimesBought++;
    }

    /**
     * @notice Processes a refund for a previously purchased song
     * @dev Only callable by owner. Reverts if user hasn't purchased the song.
     * @param id The song ID to refund
     * @param userId The unique identifier of the user requesting refund
     * @return True on successful refund
     */
    function refund(
        uint256 id,
        uint256 userId
    ) external onlyOwner onlyIfExist(id) returns (bool) {
        if (!isBoughtByUserId[id][userId]) revert UserHasNotBought();

        isBoughtByUserId[id][userId] = false;
        songs[id].TimesBought--;

        return true;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Metadata Changes 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Updates all metadata fields for an existing song
     * @dev Only callable by owner. Preserves TimesBought and IsBanned status.
     * @param id The song ID to update
     * @param title New display name for the song
     * @param principalArtistId New principal artist ID
     * @param artistIDs New array of artist IDs
     * @param mediaURI New URI for the song media file
     * @param metadataURI New URI for off-chain metadata
     * @param canBePurchased New purchasability status
     * @param price New net purchase price. Additional fees and taxes may apply separately.
     */
    function change(
        uint256 id,
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        songs[id] = SongMetadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            ArtistIDs: artistIDs,
            MediaURI: mediaURI,
            MetadataURI: metadataURI,
            CanBePurchased: canBePurchased,
            Price: price,
            TimesBought: songs[id].TimesBought,
            IsBanned: songs[id].IsBanned
        });
    }

    /**
     * @notice Updates the purchasability status of a song
     * @dev Only callable by owner. Cannot modify banned songs.
     * @param id The song ID to update
     * @param canBePurchased New purchasability status (true = available for sale)
     */
    function changePurchaseability(
        uint256 id,
        bool canBePurchased
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        songs[id].CanBePurchased = canBePurchased;
    }

    /**
     * @notice Updates the net price of a song
     * @dev Only callable by owner. Cannot modify banned songs. 
     *      This is the net price; fees and taxes are separate.
     * @param id The song ID to update
     * @param price New net purchase price for the song
     */
    function changePrice(
        uint256 id,
        uint256 price
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        songs[id].Price = price;
    }

    /**
     * @notice Sets the banned status of a song
     * @dev Only callable by owner. Banned songs cannot be purchased or modified.
     * @param id The song ID to update
     * @param isBanned New banned status (true = banned from platform)
     */
    function setBannedStatus(
        uint256 id,
        bool isBanned
    ) external onlyOwner onlyIfExist(id) {
        songs[id].IsBanned = isBanned;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 View Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Checks if a user has purchased a specific song
     * @param id The song ID to check
     * @param userId The user ID to check
     * @return True if the user has purchased the song, false otherwise
     */
    function isBoughtByUser(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }

    /**
     * @notice Checks if a user has already purchased a song
     * @param id The song ID to check
     * @param userId The user ID to check
     * @return True if the user has purchased the song, false otherwise
     */
    function canUserBuy(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }

    /**
     * @notice Checks if a user has purchased a specific song
     * @param id The song ID to check
     * @param userId The user ID to check
     * @return True if the user has purchased the song, false otherwise
     */
    function hasUserPurchased(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }

    /**
     * @notice Gets the current net price of a song
     * @param id The song ID to query
     * @return The net price of the song in wei or token units 
     *         (does not include fees or taxes)
     */
    function getPrice(uint256 id) external view returns (uint256) {
        return songs[id].Price;
    }

    /**
     * @notice Gets the principal artist ID for a song
     * @param id The song ID to query
     * @return The unique identifier of the principal artist
     */
    function getPrincipalArtistId(uint256 id) external view returns (uint256) {
        return songs[id].PrincipalArtistId;
    }

    /**
     * @notice Checks if a song is available for purchase
     * @param id The song ID to query
     * @return True if the song can be purchased, false otherwise
     */
    function isPurchasable(uint256 id) external view returns (bool) {
        return songs[id].CanBePurchased;
    }

    /**
     * @notice Checks if a song is banned from the platform
     * @param id The song ID to query
     * @return True if the song is banned, false otherwise
     */
    function checkIsBanned(uint256 id) external view returns (bool) {
        return songs[id].IsBanned;
    }

    /**
     * @notice Retrieves all metadata for a song
     * @param id The song ID to query
     * @return Complete SongMetadata struct with all song information
     */
    function getMetadata(
        uint256 id
    ) external view returns (SongMetadata memory) {
        return songs[id];
    }
}














/**********************************
🮋🮋 Made with ❤️ by 11:11 Labs 🮋🮋
⢕⢕⢕⢕⠁⢜⠕⢁⣴⣿⡇⢓⢕⢵⢐⢕⢕⠕⢁⣾⢿⣧⠑⢕⢕⠄⢑⢕⠅⢕
⢕⢕⠵⢁⠔⢁⣤⣤⣶⣶⣶⡐⣕⢽⠐⢕⠕⣡⣾⣶⣶⣶⣤⡁⢓⢕⠄⢑⢅⢑
⠍⣧⠄⣶⣾⣿⣿⣿⣿⣿⣿⣷⣔⢕⢄⢡⣾⣿⣿⣿⣿⣿⣿⣿⣦⡑⢕⢤⠱⢐
⢠⢕⠅⣾⣿⠋⢿⣿⣿⣿⠉⣿⣿⣷⣦⣶⣽⣿⣿⠈⣿⣿⣿⣿⠏⢹⣷⣷⡅⢐
⣔⢕⢥⢻⣿⡀⠈⠛⠛⠁⢠⣿⣿⣿⣿⣿⣿⣿⣿⡀⠈⠛⠛⠁⠄⣼⣿⣿⡇⢔
⢕⢕⢽⢸⢟⢟⢖⢖⢤⣶⡟⢻⣿⡿⠻⣿⣿⡟⢀⣿⣦⢤⢤⢔⢞⢿⢿⣿⠁⢕
⢕⢕⠅⣐⢕⢕⢕⢕⢕⣿⣿⡄⠛⢀⣦⠈⠛⢁⣼⣿⢗⢕⢕⢕⢕⢕⢕⡏⣘⢕
⢕⢕⠅⢓⣕⣕⣕⣕⣵⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣷⣕⢕⢕⢕⢕⡵⢀⢕⢕
⢑⢕⠃⡈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢃⢕⢕⢕
⣆⢕⠄⢱⣄⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢁⢕⢕⠕⢁
***********************************/