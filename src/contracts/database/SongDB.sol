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
    /// @dev Thrown when a user tries to purchase or gift a song they already own
    error UserAlreadyOwns();
    /// @dev Thrown when trying to refund a song the user does not own
    error UserDoesNotOwnSong();
    /// @dev Thrown when attempting to view the list of owners while it is not visible
    error CannotSeeListOfOwners();
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Type Declarations 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
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
     * @param listOfOwners Dynamic array storing all user IDs that own this song.
     *                     Used for tracking and iterating over song owners.
     * @param IsBanned Flag indicating if the song has been banned from the platform
     */
    struct Metadata {
        string Title;
        uint256 PrincipalArtistId;
        uint256[] ArtistIDs;
        string MediaURI;
        string MetadataURI;
        bool CanBePurchased;
        uint256 Price;
        uint256 TimesBought;
        uint256[] listOfOwners;
        bool IsBanned;
    }

    /**
     * @notice Enum representing types of metadata changes for a song
     * @dev Used in events to indicate what type of data was modified
     */
    enum ChangeType {
        MetadataUpdated,
        PurchaseabilityChanged,
        PriceChanged
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 State Variables 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /** 
     *  @notice Tracks whether the list of song owners is publicly visible
     *  @dev If false, only the owner (Orchestrator) can view the full list
     */
    bool private listVisibility;
    /**
     * @notice Tracks whether a user owns a specific song
     * @dev Mapping: songId => userId => status
     *      - 0x00 = not owned
     *      - 0x01 = bought (owned)
     *      - 0x02 = gifted (owned)
     */
    mapping(uint256 Id => mapping(uint256 userId => bytes1))
        private ownByUserId;

    /**
     * @notice Stores all song metadata indexed by song ID
     * @dev Private mapping to prevent direct external access
     */
    mapping(uint256 Id => Metadata) private song;

    /**
     * @notice Tracks the index location of a user in a song's listOfOwners array
     * @dev Used for efficient removal of users from ownership list during refunds
     */
    mapping(uint256 Id => mapping(uint256 userId => uint256 locationOnIndex))
        private ownerIndex;

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Events 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Emitted when a new song is registered in the database
     * @param songId The unique identifier assigned to the song
     */
    event Registered(uint256 indexed songId);

    /**
     * @notice Emitted when a song is purchased by a user
     * @param songId The unique identifier of the purchased song
     * @param userId The unique identifier of the purchasing user
     * @param timestamp The block timestamp when the purchase occurred
     */
    event Purchased(
        uint256 indexed songId,
        uint256 indexed userId,
        uint256 indexed timestamp
    );

    /**
     * @notice Emitted when a song is gifted to a user
     * @param songId The unique identifier of the gifted song
     * @param userId The unique identifier of the recipient user
     * @param timestamp The block timestamp when the gift occurred
     */
    event Gifted(
        uint256 indexed songId,
        uint256 indexed userId,
        uint256 indexed timestamp
    );

    /**
     * @notice Emitted when a song purchase is refunded
     * @param songId The unique identifier of the refunded song
     * @param userId The unique identifier of the user receiving refund
     * @param timestamp The block timestamp when the refund occurred
     */
    event Refunded(
        uint256 indexed songId,
        uint256 indexed userId,
        uint256 indexed timestamp
    );

    /**
     * @notice Emitted when song metadata, purchasability, or price is changed
     * @param songId The unique identifier of the modified song
     * @param timestamp The block timestamp when the change occurred
     * @param changeType The type of change that was made
     */
    event Changed(
        uint256 indexed songId,
        uint256 indexed timestamp,
        ChangeType indexed changeType
    );

    /**
     * @notice Emitted when a song is banned from the platform
     * @param songId The unique identifier of the banned song
     */
    event Banned(uint256 indexed songId);

    /**
     * @notice Emitted when a song ban is lifted
     * @param songId The unique identifier of the unbanned song
     */
    event Unbanned(uint256 indexed songId);

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
        if (song[id].IsBanned) revert SongIsBanned();
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

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 External Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
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

        song[idAssigned] = Metadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            ArtistIDs: artistIDs,
            MediaURI: mediaURI,
            MetadataURI: metadataURI,
            CanBePurchased: canBePurchased,
            Price: price,
            TimesBought: 0,
            listOfOwners: new uint256[](0),
            IsBanned: false
        });

        emit Registered(idAssigned);

        return idAssigned;
    }

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
        if (!song[id].CanBePurchased) revert SongCannotBePurchased();
        if (ownByUserId[id][userId] != 0x00) revert UserAlreadyOwns();

        ownByUserId[id][userId] = 0x01;
        song[id].TimesBought++;
        song[id].listOfOwners.push(userId);
        ownerIndex[id][userId] = song[id].listOfOwners.length;

        emit Purchased(id, userId, block.timestamp);
    }

    /**
     * @notice Gifts a song to a user without payment
     * @dev Only callable by owner. Reverts if user already owns it or song is banned.
     * @param id The song ID to gift
     * @param toUserId The unique identifier of the recipient user
     */
    function gift(
        uint256 id,
        uint256 toUserId
    ) external onlyOwner onlyIfExist(id) onlyIfNotBanned(id) {
        if (ownByUserId[id][toUserId] != 0x00) revert UserAlreadyOwns();

        ownByUserId[id][toUserId] = 0x02;
        song[id].TimesBought++;
        song[id].listOfOwners.push(toUserId);

        emit Gifted(id, toUserId, block.timestamp);
    }

    /**
     * @notice Processes a refund for a previously purchased/gifted song
     * @dev Only callable by owner. Reverts if user hasn't owned the song.
     *      Uses a swap-and-pop algorithm for O(1) removal from the listOfOwners array:
     *      1. Retrieve the user's position from ownerIndex (stored as position + 1)
     *      2. Swap the user with the last element in the array
     *      3. Update the swapped user's index in ownerIndex
     *      4. Pop the last element (now the removed user)
     *      5. Clean up mappings and decrement TimesBought
     * @param id The song ID to refund
     * @param userId The unique identifier of the user requesting refund
     */
    function refund(
        uint256 id,
        uint256 userId
    ) external onlyOwner onlyIfExist(id) {
        /// @dev Retrieve the stored index (1-indexed to distinguish from "not found")
        uint256 ownerSlotPlusOne = ownerIndex[id][userId];

        /// @dev If ownerSlotPlusOne is 0, the user was never added to the list
        if (ownerSlotPlusOne == 0) revert UserDoesNotOwnSong();
        
        /// @dev Convert to 0-indexed position for array access
        uint256 ownerSlot = ownerSlotPlusOne - 1;

        /// @dev Get the last element's index and value for the swap operation
        uint256 lastIndex = song[id].listOfOwners.length - 1;
        uint256 lastUser = song[id].listOfOwners[lastIndex];

        /// @dev Swap-and-pop: Only swap if the user is not already the last element
        if (ownerSlot != lastIndex) {
            /// @dev Move the last user to the position of the user being removed
            song[id].listOfOwners[ownerSlot] = lastUser;
            /// @dev Update the moved user's index in the mapping (store as 1-indexed)
            ownerIndex[id][lastUser] = ownerSlot + 1;
        }
        
        /// @dev Remove the last element (either the removed user or the duplicate after swap)
        song[id].listOfOwners.pop();

        /// @dev Clean up the removed user's index tracking
        delete ownerIndex[id][userId];
        /// @dev Remove ownership status from the user
        delete ownByUserId[id][userId];

        /// @dev Decrement the total purchase counter
        song[id].TimesBought--;

        emit Refunded(id, userId, block.timestamp);
    }

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
        song[id] = Metadata({
            Title: title,
            PrincipalArtistId: principalArtistId,
            ArtistIDs: artistIDs,
            MediaURI: mediaURI,
            MetadataURI: metadataURI,
            CanBePurchased: canBePurchased,
            Price: price,
            TimesBought: song[id].TimesBought,
            listOfOwners: song[id].listOfOwners,
            IsBanned: song[id].IsBanned
        });

        emit Changed(id, block.timestamp, ChangeType.MetadataUpdated);
    }

    /**
     * @notice Updates the purchasability status of a song
     * @dev Only callable by owner. Cannot modify banned song.
     * @param id The song ID to update
     * @param canBePurchased New purchasability status (true = available for sale)
     */
    function changePurchaseability(
        uint256 id,
        bool canBePurchased
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        song[id].CanBePurchased = canBePurchased;

        emit Changed(id, block.timestamp, ChangeType.PurchaseabilityChanged);
    }

    /**
     * @notice Updates the net price of a song
     * @dev Only callable by owner. Cannot modify banned song.
     *      This is the net price; fees and taxes are separate.
     * @param id The song ID to update
     * @param price New net purchase price for the song
     */
    function changePrice(
        uint256 id,
        uint256 price
    ) external onlyOwner onlyIfNotBanned(id) onlyIfExist(id) {
        song[id].Price = price;

        emit Changed(id, block.timestamp, ChangeType.PriceChanged);
    }

    /**
     * @notice Sets the banned status of a song
     * @dev Only callable by owner. Banned song cannot be purchased or modified.
     * @param id The song ID to update
     * @param isBanned New banned status (true = banned from platform)
     */
    function setBannedStatus(
        uint256 id,
        bool isBanned
    ) external onlyOwner onlyIfExist(id) {
        song[id].IsBanned = isBanned;

        if (isBanned) emit Banned(id);
        else emit Unbanned(id);
    }

    /**
     * @notice Sets the public visibility of the song owners list
     * @dev Only callable by owner. If set to false, only the owner (Orchestrator)
     *      can view the full list of song owners.
     * @param isVisible New visibility status (true = publicly visible)
     */
    function setListVisibility(bool isVisible) external onlyOwner {
        listVisibility = isVisible;
    }
    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Getter Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
    /**
     * @notice Checks if a user owns a specific song
     * @param id The song ID to check
     * @param userId The user ID to check
     * @return True if the user owns the song, false otherwise
     */
    function isUserOwner(
        uint256 id,
        uint256 userId
    ) external view returns (bool) {
        return ownByUserId[id][userId] != 0x00;
    }

    /**
     * @notice Retrieves the ownership status byte for a user and song
     * @param id The song ID to check
     * @param userId The user ID to check
     * @return The ownership status byte (0x00 = not owned, 0x01 = bought, 0x02 = gifted)
     */
    function userOwnershipStatus(
        uint256 id,
        uint256 userId
    ) external view returns (bytes1) {
        return ownByUserId[id][userId];
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
        return ownByUserId[id][userId] != 0x00;
    }

    /**
     * @notice Retrieves the ownership status byte for a user and song
     * @param id The song ID to check
     * @param userId The user ID to check
     * @return The ownership status byte (0x00 = not owned, 0x01 = bought, 0x02 = gifted)
     */
    function checkOwnership(
        uint256 id,
        uint256 userId
    ) external view returns (bytes1) {
        return ownByUserId[id][userId];
    }

    /**
     * @notice Gets the current net price of a song
     * @param id The song ID to query
     * @return The net price of the song in wei or token units
     *         (does not include fees or taxes)
     */
    function getPrice(uint256 id) external view returns (uint256) {
        return song[id].Price;
    }

    /**
     * @notice Gets the principal artist ID for a song
     * @param id The song ID to query
     * @return The unique identifier of the principal artist
     */
    function getPrincipalArtistId(uint256 id) external view returns (uint256) {
        return song[id].PrincipalArtistId;
    }

    /**
     * @notice Checks if a song is available for purchase
     * @param id The song ID to query
     * @return True if the song can be purchased, false otherwise
     */
    function isPurchasable(uint256 id) external view returns (bool) {
        return song[id].CanBePurchased;
    }

    /**
     * @notice Checks if a song is banned from the platform
     * @param id The song ID to query
     * @return True if the song is banned, false otherwise
     */
    function checkIsBanned(uint256 id) external view returns (bool) {
        return song[id].IsBanned;
    }

    /**
     * @notice Retrieves all metadata for a song
     * @param id The song ID to query
     * @return Complete Metadata struct with all song information
     */
    function getMetadata(uint256 id) external view returns (Metadata memory) {
        return song[id];
    }

    /**
     * @notice Retrieves the full list of user IDs that own a specific album
     * @dev Respects the listVisibility setting; reverts if visibility is disabled
     *      and caller is not the owner (Orchestrator).
     * @param id The album ID to query
     * @return Array of user IDs owning the album
     */
    function getListOfOwners(
        uint256 id
    ) external view returns (uint256[] memory) {
        if (!listVisibility && msg.sender != owner())
            revert CannotSeeListOfOwners();

        return song[id].listOfOwners;
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
