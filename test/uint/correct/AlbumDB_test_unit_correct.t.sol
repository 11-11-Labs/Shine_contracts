// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "../../Constants.sol";
import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";

contract AlbumDB_test_unit_correct is Constants {
    function executeBeforeSetUp() internal override {
        albumDB = new AlbumDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_correct_AlbumDB__register() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        vm.stopPrank();

        assertEq(assignedId, 1, "Assigned ID should be 1");
        assertEq(
            albumDB.getMetadata(assignedId).Title,
            "Album Title",
            "Album title should match"
        );
        assertEq(
            albumDB.getMetadata(assignedId).PrincipalArtistId,
            1,
            "Principal artist ID should match"
        );
        assertEq(
            albumDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "Metadata URI should match"
        );
        assertEq(
            listOfSongIDs,
            albumDB.getMetadata(assignedId).MusicIds,
            "Song IDs should match"
        );
        assertTrue(
            albumDB.isPurschaseable(assignedId),
            "Album should be purchasable"
        );
        assertEq(
            albumDB.getMetadata(assignedId).Price,
            1000,
            "Price should match"
        );
        assertFalse(
            albumDB.getMetadata(assignedId).IsASpecialEdition,
            "Should not be a special edition"
        );
        assertEq(
            albumDB.getMetadata(assignedId).SpecialEditionName,
            "",
            "Special edition name should be empty"
        );
        assertEq(
            albumDB.getMetadata(assignedId).MaxSupplySpecialEdition,
            0,
            "Max supply for special edition should be 0"
        );
    }

    function test_unit_correct_AlbumDB__purchase() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        uint256[] memory purchasedSongIDs = albumDB.purchase(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            purchasedSongIDs,
            listOfSongIDs,
            "Purchased song IDs should match the registered ones"
        );
        assertEq(
            albumDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be incremented to 1"
        );
    }

    function test_unit_correct_AlbumDB__purchaseSpecialEdition() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            67
            // he he c:
        );
        uint256[] memory purchasedSongIDs = albumDB.purchaseSpecialEdition(
            assignedId,
            1234
        );
        vm.stopPrank();

        assertEq(
            purchasedSongIDs,
            listOfSongIDs,
            "Purchased song IDs should match the registered ones"
        );
        assertEq(
            albumDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be incremented to 1"
        );
    }

    function test_unit_correct_AlbumDB__refund() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        albumDB.purchase(assignedId, 1234);
        albumDB.refund(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            albumDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should be decremented to 0"
        );
    }

    function test_unit_correct_AlbumDB__change() public {
        uint256[] memory listOfSongIDsBefore = new uint256[](3);
        listOfSongIDsBefore[0] = 67;
        listOfSongIDsBefore[1] = 21;
        listOfSongIDsBefore[2] = 420;

        uint256[] memory listOfSongIDsAfter = new uint256[](2);
        listOfSongIDsAfter[0] = 67;
        listOfSongIDsAfter[1] = 21;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDsBefore,
            1000,
            true,
            false,
            "",
            0
        );

        albumDB.change(
            assignedId,
            "New Album Title",
            2,
            "ipfs://newMetadataURI",
            listOfSongIDsAfter,
            2000,
            true,
            true,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            67
        );
        vm.stopPrank();

        assertEq(
            albumDB.getMetadata(assignedId).Title,
            "New Album Title",
            "Album title should be updated"
        );
        assertEq(
            albumDB.getMetadata(assignedId).PrincipalArtistId,
            2,
            "Principal artist ID should be updated"
        );
        assertEq(
            albumDB.getMetadata(assignedId).MetadataURI,
            "ipfs://newMetadataURI",
            "Metadata URI should be updated"
        );
        assertEq(
            listOfSongIDsAfter,
            albumDB.getMetadata(assignedId).MusicIds,
            "Song IDs should be updated"
        );
        assertTrue(
            albumDB.isPurschaseable(assignedId),
            "Album should be purchasable"
        );
        assertEq(
            albumDB.getMetadata(assignedId).Price,
            2000,
            "Price should be updated"
        );
        assertTrue(
            albumDB.getMetadata(assignedId).IsASpecialEdition,
            "Should be a special edition"
        );
        assertEq(
            albumDB.getMetadata(assignedId).SpecialEditionName,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            "Special edition name should be updated"
        );
        assertEq(
            albumDB.getMetadata(assignedId).MaxSupplySpecialEdition,
            67,
            "Max supply for special edition should be updated"
        );
    }

    function test_unit_correct_AlbumDB__changePurchaseability() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        albumDB.changePurchaseability(assignedId, false);
        vm.stopPrank();
        assertFalse(
            albumDB.isPurschaseable(assignedId),
            "Album should not be purchasable"
        );
    }

    function test_unit_correct_AlbumDB__changePrice() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        albumDB.changePrice(assignedId, 67);
        vm.stopPrank();
        assertEq(
            albumDB.getMetadata(assignedId).Price,
            67,
            "Price should be updated"
        );
    }

    function test_unit_correct_AlbumDB__setBannedStatus() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = albumDB.register(
            "Album Title",
            1,
            "ipfs://metadataURI",
            listOfSongIDs,
            1000,
            true,
            false,
            "",
            0
        );
        albumDB.setBannedStatus(assignedId, true);
        vm.stopPrank();
        assertTrue(
            albumDB.getMetadata(assignedId).IsBanned,
            "Album should be banned"
        );
    }
}
