// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "../../../Constants.sol";
import {SongDB} from "@shine/contracts/database/SongDB.sol";

contract Orchestrator_test_unit_correct_Song is Constants {
    AccountData ARTIST_3 = WILDCARD_ACCOUNT;
    uint256 USER_ID;
    uint256 ARTIST_1_ID;
    uint256 ARTIST_2_ID;
    uint256 ARTIST_3_ID;
    function executeBeforeSetUp() internal override {
        ARTIST_1_ID = _execute_orchestrator_register(
            true,
            "initial_artist",
            "https://arweave.net/initialArtistURI",
            ARTIST_1.Address
        );
        ARTIST_2_ID = _execute_orchestrator_register(
            true,
            "second_artist",
            "https://arweave.net/secondArtistURI",
            ARTIST_2.Address
        );
        ARTIST_3_ID = _execute_orchestrator_register(
            true,
            "third_artist",
            "https://arweave.net/thirdArtistURI",
            ARTIST_3.Address
        );
        USER_ID = _execute_orchestrator_register(
            false,
            "initial_user",
            "https://arweave.net/initialUserURI",
            USER.Address
        );
    }

    function test_unit_correct_registerSong() public {
        vm.startPrank(ARTIST_1.Address);

        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = ARTIST_2_ID;
        artistIDs[1] = ARTIST_3_ID;

        uint256 songID = orchestrator.registerSong(
            "Song Title",
            USER_ID,
            artistIDs,
            "https://arweave.net/mediaURI",
            "https://arweave.net/metadataURI",
            true,
            1000
        );

        vm.stopPrank();

        assertEq(
            songID,
            1,
            "Song ID should be 1 for the first registered song"
        );

        SongDB.Metadata memory song = songDB.getMetadata(songID);
        assertEq(song.Title, "Song Title", "Song title should match");
        assertEq(
            song.PrincipalArtistId,
            ARTIST_1_ID,
            "Principal artist ID should match"
        );
        assertEq(song.ArtistIDs, artistIDs, "Artist IDs should match");
        assertEq(
            song.MediaURI,
            "https://arweave.net/mediaURI",
            "Media URI should match"
        );
        assertEq(
            song.MetadataURI,
            "https://arweave.net/metadataURI",
            "Metadata URI should match"
        );
        assertTrue(song.CanBePurchased, "Song should be purchasable");
        assertEq(song.Price, 1000, "Song price should match");
        assertEq(
            song.TimesBought,
            0,
            "Times bought should be initialized to 0"
        );
        assertFalse(song.IsBanned, "Song should not be banned");
    }

    function test_unit_correct_changeSongFullData() public {
        uint256[] memory initialArtistIDs = new uint256[](1);
        initialArtistIDs[0] = ARTIST_2_ID;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Initial Song",
            ARTIST_1_ID,
            initialArtistIDs,
            "https://arweave.net/initialMediaURI",
            "https://arweave.net/initialMetadataURI",
            true,
            500
        );

        vm.startPrank(ARTIST_1.Address);
        uint256[] memory newArtistIDs = new uint256[](2);
        newArtistIDs[0] = ARTIST_2_ID;
        newArtistIDs[1] = ARTIST_3_ID;
        orchestrator.changeSongFullData(
            songID,
            "Updated Song",
            newArtistIDs,
            "https://arweave.net/updatedMediaURI",
            "https://arweave.net/updatedMetadataURI",
            false,
            1500
        );
        vm.stopPrank();

        SongDB.Metadata memory song = songDB.getMetadata(songID);
        assertEq(song.Title, "Updated Song", "Updated song title should match");
        assertEq(
            song.PrincipalArtistId,
            ARTIST_1_ID,
            "Principal artist ID should match"
        );
        assertEq(
            song.ArtistIDs,
            newArtistIDs,
            "Updated artist IDs should match"
        );
        assertEq(
            song.MediaURI,
            "https://arweave.net/updatedMediaURI",
            "Updated media URI should match"
        );
        assertEq(
            song.MetadataURI,
            "https://arweave.net/updatedMetadataURI",
            "Updated metadata URI should match"
        );
        assertFalse(song.CanBePurchased, "Song should not be purchasable");
        assertEq(song.Price, 1500, "Updated song price should match");
        assertEq(song.TimesBought, 0, "Times bought should remain unchanged");
        assertFalse(song.IsBanned, "Song should not be banned");
    }

    function test_unit_correct_changeSongPrice() public {
        uint256[] memory artistIDs = new uint256[](1);
        artistIDs[0] = ARTIST_2_ID;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Initial Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/initialMediaURI",
            "https://arweave.net/initialMetadataURI",
            true,
            500
        );

        vm.startPrank(ARTIST_1.Address);
        orchestrator.changeSongPrice(songID, 2000);
        vm.stopPrank();

        SongDB.Metadata memory song = songDB.getMetadata(songID);
        assertEq(song.Price, 2000, "Updated song price should match");
    }

    function test_unit_correct_changeSongPurchaseability() public {
        uint256[] memory artistIDs = new uint256[](1);
        artistIDs[0] = ARTIST_2_ID;

        uint256 songID = _execute_orchestrator_registerSong(
            ARTIST_1.Address,
            "Initial Song",
            ARTIST_1_ID,
            artistIDs,
            "https://arweave.net/initialMediaURI",
            "https://arweave.net/initialMetadataURI",
            true,
            500
        );

        vm.startPrank(ARTIST_1.Address);
        orchestrator.changeSongPurchaseability(songID, false);
        vm.stopPrank();

        SongDB.Metadata memory song = songDB.getMetadata(songID);
        assertFalse(song.CanBePurchased, "Song should not be purchasable");
    }

    
}