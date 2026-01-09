// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "../Constants.sol";
import {SongDB} from "@shine/contracts/database/SongDB.sol";

contract SongDB_test_fuzz is Constants {
    function executeBeforeSetUp() internal override {
        songDB = new SongDB(FAKE_ORCHESTRATOR.Address);
    }

    struct SongDataInputs {
        string title;
        uint256 principalArtistID;
        uint256[] artistIDs;
        string mediaURI;
        string metadataURI;
        bool canBePurchased;
        uint256 price;
    }
    function test_fuzz_SongDB__register(SongDataInputs memory inputs) public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = songDB.register(
            inputs.title,
            inputs.principalArtistID,
            inputs.artistIDs,
            inputs.mediaURI,
            inputs.metadataURI,
            inputs.canBePurchased,
            inputs.price
        );
        vm.stopPrank();

        assertEq(assignedId, 1, "Assigned ID should be 1 for the first song");
        assertEq(
            songDB.getMetadata(assignedId).Title,
            inputs.title,
            "Song title should match the registered title"
        );
        assertEq(
            inputs.artistIDs,
            songDB.getMetadata(assignedId).ArtistIDs,
            "Artist IDs should match the registered artist IDs"
        );
        assertEq(
            songDB.getMetadata(assignedId).MediaURI,
            inputs.mediaURI,
            "Media URI should match the registered URI"
        );
        assertEq(
            songDB.getMetadata(assignedId).MetadataURI,
            inputs.metadataURI,
            "Metadata URI should match the registered URI"
        );
        assertEq(
            songDB.getMetadata(assignedId).CanBePurchased,
            inputs.canBePurchased,
            "Song should match the registered purchaseability status"
        );
        assertEq(
            songDB.getMetadata(assignedId).Price,
            inputs.price,
            "Price should match the registered price"
        );
    }

    struct ChangeSongDataInputs {
        string newTitle;
        uint256 newPrincipalArtistID;
        uint256[] newArtistIDs;
        string newMediaURI;
        string newMetadataURI;
        bool newCanBePurchased;
        uint256 newPrice;
    }
    function test_fuzz_SongDB__change(ChangeSongDataInputs memory inputs) public {
        uint256[] memory artistIDsBefore = new uint256[](2);
        artistIDsBefore[0] = 2;
        artistIDsBefore[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = songDB.register(
            "Song Title",
            1,
            artistIDsBefore,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        songDB.change(
            assignedId,
            inputs.newTitle,
            inputs.newPrincipalArtistID,
            inputs.newArtistIDs,
            inputs.newMediaURI,
            inputs.newMetadataURI,
            inputs.newCanBePurchased,
            inputs.newPrice
        );
        vm.stopPrank();

        assertEq(
            songDB.getMetadata(assignedId).Title,
            inputs.newTitle,
            "Song title should be updated to the new title"
        );
        assertEq(
            inputs.newArtistIDs,
            songDB.getMetadata(assignedId).ArtistIDs,
            "Artist IDs should be updated to the new artist IDs"
        );
        assertEq(
            songDB.getMetadata(assignedId).MediaURI,
            inputs.newMediaURI,
            "Media URI should be updated to the new URI"
        );
        assertEq(
            songDB.getMetadata(assignedId).MetadataURI,
            inputs.newMetadataURI,
            "Metadata URI should be updated to the new URI"
        );
        assertEq(
            songDB.getMetadata(assignedId).CanBePurchased,
            inputs.newCanBePurchased,
            "Song should match the updated purchaseability status"
        );
        assertEq(
            songDB.getMetadata(assignedId).Price,
            inputs.newPrice,
            "Price should be updated to the new price"
        );
    }

    function test_fuzz_SongDB__purchase(uint userId) public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;
        
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        songDB.purchase(assignedId, userId);
        vm.stopPrank();
        assertTrue(
            songDB.isBoughtByUser(assignedId, userId),
            "Song should be marked as bought by user"
        );
        assertEq(
            songDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be incremented to 1"
        );
    }

    function test_fuzz_SongDB__refund(uint userId) public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;
        
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        songDB.purchase(assignedId, userId);
        songDB.refund(assignedId, userId);
        vm.stopPrank();
        assertFalse(
            songDB.isBoughtByUser(assignedId, userId),
            "Song should not be marked as bought by user after refund"
        );
        assertEq(
            songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should be decremented to 0 after refund"
        );
    }

    function test_fuzz_SongDB__changePurchaseability(bool statusFlag) public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;
        
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        songDB.changePurchaseability(assignedId, statusFlag);
        vm.stopPrank();
        assertEq(
            songDB.getMetadata(assignedId).CanBePurchased,
            statusFlag,
            "Song purchaseability should be updated to the new status flag"
        );
    }

    function test_fuzz_SongDB__changePrice(uint256 newPrice) public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;
        
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        songDB.changePrice(assignedId, newPrice);
        vm.stopPrank();
        assertEq(
            songDB.getMetadata(assignedId).Price,
            newPrice,
            "Song price should be updated to the new price"
        );
    }

    function test_fuzz_SongDB__setBannedStatus(bool bannedStatus) public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;
        
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        songDB.setBannedStatus(assignedId, bannedStatus);
        vm.stopPrank();
        assertEq(
            songDB.getMetadata(assignedId).IsBanned,
            bannedStatus,
            "Song banned status should be updated to the new status flag"
        );
    }
}
