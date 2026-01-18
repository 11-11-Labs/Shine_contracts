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

import {Ownable} from "@solady/auth/Ownable.sol";
import {IERC20} from "@shine/interface/IERC20.sol";
import {ErrorsLib} from "@shine/contracts/orchestrator/library/ErrorsLib.sol";
import {StructsLib} from "@shine/contracts/orchestrator/library/StructsLib.sol";
import {EventsLib} from "@shine/contracts/orchestrator/library/EventsLib.sol";

import {ISongDB} from "@shine/interface/ISongDB.sol";
import {IAlbumDB} from "@shine/interface/IAlbumDB.sol";
import {IArtistDB} from "@shine/interface/IArtistDB.sol";
import {IUserDB} from "@shine/interface/IUserDB.sol";

contract Orchestrator is Ownable {
    address private newOrchestratorAddress;
    uint256 private amountCollectedInFees;
    StructsLib.AddressProposal private stablecoin;
    StructsLib.DataBaseList private dbAddress;
    StructsLib.Breakers private breaker;
    uint16 private percentageFee;

    ISongDB private songDB;
    IAlbumDB private albumDB;
    IArtistDB private artistDB;
    IUserDB private userDB;

    modifier senderIsUserId(uint256 userId) {
        if (userDB.getAddress(userId) != msg.sender)
            revert ErrorsLib.AddressIsNotOwnerOfUserId();
        _;
    }

    modifier userIdExists(uint256 userId) {
        if (!userDB.exists(userId)) revert ErrorsLib.UserIdDoesNotExist();
        _;
    }

    modifier senderIsArtistId(uint256 artistId) {
        if (artistDB.getAddress(artistId) != msg.sender)
            revert ErrorsLib.AddressIsNotOwnerOfArtistId();
        _;
    }

    modifier artistIdExists(uint256 artistId) {
        if (!artistDB.exists(artistId))
            revert ErrorsLib.ArtistIdDoesNotExist(artistId);
        _;
    }

    modifier songIdExists(uint256 songId) {
        if (!songDB.exists(songId)) revert ErrorsLib.SongIdDoesNotExist(songId);
        _;
    }

    modifier albumIdExists(uint256 albumId) {
        if (!albumDB.exists(albumId)) revert();
        _;
    }

    constructor(address initialOwner, address _stablecoinAddress) {
        _initializeOwner(initialOwner);
        stablecoin.current = _stablecoinAddress;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 User/Artist Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    function register(
        bool isArtist,
        string memory name,
        string memory metadataURI,
        address addressToUse
    ) external returns (uint256) {
        if (isArtist) {
            return artistDB.register(name, metadataURI, addressToUse);
        } else {
            return userDB.register(name, metadataURI, addressToUse);
        }
    }

    function chnageBasicData(
        bool isArtist,
        uint256 id,
        string memory name,
        string memory metadataURI
    ) external {
        if (isArtist) {
            if (artistDB.getAddress(id) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfArtistId();

            artistDB.changeBasicData(id, name, metadataURI);
        } else {
            if (userDB.getAddress(id) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfUserId();

            userDB.changeBasicData(id, name, metadataURI);
        }
    }

    function changeAddress(
        bool isArtist,
        uint256 id,
        address newAddress
    ) external {
        if (isArtist) {
            if (artistDB.getAddress(id) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfArtistId();

            artistDB.changeAddress(id, newAddress);
        } else {
            if (userDB.getAddress(id) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfUserId();

            userDB.changeAddress(id, newAddress);
        }
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Funds Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    function depositFunds(uint256 userId, uint256 amount) external {
        if (userDB.getAddress(userId) != msg.sender)
            revert ErrorsLib.AddressIsNotOwnerOfUserId();

        IERC20(stablecoin.current).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        userDB.addBalance(userId, amount);
    }

    function depositFundsToAnotherUser(
        uint256 toUserId,
        uint256 amount
    ) external userIdExists(toUserId) {
        IERC20(stablecoin.current).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        userDB.addBalance(toUserId, amount);
    }

    function makeDonation(
        uint256 userId,
        uint256 toArtistId,
        uint256 amount
    ) external senderIsUserId(userId) artistIdExists(toArtistId) {
        uint256 userBalance = userDB.getBalance(userId);
        if (userBalance < amount) revert ErrorsLib.InsufficientBalance();

        userDB.deductBalance(userId, amount);
        artistDB.addBalance(toArtistId, amount);

        emit EventsLib.DonationMade(userId, toArtistId, amount);
    }

    function withdrawFunds(
        bool isArtist,
        uint256 userId,
        uint256 amount
    ) external {
        if (isArtist) {
            if (artistDB.getAddress(userId) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfArtistId();

            if (artistDB.getBalance(userId) < amount)
                revert ErrorsLib.InsufficientBalance();

            artistDB.deductBalance(userId, amount);
        } else {
            if (userDB.getAddress(userId) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfUserId();

            if (userDB.getBalance(userId) < amount)
                revert ErrorsLib.InsufficientBalance();

            userDB.deductBalance(userId, amount);
        }

        IERC20(stablecoin.current).transfer(msg.sender, amount);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Song Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    function registerSong(
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 netprice
    ) external senderIsArtistId(principalArtistId) returns (uint256) {
        if (artistIDs.length > 0) {
            for (uint256 i = 0; i < artistIDs.length; i++) {
                if (!artistDB.exists(artistIDs[i]))
                    revert ErrorsLib.ArtistIdDoesNotExist(artistIDs[i]);
            }
        }

        if (bytes(title).length == 0) revert ErrorsLib.TitleCannotBeEmpty();

        return
            songDB.register(
                title,
                principalArtistId,
                artistIDs,
                mediaURI,
                metadataURI,
                canBePurchased,
                netprice
            );
    }

    function changeSongFullData(
        uint256 id,
        string memory title,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    )
        external
        senderIsArtistId(songDB.getPrincipalArtistId(id))
        songIdExists(id)
    {
        songDB.change(
            id,
            title,
            songDB.getPrincipalArtistId(id),
            artistIDs,
            mediaURI,
            metadataURI,
            canBePurchased,
            price
        );
    }

    function changeSongPurchaseability(
        uint256 songId,
        bool canBePurchased
    )
        external
        senderIsArtistId(songDB.getPrincipalArtistId(songId))
        songIdExists(songId)
    {
        songDB.changePurchaseability(songId, canBePurchased);
    }

    function changeSongPrice(
        uint256 songId,
        uint256 price
    )
        external
        senderIsArtistId(songDB.getPrincipalArtistId(songId))
        songIdExists(songId)
    {
        songDB.changePrice(songId, price);
    }

    function purchaseSong(uint256 songId) external {
        uint256 userID = userDB.getId(msg.sender);
        songDB.purchase(songId, userID);
        userDB.addSong(userID, songId);

        _executePayment(
            userID,
            songDB.getPrincipalArtistId(songId),
            songDB.getPrice(songId)
        );

        emit EventsLib.SongPurchased(songId, userID, songDB.getPrice(songId));
    }

    function giftSong(
        uint256 songId,
        uint256 toUserId
    ) external senderIsArtistId(songDB.getPrincipalArtistId(songId)) {

        songDB.gift(songId, toUserId);
        userDB.addSong(toUserId, songId);

        emit EventsLib.SongGifted(songId, toUserId);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Album Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    function registerAlbum(
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory songIDs,
        uint256 price,
        bool canBePurchased,
        bool isASpecialEdition,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external senderIsArtistId(principalArtistId) returns (uint256) {
        if (bytes(title).length == 0) revert ErrorsLib.TitleCannotBeEmpty();

        if (isASpecialEdition) {
            if (maxSupplySpecialEdition == 0)
                revert ErrorsLib.MaxSupplyMustBeGreaterThanZero();

            if (bytes(specialEditionName).length == 0)
                revert ErrorsLib.SpecialEditionNameCannotBeEmpty();
        }

        for (uint256 i = 0; i < songIDs.length; i++) {
            if (!songDB.exists(songIDs[i])) revert();
            if (songDB.getPrincipalArtistId(songIDs[i]) != principalArtistId)
                revert();
        }

        return
            albumDB.register(
                title,
                principalArtistId,
                metadataURI,
                songIDs,
                price,
                canBePurchased,
                isASpecialEdition,
                specialEditionName,
                maxSupplySpecialEdition
            );
    }

    function changeAlbumFullData(
        uint256 id,
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory musicIds,
        uint256 price,
        bool canBePurchased,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external senderIsArtistId(principalArtistId) {
        if (albumDB.getPrincipalArtistId(id) != principalArtistId)
            revert ErrorsLib.SenderIsNotPrincipalArtist();

        if (
            albumDB.isAnSpecialEdition(id) &&
            maxSupplySpecialEdition <= albumDB.getTotalSupply(id)
        ) revert ErrorsLib.MustBeGreaterThanCurrent();

        bool isSpecialEdition = albumDB.isAnSpecialEdition(id);

        albumDB.change(
            id,
            title,
            principalArtistId,
            metadataURI,
            musicIds,
            price,
            canBePurchased,
            isSpecialEdition,
            isSpecialEdition ? specialEditionName : "",
            isSpecialEdition ? maxSupplySpecialEdition : 0
        );
    }

    function changeAlbumPurchaseability(
        uint256 principalArtistId,
        uint256 albumId,
        bool canBePurchased
    ) external senderIsArtistId(principalArtistId) {
        if (albumDB.getPrincipalArtistId(albumId) != principalArtistId)
            revert ErrorsLib.SenderIsNotPrincipalArtist();

        albumDB.changePurchaseability(albumId, canBePurchased);
    }

    function changeAlbumPrice(
        uint256 principalArtistId,
        uint256 albumId,
        uint256 price
    ) external senderIsArtistId(principalArtistId) {
        if (albumDB.getPrincipalArtistId(albumId) != principalArtistId)
            revert ErrorsLib.SenderIsNotPrincipalArtist();

        albumDB.changePrice(albumId, price);
    }

    function purchaseAlbum(uint256 albumId) external {
        uint256 userID = userDB.getId(msg.sender);

        uint[] memory listOfSong = albumDB.purchase(albumId, userID);
        userDB.addSongs(userID, listOfSong);

        _executePayment(
            userID,
            albumDB.getPrincipalArtistId(albumId),
            albumDB.getPrice(albumId)
        );

        emit EventsLib.AlbumPurchased(
            albumId,
            userID,
            albumDB.getPrice(albumId)
        );
    }

    function giftAlbum(
        uint256 artistId,
        uint256 albumId,
        uint256 toUserId
    ) external senderIsArtistId(artistId) {
        if (albumDB.getPrincipalArtistId(albumId) != artistId)
            revert ErrorsLib.SenderIsNotPrincipalArtist();

        uint[] memory listOfSong = albumDB.gift(albumId, toUserId);
        userDB.addSongs(toUserId, listOfSong);

        emit EventsLib.AlbumGifted(albumId, toUserId);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Admin Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    function setDatabaseAddresses(
        address _dbalbum,
        address _dbartist,
        address _dbsong,
        address _dbuser
    ) external onlyOwner {
        if (breaker.addressSetup != bytes1(0x00))
            revert ErrorsLib.AddressSetupAlreadyDone();

        dbAddress.album = _dbalbum;
        dbAddress.artist = _dbartist;
        dbAddress.song = _dbsong;
        dbAddress.user = _dbuser;

        songDB = ISongDB(_dbsong);
        albumDB = IAlbumDB(_dbalbum);
        artistDB = IArtistDB(_dbartist);
        userDB = IUserDB(_dbuser);
        breaker.addressSetup = bytes1(0x01);
    }

    function addPercentageFee(uint16 _percentageFee) external onlyOwner {
        /// @dev percentage fee is in basis points (100 = 1%)
        if (_percentageFee > 10000) revert(); // max 100%
        percentageFee = _percentageFee;
    }

    function proposeStablecoinAddressChange(
        address newStablecoinAddress
    ) external onlyOwner {
        if (newStablecoinAddress == address(0)) revert();
        stablecoin.proposed = newStablecoinAddress;
        stablecoin.timeToExecute = block.timestamp + 1 days;
    }

    function cancelStablecoinAddressChange() external onlyOwner {
        stablecoin.proposed = address(0);
        stablecoin.timeToExecute = 0;
    }

    function executeStablecoinAddressChange() external onlyOwner {
        if (
            stablecoin.proposed == address(0) ||
            block.timestamp < stablecoin.timeToExecute
        ) revert();
        stablecoin.current = stablecoin.proposed;
        stablecoin.proposed = address(0);
        stablecoin.timeToExecute = 0;
    }

    function migrateOrchestrator(
        address orchestratorAddressToMigrate,
        address accountToTransferCollectedFees
    ) external onlyOwner {
        if (orchestratorAddressToMigrate == address(0)) revert();

        albumDB.transferOwnership(orchestratorAddressToMigrate);
        artistDB.transferOwnership(orchestratorAddressToMigrate);
        songDB.transferOwnership(orchestratorAddressToMigrate);
        userDB.transferOwnership(orchestratorAddressToMigrate);

        if (amountCollectedInFees > 0)
            IERC20(stablecoin.current).transfer(
                accountToTransferCollectedFees,
                amountCollectedInFees
            );

        uint256 balance = IERC20(stablecoin.current).balanceOf(address(this));
        IERC20(stablecoin.current).transfer(
            orchestratorAddressToMigrate,
            balance
        );

        newOrchestratorAddress = orchestratorAddressToMigrate;
    }

    function withdrawCollectedFees(
        address to,
        uint256 amount
    ) external onlyOwner {
        if (amountCollectedInFees < amount) revert();
        amountCollectedInFees -= amount;
        IERC20(stablecoin.current).transfer(to, amount);
    }

    function giveCollectedFeesToArtist(
        uint256 artistId,
        uint256 amount
    ) external onlyOwner artistIdExists(artistId) {
        if (amountCollectedInFees < amount) revert();

        amountCollectedInFees -= amount;
        artistDB.addBalance(artistId, amount);
    }

    function giveCollectedFeesToUser(
        uint256 userId,
        uint256 amount
    ) external onlyOwner userIdExists(userId) {
        if (amountCollectedInFees < amount) revert();

        amountCollectedInFees -= amount;
        userDB.addBalance(userId, amount);
    }

    function getAmountCollectedInFees()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return amountCollectedInFees;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Getter Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    function getPriceWithFee(
        uint256 netPrice
    ) public view returns (uint256 totalPrice, uint256 fee) {
        if (netPrice == 0) return (0, 0);
        fee = (netPrice * uint256(percentageFee)) / 10000;
        return (netPrice + fee, fee);
    }

    function getAlbumDBAddress() external view returns (address) {
        return dbAddress.album;
    }

    function getArtistDBAddress() external view returns (address) {
        return dbAddress.artist;
    }

    function getSongDBAddress() external view returns (address) {
        return dbAddress.song;
    }

    function getUserDBAddress() external view returns (address) {
        return dbAddress.user;
    }

    function getDbAddresses()
        external
        view
        returns (StructsLib.DataBaseList memory)
    {
        return dbAddress;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Internal Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    function _executePayment(
        uint256 userId,
        uint256 artistId,
        uint256 price
    ) internal {
        if (price != 0) {
            uint256 userBalance = userDB.getBalance(userId);
            (uint256 totalPrice, uint256 calculatedFee) = getPriceWithFee(
                price
            );
            if (userBalance < totalPrice)
                revert ErrorsLib.InsufficientBalance();

            userDB.deductBalance(userId, totalPrice);
            artistDB.addBalance(artistId, price);
            amountCollectedInFees += calculatedFee;
        }
    }
}

/****************************************
You like snooping around code, don't you?
  ⠄⠄⢸⠃⠄⠛⠉⠄⣤⣤⣤⣤⣤⣄⠉⠙⠻⣿⣿⣿⣿⡇⣶⡄⢢⢻⣿⣿⣮⡛   
  ⠄⠄⠘⢀⣠⣾⠄⠘⠋⠉⠉⠛⠻⢿⣦⡲⣄⠈⠻⣿⣇⣣⠹⣯⣄⣦⡙⢿⣿⣿
  ⢀⡎⠄⣾⠋⠄⠄⠄⣠⣤⣤⣤⣤⣄⠈⠙⣍⢳⠄⠘⣿⡐⠁⢉⣁⣀⡀⠄⠙⠿
  ⡼⠄⡆⡇⢀⣤⡆⣿⣿⣿⣿⣿⣿⣿⣷⡘⣿⣷⣄⡀⢹⡇⣾⣿⣿⣿⣿⡇⣄⢠
  ⡇⠄⢿⡔⢿⣿⡇⢿⣿⣿⣿⠿⠿⢿⣿⠇⣿⣿⣿⠇⢈⣁⡻⢿⣿⣀⠈⣱⢏⣾
  ⢣⠄⢆⢩⣮⣿⣿⣄⠻⣿⣷⣤⣤⡴⢋⣴⣿⣿⡟⠄⢸⣿⣿⣷⣶⣶⠾⢫⣪⠅
  ⠘⣆⠈⢑⣘⣿⣿⣿⣷⣶⣤⣤⣴⣾⣿⣿⣿⣿⠃⢀⣿⣿⣿⣿⣿⣿⣿⣿⢇⣴
  ⠄⠘⢦⡈⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⢁⣀⣉⣉⣹⣿⣿⣿⣿⠿⡃⠪⣶
  ⠄⠄⠄⠙⠢⢄⡈⠛⠻⠿⠿⠿⠟⠛⠋⣀⠰⣿⣿⣿⣿⡿⠿⡛⠉⡄⠄⠄⠄⣀
  ⠄⠄⠄⠄⢀⡾⢉⣁⠄⠄⠄⠲⠂⢂⠋⠄⠛⠒⠉⠉⠑⠒⠉⠒⠒⡧⠤⠖⢋⣡ <- that's you reading all the code BTW
🮋🮋🮋🮋 Made with ❤️ by 11:11 Labs 🮋🮋🮋🮋  
*****************************************/
