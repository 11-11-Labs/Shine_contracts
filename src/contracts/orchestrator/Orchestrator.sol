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

import {ISongDB} from "@shine/interface/ISongDB.sol";
import {IAlbumDB} from "@shine/interface/IAlbumDB.sol";
import {IArtistDB} from "@shine/interface/IArtistDB.sol";
import {IUserDB} from "@shine/interface/IUserDB.sol";
import {Ownable} from "@solady/auth/Ownable.sol";
import {IERC20} from "@shine/interface/IERC20.sol";
import {ErrorsLib} from "@shine/contracts/orchestrator/library/ErrorsLib.sol";
import {StructsLib} from "@shine/contracts/orchestrator/library/StructsLib.sol";
import {EventsLib} from "@shine/contracts/orchestrator/library/EventsLib.sol";

contract Orchestrator is Ownable {
    address private newOrchestratorAddress;
    uint256 private amountCollectedInFees;
    StructsLib.AddressProposal private stablecoin;
    StructsLib.DataBaseList private dbAddress;
    StructsLib.Breakers private breaker;
    uint16 private percentageFee;

    constructor(address initialOwner, address _stablecoinAddress) {
        _initializeOwner(initialOwner);
        stablecoin.current = _stablecoinAddress;
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Funds Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    function depositFunds(uint256 userId, uint256 amount) external {
        if (IUserDB(dbAddress.user).getAddress(userId) != msg.sender)
            revert ErrorsLib.AddressIsNotOwnerOfUserId();

        IERC20(stablecoin.current).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        IUserDB(dbAddress.user).addBalance(userId, amount);
    }

    function giftFunds(uint256 toUserId, uint256 amount) external {
        if (!IUserDB(dbAddress.user).exists(toUserId))
            revert ErrorsLib.UserIdDoesNotExist();

        IERC20(stablecoin.current).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        IUserDB(dbAddress.user).addBalance(toUserId, amount);
    }

    function withdrawFunds(
        bool isArtist,
        uint256 userId,
        uint256 amount
    ) external {
        if (isArtist) {
            if (IArtistDB(dbAddress.artist).getAddress(userId) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfArtistId();

            if (IArtistDB(dbAddress.artist).getBalance(userId) < amount)
                revert ErrorsLib.InsufficientBalance();

            IArtistDB(dbAddress.artist).deductBalance(userId, amount);
        } else {
            if (IUserDB(dbAddress.user).getAddress(userId) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfUserId();

            if (IUserDB(dbAddress.user).getBalance(userId) < amount)
                revert ErrorsLib.InsufficientBalance();

            IUserDB(dbAddress.user).deductBalance(userId, amount);
        }

        IERC20(stablecoin.current).transfer(msg.sender, amount);
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 User/Artist Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    function register(
        bool isArtist,
        string memory name,
        string memory metadataURI,
        address artistAddress
    ) external returns (uint256) {
        if (isArtist) {
            return
                IArtistDB(dbAddress.artist).register(
                    name,
                    metadataURI,
                    artistAddress
                );
        } else {
            return
                IUserDB(dbAddress.user).register(
                    name,
                    metadataURI,
                    artistAddress
                );
        }
    }

    function chnageBasicData(
        bool isArtist,
        uint256 id,
        string memory name,
        string memory metadataURI
    ) external {
        if (isArtist) {
            if (IArtistDB(dbAddress.artist).getAddress(id) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfArtistId();

            IArtistDB(dbAddress.artist).changeBasicData(id, name, metadataURI);
        } else {
            if (IUserDB(dbAddress.user).getAddress(id) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfUserId();

            IUserDB(dbAddress.user).changeBasicData(id, name, metadataURI);
        }
    }

    function changeAddress(
        bool isArtist,
        uint256 id,
        address newAddress
    ) external {
        if (isArtist) {
            if (IArtistDB(dbAddress.artist).getAddress(id) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfArtistId();

            IArtistDB(dbAddress.artist).changeAddress(id, newAddress);
        } else {
            if (IUserDB(dbAddress.user).getAddress(id) != msg.sender)
                revert ErrorsLib.AddressIsNotOwnerOfUserId();

            IUserDB(dbAddress.user).changeAddress(id, newAddress);
        }
    }

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Song Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    function registerSong(
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external returns (uint256) {
        if (!IArtistDB(dbAddress.artist).exists(principalArtistId))
            revert ErrorsLib.ArtistIdDoesNotExist(principalArtistId);

        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert ErrorsLib.AddressIsNotOwnerOfArtistId();

        if (artistIDs.length > 0) {
            for (uint256 i = 0; i < artistIDs.length; i++) {
                if (!IArtistDB(dbAddress.artist).exists(artistIDs[i]))
                    revert ErrorsLib.ArtistIdDoesNotExist(artistIDs[i]);
            }
        }

        if (bytes(title).length == 0) revert ErrorsLib.TitleCannotBeEmpty();

        return
            ISongDB(dbAddress.song).register(
                title,
                principalArtistId,
                artistIDs,
                mediaURI,
                metadataURI,
                canBePurchased,
                price
            );
    }

    function changeSongFullData(
        uint256 id,
        string memory title,
        uint256 principalArtistId,
        uint256[] memory artistIDs,
        string memory mediaURI,
        string memory metadataURI,
        bool canBePurchased,
        uint256 price
    ) external {
        if (!IArtistDB(dbAddress.artist).exists(principalArtistId))
            revert ErrorsLib.ArtistIdDoesNotExist(principalArtistId);

        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert ErrorsLib.SenderIsNotPrincipalArtist();

        if (!ISongDB(dbAddress.song).exists(id))
            revert ErrorsLib.SongIdDoesNotExist(id);

        if (
            ISongDB(dbAddress.song).getPrincipalArtistId(id) !=
            principalArtistId
        ) revert ErrorsLib.ArtistIdIsNotPrincipalArtistIdOfSong();

        ISongDB(dbAddress.song).change(
            id,
            title,
            principalArtistId,
            artistIDs,
            mediaURI,
            metadataURI,
            canBePurchased,
            price
        );
    }

    function changeSongPurchaseability(
        uint256 id,
        bool canBePurchased
    ) external {
        uint256 principalArtistId = ISongDB(dbAddress.song)
            .getPrincipalArtistId(id);
        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert ErrorsLib.SenderIsNotPrincipalArtist();

        ISongDB(dbAddress.song).changePurchaseability(id, canBePurchased);
    }

    function changeSongPrice(uint256 id, uint256 price) external {
        uint256 principalArtistId = ISongDB(dbAddress.song)
            .getPrincipalArtistId(id);
        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert ErrorsLib.SenderIsNotPrincipalArtist();

        ISongDB(dbAddress.song).changePrice(id, price);
    }

    function purchaseSong(uint256 songId) external payable {
        uint256 userID = IUserDB(dbAddress.user).getId(msg.sender);
        ISongDB(dbAddress.song).purchase(songId, userID);
        IUserDB(dbAddress.user).addSong(userID, songId);

        _executePayment(
            userID,
            ISongDB(dbAddress.song).getPrincipalArtistId(songId),
            ISongDB(dbAddress.song).getPrice(songId)
        );

        emit EventsLib.SongPurchased(
            songId,
            userID,
            ISongDB(dbAddress.song).getPrice(songId)
        );
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
    ) external returns (uint256) {
        if (!IArtistDB(dbAddress.artist).exists(principalArtistId))
            revert ErrorsLib.ArtistIdDoesNotExist(principalArtistId);
        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert ErrorsLib.SenderIsNotPrincipalArtist();

        if (bytes(title).length == 0) revert ErrorsLib.TitleCannotBeEmpty();

        if (isASpecialEdition) {
            if (maxSupplySpecialEdition == 0)
                revert ErrorsLib.MaxSupplyMustBeGreaterThanZero();

            if (bytes(specialEditionName).length == 0)
                revert ErrorsLib.SpecialEditionNameCannotBeEmpty();
        }

        for (uint256 i = 0; i < songIDs.length; i++) {
            if (!ISongDB(dbAddress.song).exists(songIDs[i])) revert();
            if (
                ISongDB(dbAddress.song).getPrincipalArtistId(songIDs[i]) !=
                principalArtistId
            ) revert();
        }

        return
            IAlbumDB(dbAddress.album).register(
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

    function changeAlbumNonSpecialFullData(
        uint256 id,
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory musicIds,
        uint256 price,
        bool canBePurchased
    ) external {
        if (!IArtistDB(dbAddress.artist).exists(principalArtistId))
            revert ErrorsLib.ArtistIdDoesNotExist(principalArtistId);

        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert ErrorsLib.SenderIsNotPrincipalArtist();

        if (IAlbumDB(dbAddress.album).isAnSpecialEdition(id))
            revert ErrorsLib.AlbumIsASpecialEdition();

        IAlbumDB(dbAddress.album).change(
            id,
            title,
            principalArtistId,
            metadataURI,
            musicIds,
            price,
            canBePurchased,
            false,
            "",
            0
        );
    }

    function changeAlbumSpecialFullData(
        uint256 id,
        string memory title,
        uint256 principalArtistId,
        string memory metadataURI,
        uint256[] memory musicIds,
        uint256 price,
        bool canBePurchased,
        string memory specialEditionName,
        uint256 maxSupplySpecialEdition
    ) external {
        if (!IArtistDB(dbAddress.artist).exists(principalArtistId))
            revert ErrorsLib.ArtistIdDoesNotExist(principalArtistId);

        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert ErrorsLib.SenderIsNotPrincipalArtist();

        if (!IAlbumDB(dbAddress.album).isAnSpecialEdition(id))
            revert ErrorsLib.AlbumIsNotASpecialEdition();

        if (
            maxSupplySpecialEdition <=
            IAlbumDB(dbAddress.album).getTotalSupply(id)
        ) revert ErrorsLib.MustBeGreaterThanCurrent();

        IAlbumDB(dbAddress.album).change(
            id,
            title,
            principalArtistId,
            metadataURI,
            musicIds,
            price,
            canBePurchased,
            true,
            specialEditionName,
            maxSupplySpecialEdition
        );
    }

    function changeAlbumPurchaseability(
        uint256 id,
        bool canBePurchased
    ) external {
        uint256 principalArtistId = IAlbumDB(dbAddress.album)
            .getPrincipalArtistId(id);
        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert ErrorsLib.SenderIsNotPrincipalArtist();

        IAlbumDB(dbAddress.album).changePurchaseability(id, canBePurchased);
    }

    function changeAlbumPrice(uint256 id, uint256 price) external {
        uint256 principalArtistId = IAlbumDB(dbAddress.album)
            .getPrincipalArtistId(id);
        if (
            IArtistDB(dbAddress.artist).getAddress(principalArtistId) !=
            msg.sender
        ) revert ErrorsLib.SenderIsNotPrincipalArtist();

        IAlbumDB(dbAddress.album).changePrice(id, price);
    }

    function purchaseAlbum(uint256 albumId) external payable {
        uint256 userID = IUserDB(dbAddress.user).getId(msg.sender);

        uint[] memory listOfSong = IAlbumDB(dbAddress.album).purchase(
            albumId,
            userID
        );
        IUserDB(dbAddress.user).addSongs(userID, listOfSong);

        _executePayment(
            userID,
            IAlbumDB(dbAddress.album).getPrincipalArtistId(albumId),
            IAlbumDB(dbAddress.album).getPrice(albumId)
        );

        emit EventsLib.AlbumPurchased(
            albumId,
            userID,
            IAlbumDB(dbAddress.album).getPrice(albumId)
        );
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

        IAlbumDB(dbAddress.album).transferOwnership(
            orchestratorAddressToMigrate
        );
        IArtistDB(dbAddress.artist).transferOwnership(
            orchestratorAddressToMigrate
        );
        ISongDB(dbAddress.song).transferOwnership(orchestratorAddressToMigrate);
        IUserDB(dbAddress.user).transferOwnership(orchestratorAddressToMigrate);

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

    //🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮶 Internal Functions 🮵🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋

    function _executePayment(
        uint256 userId,
        uint256 artistId,
        uint256 price
    ) internal {
        if (price != 0) {
            uint256 userBalance = IUserDB(dbAddress.user).getBalance(userId);
            (uint256 totalPrice, uint256 calculatedFee) = getPriceWithFee(
                price
            );
            if (userBalance < totalPrice)
                revert ErrorsLib.InsufficientBalance();

            IUserDB(dbAddress.user).deductBalance(userId, totalPrice);
            IUserDB(dbAddress.user).addBalance(artistId, price);
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
