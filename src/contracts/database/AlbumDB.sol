// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
 * @title Shine AlbumDB
 * @author 11:11 Labs 
 * @notice This contract serves as a database for storing and managing album metadata,
 *         including purchases, refunds, special editions, and administrative controls
 *         for the Shine music platform.
 * @dev Inherits from IdUtils for unique ID generation and Ownable for access control.
 *      Only the Orchestrator contract (owner) can modify state.
 */

import {IdUtils} from "@shine/library/IdUtils.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract AlbumDB is IdUtils, Ownable {
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Errors 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /// @dev Thrown when attempting to access an album that does not exist
    error AlbumDoesNotExist();
    /// @dev Thrown when a user tries to purchase an album they already own
    error UserBoughtAlbum();
    /// @dev Thrown when attempting to purchase an album that is not available for sale
    error AlbumNotPurchasable();
    /// @dev Thrown when attempting to interact with a banned album
    error AlbumIsBanned();
    /// @dev Thrown when the special edition max supply has been reached
    error AlbumMaxSupplyReached();
    /// @dev Thrown when trying to refund an album the user has not purchased
    error UserNotBoughtAlbum();
    /// @dev Thrown when trying to create or update an album with zero songs
    error AlbumCannotHaveZeroSongs();

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Structs 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Stores all metadata associated with an album
     * @dev Used to track album information, pricing, purchase status, and special editions
     * @param Title The display name of the album
     * @param PrincipalArtistId The unique identifier of the main artist
     * @param MetadataURI URI pointing to off-chain metadata (e.g., IPFS)
     * @param MusicIds Array of song IDs included in this album
     * @param Price The net purchase price for this album (in wei or token units).
     *              Does not include platform fees or taxes.
     * @param TimesBought Counter tracking total number of purchases
     * @param CanBePurchased Flag indicating if the album is available for sale
     * @param IsASpecialEdition Flag indicating if this is a limited special edition
     * @param SpecialEditionName Name identifier for the special edition
     * @param MaxSupplySpecialEdition Maximum copies available for special editions
     * @param IsBanned Flag indicating if the album has been banned from the platform
     */
    struct Metadata {
        string Title;
        uint256 PrincipalArtistId;
        string MetadataURI;
        uint256[] MusicIds;
        uint256 Price;
        uint256 TimesBought;
        bool CanBePurchased;
        bool IsASpecialEdition;
        string SpecialEditionName;
        uint256 MaxSupplySpecialEdition;
        bool IsBanned;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Mappings 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /// @notice Tracks whether a user has purchased a specific album
    /// @dev Mapping: albumId => userId => hasPurchased
    mapping(uint256 Id => mapping(uint256 userId => bool)) isBoughtByUserId;

    /// @notice Stores all album metadata indexed by album ID
    /// @dev Private mapping to prevent direct external access
    mapping(uint256 Id => Metadata) private albums;

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Modifiers 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Ensures the album exists before executing the function
     * @dev Reverts with AlbumDoesNotExist if the album ID is not registered
     * @param id The album ID to validate
     */
    modifier onlyIfExist(uint256 id) {
        if (!exists(id)) revert AlbumDoesNotExist();
        _;
    }

    /**
     * @notice Ensures the album is not banned before executing the function
     * @dev Reverts with AlbumIsBanned if the album has been banned
     * @param id The album ID to validate
     */
    modifier onlyIfNotBanned(uint256 id) {
        if (albums[id].IsBanned) revert AlbumIsBanned();
        _;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Constructor 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Initializes the AlbumDB contract
     * @dev Sets the Orchestrator contract as the owner for access control
     * @param _orchestratorAddress Address of the Orchestrator contract that will
     *                             manage this database
     */
    constructor(address _orchestratorAddress) {
        _initializeOwner(_orchestratorAddress);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Registration 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Registers a new album in the database
     * @dev Only callable by the Orchestrator (owner). Assigns a unique ID automatically.
     * @param title The display name of the album
     * @param principalArtistId The unique ID of the main artist
     * @param metadataURI URI pointing to off-chain metadata (e.g., IPFS hash)
     * @param songIDs Array of song IDs included in this album
     * @param price The net purchase price for this album.
     *              Additional fees and taxes may apply separately.
     * @param canBePurchased Whether the album is available for purchase
     * @param isASpecialEdition Whether this is a limited special edition
     * @param specialEditionName Name for the special edition (if applicable)
     * @param maxSupplySpecialEdition Maximum copies for special edition (0 if not special)
     * @return The newly assigned album ID
     */
    function register(
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory songIDs,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external onlyOwner returns (uint256) {
        uint256 idAssigned = _getNextId();

        albums[idAssigned] = Metadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            MetadataURI: metadataURI,
            MusicIds: songIDs,
            Price: price,
            TimesBought: 0,
            CanBePurchased: canBePurchased,
            IsASpecialEdition: isASpecialEdition,
            SpecialEditionName: specialEditionName,
            MaxSupplySpecialEdition: maxSupplySpecialEdition,
            IsBanned: false
        });

        return idAssigned;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Purchases 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Processes a standard album purchase for a user
     * @dev Only callable by owner. Marks the album as purchased by the user and 
     *      increments the purchase counter. For special editions, validates that
     *      max supply has not been reached. Reverts if: user already owns album,
     *      album is not purchasable, album is banned, or special edition max supply reached.
     * @param id The album ID to purchase
     * @param userId The unique identifier of the purchasing user
     * @return Array of song IDs included in the purchased album
     */
    function purchase(
        uint256 id,
        uint256 userId
    )
        external
        onlyOwner
        onlyIfNotBanned(id)
        onlyIfExist(id)
        returns (uint256[] memory)
    {
        if (isBoughtByUserId[id][userId]) revert UserBoughtAlbum();

        if (!albums[id].CanBePurchased) revert AlbumNotPurchasable();

        if (albums[id].IsASpecialEdition) {
            if (albums[id].TimesBought >= albums[id].MaxSupplySpecialEdition) {
                revert AlbumMaxSupplyReached();
            }
        }

        isBoughtByUserId[id][userId] = true;
        albums[id].TimesBought++;

        return albums[id].MusicIds;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Refunds 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Processes a refund for a previously purchased album
     * @dev Only callable by owner. Reverts if user hasn't purchased the album.
     * @param id The album ID to refund
     * @param userId The unique identifier of the user requesting refund
     * @return Tuple containing (array of song IDs, refund price amount)
     */
    function refund(
        uint256 id,
        uint256 userId
    ) external onlyOwner onlyIfExist(id) returns (uint256[] memory, uint256) {
        if (!isBoughtByUserId[id][userId]) revert UserNotBoughtAlbum();

        isBoughtByUserId[id][userId] = false;
        albums[id].TimesBought--;

        return (albums[id].MusicIds, albums[id].Price);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Metadata Changes 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Updates all metadata fields for an existing album
     * @dev Only callable by owner. Preserves TimesBought and IsBanned status.
     *      Reverts if musicIds is empty.
     * @param id The album ID to update
     * @param title New display name for the album
     * @param principalArtistId New principal artist ID
     * @param metadataURI New URI for off-chain metadata
     * @param musicIds New array of song IDs (cannot be empty)
     * @param price New net purchase price. Additional fees and taxes may apply separately.
     * @param canBePurchased New purchasability status
     * @param isASpecialEdition New special edition status
     * @param specialEditionName New special edition name
     * @param maxSupplySpecialEdition New max supply for special edition
     */
    function change(
        uint256 id,
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory musicIds,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        if (musicIds.length == 0) revert AlbumCannotHaveZeroSongs();

        albums[id] = Metadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            MetadataURI: metadataURI,
            MusicIds: musicIds,
            Price: price,
            TimesBought: albums[id].TimesBought,
            CanBePurchased: canBePurchased,
            IsASpecialEdition: isASpecialEdition,
            SpecialEditionName: specialEditionName,
            MaxSupplySpecialEdition: maxSupplySpecialEdition,
            IsBanned: albums[id].IsBanned
        });
    }

    /**
     * @notice Updates the purchasability status of an album
     * @dev Only callable by owner. Cannot modify banned albums.
     * @param id The album ID to update
     * @param canBePurchased New purchasability status (true = available for sale)
     */
    function changePurchaseability(
        uint256 id,
        bool canBePurchased
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        albums[id].CanBePurchased = canBePurchased;
    }

    /**
     * @notice Updates the net price of an album
     * @dev Only callable by owner. Cannot modify banned albums.
     *      This is the net price; fees and taxes are separate.
     * @param id The album ID to update
     * @param price New net purchase price for the album
     */
    function changePrice(
        uint256 id,
        uint256 price
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        albums[id].Price = price;
    }

    /**
     * @notice Sets the banned status of an album
     * @dev Only callable by owner. Banned albums cannot be purchased or modified.
     * @param id The album ID to update
     * @param isBanned New banned status (true = banned from platform)
     */
    function setBannedStatus(
        uint256 id,
        bool isBanned
    ) external onlyOwner onlyIfExist(id) {
        albums[id].IsBanned = isBanned;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 View Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Checks if a user has already purchased an album
     * @dev Returns true if the user has bought the album (useful before attempting purchase)
     * @param id The album ID to check
     * @param userId The user ID to check
     * @return True if the user has purchased the album, false otherwise
     */
    function canUserBuy(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }

    /**
     * @notice Checks if an album is a special edition
     * @param id The album ID to query
     * @return True if the album is a special edition, false otherwise
     */
    function isAnSpecialEdition(uint256 id) external view returns (bool) {
        return albums[id].IsASpecialEdition;
    }

    /**
     * @notice Gets the total number of times an album has been purchased if
     *         is a special edition
     * @param id The album ID to query
     * @return The total purchase count for the album
     *
     * @notice if the album is not a special edition, this returns 0
     */
    function getTotalSupply(uint256 id) external view returns (uint256) {
        return albums[id].TimesBought;
    }

    /**
     * @notice Gets the current net price of an album
     * @param id The album ID to query
     * @return The net price of the album in wei or token units (does not include fees or taxes)
     */
    function getPrice(uint256 id) external view returns (uint256) {
        return albums[id].Price;
    }

    /**
     * @notice Checks if an album is available for purchase
     * @param id The album ID to query
     * @return True if the album can be purchased, false otherwise
     */
    function isPurchasable(uint256 id) external view returns (bool) {
        return albums[id].CanBePurchased;
    }

    /**
     * @notice Checks if a user has purchased a specific album
     * @param id The album ID to check
     * @param userId The user ID to check
     * @return True if the user has purchased the album, false otherwise
     */
    function hasUserPurchased(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return isBoughtByUserId[id][userId];
    }

    /**
     * @notice Gets the principal artist ID for an album
     * @param id The album ID to query
     * @return The unique identifier of the principal artist
     */
    function getPrincipalArtistId(uint256 id) external view returns (uint256) {
        return albums[id].PrincipalArtistId;
    }

    /**
     * @notice Checks if an album is banned from the platform
     * @param id The album ID to query
     * @return True if the album is banned, false otherwise
     */
    function checkIsBanned(uint256 id) external view returns (bool) {
        return albums[id].IsBanned;
    }

    /**
     * @notice Retrieves all metadata for an album
     * @param id The album ID to query
     * @return Complete Metadata struct with all album information
     */
    function getMetadata(
        uint256 id
    ) external view returns (Metadata memory) {
        return albums[id];
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
