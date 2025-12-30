// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "../../Constants.sol";

import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {ArtistDB} from "@shine/contracts/database/ArtistDB.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";
import {Orchestrator} from "@shine/contracts/Orchestrator.sol";

contract Orchestrator_test_unit_correct is Constants {
    function executeBeforeSetUp() internal override {
        orchestrator = new Orchestrator(
            SUDO.Address,
            ADMIN.Address,
            API.Address
        );

        userDB = new UserDB(address(orchestrator));
        songDB = new SongDB(address(orchestrator));
        albumDB = new AlbumDB(address(orchestrator));
        artistDB = new ArtistDB(address(orchestrator));

        vm.prank(SUDO.Address);

        orchestrator._setDatabaseAddresses(
            address(albumDB),
            address(artistDB),
            address(songDB),
            address(userDB)
        );
        vm.stopPrank();
    }

    function test_unit_correct_Orchestrator__registerArtist() public {
        vm.startPrank(API.Address);
        uint256 assignedId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        vm.stopPrank();

        assertEq(assignedId, 1, "Assigned ID should be 1 for the first artist");
        assertEq(
            artistDB.getMetadata(assignedId).Name,
            "Artist Name",
            "Artist name should match the registered name"
        );
        assertEq(
            artistDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "Metadata URI should match the registered URI"
        );
        assertEq(
            artistDB.getMetadata(assignedId).Address,
            ARTIST.Address,
            "Artist address should match the registered address"
        );
    }

    function test_unit_correct_Orchestrator__chnageDataOfArtist__sameAddress()
        public
    {
        vm.startPrank(API.Address);
        uint256 assignedId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        orchestrator.chnageDataOfArtist(
            assignedId,
            "New Artist Name",
            "ipfs://newMetadataURI",
            ARTIST.Address
        );
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Name,
            "New Artist Name",
            "Artist name should be updated to the new name"
        );
        assertEq(
            artistDB.getMetadata(assignedId).MetadataURI,
            "ipfs://newMetadataURI",
            "Metadata URI should be updated to the new URI"
        );
        assertEq(
            artistDB.getMetadata(assignedId).Address,
            ARTIST.Address,
            "Artist address should remain unchanged"
        );
    }

    function test_unit_correct_Orchestrator__chnageDataOfArtist__diferentAddress()
        public
    {
        vm.startPrank(API.Address);
        uint256 assignedId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        orchestrator.chnageDataOfArtist(
            assignedId,
            "New Artist Name",
            "ipfs://newMetadataURI",
            address(67)
        );
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Name,
            "New Artist Name",
            "Artist name should be updated to the new name"
        );
        assertEq(
            artistDB.getMetadata(assignedId).MetadataURI,
            "ipfs://newMetadataURI",
            "Metadata URI should be updated to the new URI"
        );
        assertEq(
            artistDB.getMetadata(assignedId).Address,
            address(67),
            "Artist address should be updated to the new address"
        );
    }

    function test_unit_correct_Orchestrator__registerUser() public {
        vm.startPrank(API.Address);
        uint256 assignedId = orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        vm.stopPrank();
        assertEq(assignedId, 1, "Assigned ID should be 1 for the first user");
        assertEq(
            userDB.getMetadata(assignedId).username,
            "Username",
            "Username should match the registered username"
        );
        assertEq(
            userDB.getMetadata(assignedId).metadataURI,
            "ipfs://metadataURI",
            "Metadata URI should match the registered URI"
        );
        assertEq(
            userDB.getMetadata(assignedId).userAddress,
            USER.Address,
            "User address should match the registered address"
        );
    }

    function test_unit_correct_Orchestrator__changeDataOfUser__sameAddress()
        public
    {
        vm.startPrank(API.Address);
        uint256 assignedId = orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        orchestrator.changeDataOfUser(
            assignedId,
            "New Username",
            "ipfs://newMetadataURI",
            USER.Address
        );
        vm.stopPrank();

        assertEq(
            userDB.getMetadata(assignedId).username,
            "New Username",
            "Username should be updated to the new username"
        );
        assertEq(
            userDB.getMetadata(assignedId).metadataURI,
            "ipfs://newMetadataURI",
            "Metadata URI should be updated to the new URI"
        );
        assertEq(
            userDB.getMetadata(assignedId).userAddress,
            USER.Address,
            "User address should remain unchanged"
        );
    }

    function test_unit_correct_Orchestrator__changeDataOfUser__diferentAddress()
        public
    {
        vm.startPrank(API.Address);
        uint256 assignedId = orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        orchestrator.changeDataOfUser(
            assignedId,
            "New Username",
            "ipfs://newMetadataURI",
            address(89)
        );
        vm.stopPrank();

        assertEq(
            userDB.getMetadata(assignedId).username,
            "New Username",
            "Username should be updated to the new username"
        );
        assertEq(
            userDB.getMetadata(assignedId).metadataURI,
            "ipfs://newMetadataURI",
            "Metadata URI should be updated to the new URI"
        );
        assertEq(
            userDB.getMetadata(assignedId).userAddress,
            address(89),
            "User address should be updated to the new address"
        );
    }

    function test_unit_correct_Orchestrator__registerSong() public {
        vm.startPrank(API.Address);

        /*uint256 userId =*/ orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        uint256 artistId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        uint256[] memory artistIDs = new uint256[](0);
        uint256 songId = orchestrator.registerSong(
            artistId,
            "Song Title",
            artistIDs,
            "ipfs://songMediaURI",
            "ipfs://songMetadataURI",
            false,
            180
        );

        vm.stopPrank();

        assertEq(songId, 1, "Assigned ID should be 1 for the first song");
        assertEq(
            songDB.getMetadata(songId).title,
            "Song Title",
            "Song title should match the registered title"
        );
        assertEq(
            artistIDs,
            songDB.getMetadata(songId).artistIDs,
            "Artist IDs should match the registered artist IDs"
        );
        assertEq(
            songDB.getMetadata(songId).mediaURI,
            "ipfs://songMediaURI",
            "Media URI should match the registered URI"
        );
        assertEq(
            songDB.getMetadata(songId).metadataURI,
            "ipfs://songMetadataURI",
            "Metadata URI should match the registered URI"
        );
        assertFalse(
            songDB.getMetadata(songId).canBePurchased,
            "Song should be not purchasable"
        );
        assertEq(
            songDB.getMetadata(songId).price,
            180,
            "Price should match the registered price"
        );
    }

    function test_unit_correct_Orchestrator__changeDataOfSong() public {
        vm.startPrank(API.Address);

        /*uint256 userId =*/ orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        uint256 artistId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        uint256[] memory artistIDs = new uint256[](0);
        uint256 songId = orchestrator.registerSong(
            artistId,
            "Song Title",
            artistIDs,
            "ipfs://songMediaURI",
            "ipfs://songMetadataURI",
            false,
            180
        );
        uint256[] memory artistIDsNew = new uint256[](2);
        artistIDsNew[0] = 67;
        artistIDsNew[1] = 777;
        orchestrator.changeDataOfSong(
            songId,
            "New Song Title",
            artistId,
            artistIDsNew,
            "ipfs://newSongMediaURI",
            "ipfs://newSongMetadataURI",
            true,
            250
        );

        vm.stopPrank();

        assertEq(
            songDB.getMetadata(songId).title,
            "New Song Title",
            "Song title should be updated to the new title"
        );
        assertEq(
            artistIDsNew,
            songDB.getMetadata(songId).artistIDs,
            "Artist IDs should be updated to the new artist IDs"
        );
        assertEq(
            songDB.getMetadata(songId).mediaURI,
            "ipfs://newSongMediaURI",
            "Media URI should be updated to the new URI"
        );
        assertEq(
            songDB.getMetadata(songId).metadataURI,
            "ipfs://newSongMetadataURI",
            "Metadata URI should be updated to the new URI"
        );
        assertTrue(
            songDB.getMetadata(songId).canBePurchased,
            "Song should be purchasable after update"
        );
        assertEq(
            songDB.getMetadata(songId).price,
            250,
            "Price should be updated to the new price"
        );
    }

    function test_unit_correct_Orchestrator__changePurchaseabilityAndPriceOfSong()
        public
    {
        vm.startPrank(API.Address);

        /*uint256 userId =*/ orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        uint256 artistId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        uint256[] memory artistIDs = new uint256[](0);
        uint256 songId = orchestrator.registerSong(
            artistId,
            "Song Title",
            artistIDs,
            "ipfs://songMediaURI",
            "ipfs://songMetadataURI",
            false,
            180
        );
        orchestrator.changePurchaseabilityAndPriceOfSong(
            songId,
            artistId,
            true,
            250
        );

        vm.stopPrank();

        assertTrue(
            songDB.getMetadata(songId).canBePurchased,
            "Song should be purchasable after update"
        );
        assertEq(
            songDB.getMetadata(songId).price,
            250,
            "Price should be updated to the new price"
        );
    }

    function test_unit_correct_Orchestrator__registerAlbum() public {
        vm.startPrank(API.Address);

        /*uint256 userId =*/ orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        uint256 artistId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        uint256[] memory artistIDs = new uint256[](0);
        uint256 songId = orchestrator.registerSong(
            artistId,
            "Song Title",
            artistIDs,
            "ipfs://songMediaURI",
            "ipfs://songMetadataURI",
            false,
            180
        );

        uint256[] memory songIDs = new uint256[](1);
        songIDs[0] = songId;

        uint256 albumId = orchestrator.registerAlbum(
            artistId,
            "Album Title",
            "ipfs://albumMetadataURI",
            songIDs,
            500,
            true,
            false,
            "",
            0
        );

        vm.stopPrank();

        assertEq(albumId, 1, "Assigned ID should be 1 for the first album");
        assertEq(
            albumDB.getMetadata(albumId).Title,
            "Album Title",
            "Album title should match the registered title"
        );
        assertEq(
            albumDB.getMetadata(albumId).PrincipalArtistId,
            artistId,
            "Principal artist ID should match the registered artist ID"
        );
        assertEq(
            albumDB.getMetadata(albumId).MetadataURI,
            "ipfs://albumMetadataURI",
            "Metadata URI should match the registered URI"
        );
        assertEq(
            songIDs,
            albumDB.getMetadata(albumId).MusicIds,
            "Song IDs should match the registered song IDs"
        );
        assertTrue(
            albumDB.isPurschaseable(albumId),
            "Album should be purchasable"
        );
        assertEq(
            albumDB.getMetadata(albumId).Price,
            500,
            "Price should match the registered price"
        );
        assertFalse(
            albumDB.getMetadata(albumId).IsASpecialEdition,
            "Should not be a special edition"
        );
        assertEq(
            albumDB.getMetadata(albumId).SpecialEditionName,
            "",
            "Special edition name should be empty"
        );
        assertEq(
            albumDB.getMetadata(albumId).MaxSupplySpecialEdition,
            0,
            "Max supply for special edition should be 0"
        );
    }

    function test_unit_correct_Orchestrator__changeDataOfAlbum() public {
        vm.startPrank(API.Address);

        /*uint256 userId =*/ orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        uint256 artistId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        uint256[] memory artistIDs = new uint256[](0);
        uint256 songId = orchestrator.registerSong(
            artistId,
            "Song Title",
            artistIDs,
            "ipfs://songMediaURI",
            "ipfs://songMetadataURI",
            false,
            180
        );

        uint256[] memory songIDs = new uint256[](1);
        songIDs[0] = songId;

        uint256 albumId = orchestrator.registerAlbum(
            artistId,
            "Album Title",
            "ipfs://albumMetadataURI",
            songIDs,
            500,
            true,
            false,
            "",
            0
        );

        orchestrator.changeDataOfAlbum(
            albumId,
            "New Album Title",
            artistId,
            "ipfs://newAlbumMetadataURI",
            songIDs,
            1000,
            false,
            true,
            "Special Edition Name",
            50
        );

        vm.stopPrank();

        assertEq(
            albumDB.getMetadata(albumId).Title,
            "New Album Title",
            "Album title should be updated to the new title"
        );
        assertEq(
            albumDB.getMetadata(albumId).PrincipalArtistId,
            artistId,
            "Principal artist ID should remain unchanged"
        );
        assertEq(
            albumDB.getMetadata(albumId).MetadataURI,
            "ipfs://newAlbumMetadataURI",
            "Metadata URI should be updated to the new URI"
        );
        assertEq(
            songIDs,
            albumDB.getMetadata(albumId).MusicIds,
            "Song IDs should remain unchanged"
        );
        assertFalse(
            albumDB.isPurschaseable(albumId),
            "Album should not be purchasable after update"
        );
        assertEq(
            albumDB.getMetadata(albumId).Price,
            1000,
            "Price should be updated to the new price"
        );
        assertTrue(
            albumDB.getMetadata(albumId).IsASpecialEdition,
            "Should be a special edition after update"
        );
        assertEq(
            albumDB.getMetadata(albumId).SpecialEditionName,
            "Special Edition Name",
            "Special edition name should be updated"
        );
        assertEq(
            albumDB.getMetadata(albumId).MaxSupplySpecialEdition,
            50,
            "Max supply for special edition should be updated"
        );
    }

    function test_unit_correct_Orchestrator__changePurchaseabilityAndPriceOfAlbum()
        public
    {
        vm.startPrank(API.Address);

        /*uint256 userId =*/ orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        uint256 artistId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        uint256[] memory artistIDs = new uint256[](0);
        uint256 songId = orchestrator.registerSong(
            artistId,
            "Song Title",
            artistIDs,
            "ipfs://songMediaURI",
            "ipfs://songMetadataURI",
            false,
            180
        );

        uint256[] memory songIDs = new uint256[](1);
        songIDs[0] = songId;

        uint256 albumId = orchestrator.registerAlbum(
            artistId,
            "Album Title",
            "ipfs://albumMetadataURI",
            songIDs,
            500,
            true,
            false,
            "",
            0
        );

        orchestrator.changePurchaseabilityAndPriceOfAlbum(
            albumId,
            artistId,
            false,
            1000
        );

        vm.stopPrank();

        assertFalse(
            albumDB.isPurschaseable(albumId),
            "Album should not be purchasable after update"
        );
        assertEq(
            albumDB.getMetadata(albumId).Price,
            1000,
            "Price should be updated to the new price"
        );
    }

    function test_unit_correct_Orchestrator__buySong() public {
        vm.startPrank(API.Address);

        uint256 userId = orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );

        orchestrator.addBalanceToUser(userId, 1000);

        uint256 artistId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        uint256[] memory artistIDs = new uint256[](0);
        uint256 songId = orchestrator.registerSong(
            artistId,
            "Song Title",
            artistIDs,
            "ipfs://songMediaURI",
            "ipfs://songMetadataURI",
            true,
            1000
        );

        orchestrator.buySong(userId, songId);

        vm.stopPrank();

        assertTrue(
            songDB.hasUserPurchased(songId, userId),
            "User should have purchased the song"
        );
        assertEq(
            userDB.getMetadata(userId).balance,
            0,
            "User balance should be deducted by the song price"
        );
        assertEq(
            artistDB.getMetadata(artistId).Balance,
            1000,
            "Artist balance should be increased by the song price"
        );
        uint256[] memory purchasedSongs = new uint256[](1);
        purchasedSongs[0] = songId;
        assertEq(
            userDB.getMetadata(userId).purchasedSongIds,
            purchasedSongs,
            "Song ID should be added to the user's purchased songs"
        );
    }

    function test_unit_correct_Orchestrator__buyAlbum() public {
        vm.startPrank(API.Address);

        uint256 userId = orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        uint256 artistId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        uint256[] memory artistIDs = new uint256[](0);
        uint256 songId = orchestrator.registerSong(
            artistId,
            "Song Title",
            artistIDs,
            "ipfs://songMediaURI",
            "ipfs://songMetadataURI",
            false,
            180
        );

        uint256[] memory songIDs = new uint256[](1);
        songIDs[0] = songId;

        uint256 albumId = orchestrator.registerAlbum(
            artistId,
            "Album Title",
            "ipfs://albumMetadataURI",
            songIDs,
            500,
            true,
            false,
            "",
            0
        );

        orchestrator.addBalanceToUser(userId, 1000);
        orchestrator.buyAlbum(userId, albumId);

        vm.stopPrank();

        assertTrue(
            albumDB.hasUserPurchased(albumId, userId),
            "User should have purchased the album"
        );
        assertEq(
            userDB.getMetadata(userId).balance,
            500,
            "User balance should be deducted by the album price"
        );
        assertEq(
            artistDB.getMetadata(artistId).Balance,
            500,
            "Artist balance should be increased by the album price"
        );
        uint256[] memory purchasedSongs = new uint256[](1);
        purchasedSongs[0] = songId;
        assertEq(
            userDB.getMetadata(userId).purchasedSongIds,
            purchasedSongs,
            "All song IDs from the album should be added to the user's purchased songs"
        );
    }

    function test_unit_correct_Orchestrator__addBalanceToUser() public {
        vm.startPrank(API.Address);

        uint256 userId = orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        orchestrator.addBalanceToUser(userId, 1000);
        vm.stopPrank();

        assertEq(
            userDB.getMetadata(userId).balance,
            1000,
            "User balance should be increased by the added amount"
        );
    }

    function test_unit_correct_Orchestrator__deductBalanceFromUser() public {
        vm.startPrank(API.Address);

        uint256 userId = orchestrator.registerUser(
            "Username",
            "ipfs://metadataURI",
            USER.Address
        );
        orchestrator.addBalanceToUser(userId, 1000);
        orchestrator.deductBalanceFromUser(userId, 500);
        vm.stopPrank();

        assertEq(
            userDB.getMetadata(userId).balance,
            500,
            "User balance should be decreased by the deducted amount"
        );
    }

    function test_unit_correct_Orchestrator__addBalanceToArtist() public {
        vm.startPrank(API.Address);

        uint256 artistId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        orchestrator.addBalanceToArtist(artistId, 2000);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(artistId).Balance,
            2000,
            "Artist balance should be increased by the added amount"
        );
    }

    function test_unit_correct_Orchestrator__deductBalanceFromArtist() public {
        vm.startPrank(API.Address);

        uint256 artistId = orchestrator.registerArtist(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        orchestrator.addBalanceToArtist(artistId, 2000);
        orchestrator.deductBalanceFromArtist(artistId, 750);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(artistId).Balance,
            1250,
            "Artist balance should be decreased by the deducted amount"
        );
    }




}
