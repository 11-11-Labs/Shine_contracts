// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
 * @title Shine ArtistDB
 * @author 11:11 Labs 
 * @notice This contract serves as a database for storing and managing artist metadata,
 *         including registration, profile data, balance tracking, and royalty management
 *         for the Shine music platform.
 * @dev Inherits from IdUtils for unique ID generation and Ownable for access control.
 *      Only the Orchestrator contract (owner) can modify state.
 */

import {IdUtils} from "@shine/library/IdUtils.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract ArtistDB is IdUtils, Ownable {
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /// @dev Thrown when attempting to interact with a banned artist
    error ArtistIsBanned();
    /// @dev Thrown when trying to set an artist name to empty string
    error NameShouldNotBeEmpty();
    /// @dev Thrown when attempting to access an artist that does not exist
    error ArtistDoesNotExist();

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Structs 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Stores all metadata associated with an artist
     * @dev Used to track artist information, balance, royalties, and ban status
     * @param Name The display name of the artist
     * @param MetadataURI URI pointing to off-chain metadata (e.g., IPFS)
     * @param Address The wallet address associated with this artist
     * @param Balance Current balance of the artist account
     * @param AccumulatedRoyalties Total royalties accumulated from music sales
     * @param IsBanned Flag indicating if the artist has been banned from the platform
     */
    struct Artist {
        string Name;
        string MetadataURI;
        address Address;
        uint256 Balance;
        uint256 AccumulatedRoyalties;
        bool IsBanned;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Mappings 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /// @notice Maps artist wallet addresses to their unique IDs
    /// @dev Provides quick lookup of artist ID by their Ethereum address
    mapping(address artistAddress => uint256 id) private addressArtist;

    /// @notice Stores all artist metadata indexed by artist ID
    /// @dev Private mapping to prevent direct external access
    mapping(uint256 id => Artist) private artists;

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Modifiers 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Ensures the artist exists before executing the function
     * @dev Reverts with ArtistDoesNotExist if the artist ID is not registered
     * @param id The artist ID to validate
     */
    modifier onlyIfExist(uint256 id) {
        if (!exists(id)) revert ArtistDoesNotExist();
        _;
    }

    /**
     * @notice Ensures the artist is not banned before executing the function
     * @dev Reverts with ArtistIsBanned if the artist has been banned
     * @param id The artist ID to validate
     */
    modifier onlyIfNotBanned(uint256 id) {
        if (artists[id].IsBanned) revert ArtistIsBanned();
        _;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Constructor 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Initializes the ArtistDB contract
     * @dev Sets the Orchestrator contract as the owner for access control
     * @param _orchestratorAddress Address of the Orchestrator contract that will manage this database
     */
    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Registration 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Registers a new artist in the database
     * @dev Only callable by the Orchestrator (owner). Assigns a unique ID automatically.
     * @param name The display name of the artist
     * @param metadataURI URI pointing to off-chain metadata (e.g., IPFS hash)
     * @param artistAddress The wallet address of the artist
     * @return The newly assigned artist ID
     */
    function register(
        string memory name,
        string memory metadataURI,
        address artistAddress
    ) external onlyOwner returns (uint256) {
        uint256 idAssigned = _getNextId();

        artists[idAssigned] = Artist({
            Name: name,
            MetadataURI: metadataURI,
            Address: artistAddress,
            Balance: 0,
            AccumulatedRoyalties: 0,
            IsBanned: false
        });

        return idAssigned;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Admin Changes 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Updates basic artist information (name and metadata)
     * @dev Only callable by owner. Cannot modify banned artists. Name cannot be empty.
     * @param id The artist ID to update
     * @param name New display name for the artist
     * @param metadataURI New URI for off-chain metadata
     */
    function changeBasicData(
        uint256 id,
        string memory name,
        string memory metadataURI
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        if (bytes(name).length == 0) revert NameShouldNotBeEmpty();

        artists[id].Name = name;
        artists[id].MetadataURI = metadataURI;
    }

    /**
     * @notice Updates the wallet address associated with an artist
     * @dev Only callable by owner. Updates both direction mappings.
     * @param id The artist ID to update
     * @param newArtistAddress New wallet address for the artist
     */
    function changeAddress(
        uint256 id,
        address newArtistAddress
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        addressArtist[artists[id].Address] = 0;
        artists[id].Address = newArtistAddress;
        addressArtist[newArtistAddress] = id;
    }

    /**
     * @notice Adds balance to an artist account
     * @dev Only callable by owner. Cannot be called on banned artists.
     * @param artistId The artist ID to credit
     * @param amount The amount to add to balance
     */
    function addBalance(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner onlyIfExist(artistId) onlyIfNotBanned(artistId) {
        artists[artistId].Balance += amount;
    }

    /**
     * @notice Deducts balance from an artist account
     * @dev Only callable by owner.
     * @param artistId The artist ID to debit
     * @param amount The amount to deduct from balance
     */
    function deductBalance(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner onlyIfExist(artistId) {
        artists[artistId].Balance -= amount;
    }

    /**
     * @notice Adds accumulated royalties to an artist account
     * @dev Only callable by owner. Cannot be called on banned artists.
     * @param artistId The artist ID to credit
     * @param amount The amount of royalties to add
     */
    function addAccumulatedRoyalties(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner onlyIfExist(artistId) onlyIfNotBanned(artistId) {
        artists[artistId].AccumulatedRoyalties += amount;
    }

    /**
     * @notice Deducts accumulated royalties from an artist account
     * @dev Only callable by owner.
     * @param artistId The artist ID to debit
     * @param amount The amount of royalties to deduct
     */
    function deductAccumulatedRoyalties(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner onlyIfExist(artistId) {
        artists[artistId].AccumulatedRoyalties -= amount;
    }

    /**
     * @notice Sets the banned status of an artist
     * @dev Only callable by owner. Banned artists cannot have their data modified.
     * @param artistId The artist ID to update
     * @param action New banned status (true = banned from platform)
     */
    function setBannedStatus(
        uint256 artistId,
        bool action
    ) external onlyOwner onlyIfExist(artistId) {
        artists[artistId].IsBanned = action;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 View Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Retrieves all metadata for an artist
     * @param id The artist ID to query
     * @return Complete Artist struct with all information
     */
    function getMetadata(uint256 id) external view returns (Artist memory) {
        return artists[id];
    }

    /**
     * @notice Gets the wallet address associated with an artist
     * @param id The artist ID to query
     * @return The artist's wallet address
     */
    function getAddress(uint256 id) external view returns (address) {
        return artists[id].Address;
    }

    /**
     * @notice Gets the artist ID for a given wallet address
     * @param artistAddress The artist's wallet address
     * @return The unique identifier of the artist
     */
    function getId(address artistAddress) external view returns (uint256) {
        return addressArtist[artistAddress];
    }

    /**
     * @notice Gets the current balance of an artist
     * @param artistId The artist ID to query
     * @return The artist's current balance
     */
    function getBalance(uint256 artistId) external view returns (uint256) {
        return artists[artistId].Balance;
    }

    /**
     * @notice Checks if an artist is banned from the platform
     * @param id The artist ID to query
     * @return True if the artist is banned, false otherwise
     */
    function checkIsBanned(uint256 id) external view returns (bool) {
        return artists[id].IsBanned;
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