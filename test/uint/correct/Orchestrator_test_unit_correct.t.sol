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
}
