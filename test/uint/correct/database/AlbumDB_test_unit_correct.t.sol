// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "testing/Constants.sol";
import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";

contract AlbumDB_test_unit_correct is Constants {
    function executeBeforeSetUp() internal override {
        _albumDB = new AlbumDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_correct_AlbumDB__register() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
            _albumDB.getMetadata(assignedId).Title,
            "Album Title",
            "Album title should match"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).PrincipalArtistId,
            1,
            "Principal artist ID should match"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "Metadata URI should match"
        );
        assertEq(
            listOfSongIDs,
            _albumDB.getMetadata(assignedId).MusicIds,
            "Song IDs should match"
        );
        assertTrue(
            _albumDB.isPurchasable(assignedId),
            "Album should be purchasable"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).Price,
            1000,
            "Price should match"
        );
        assertFalse(
            _albumDB.getMetadata(assignedId).IsASpecialEdition,
            "Should not be a special edition"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).SpecialEditionName,
            "",
            "Special edition name should be empty"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MaxSupplySpecialEdition,
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
        uint256 assignedId = _albumDB.register(
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
        uint256[] memory purchasedSongIDs = _albumDB.purchase(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            purchasedSongIDs,
            listOfSongIDs,
            "Purchased song IDs should match the registered ones"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be incremented to 1"
        );
    }

    function test_unit_correct_AlbumDB__gift() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        uint256[] memory giftedSongIDs = _albumDB.gift(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            giftedSongIDs,
            listOfSongIDs,
            "Gifted song IDs should match the registered ones"
        );
    }

    function test_unit_correct_AlbumDB__purchaseSpecialEdition() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        uint256[] memory purchasedSongIDs = _albumDB.purchase(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            purchasedSongIDs,
            listOfSongIDs,
            "Purchased song IDs should match the registered ones"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
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
        uint256 assignedId = _albumDB.register(
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
        _albumDB.purchase(assignedId, 1234);
        _albumDB.refund(assignedId, 1234);
        vm.stopPrank();

        assertEq(
            _albumDB.getMetadata(assignedId).TimesBought,
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
        uint256 assignedId = _albumDB.register(
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

        _albumDB.change(
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
            _albumDB.getMetadata(assignedId).Title,
            "New Album Title",
            "Album title should be updated"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).PrincipalArtistId,
            2,
            "Principal artist ID should be updated"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MetadataURI,
            "ipfs://newMetadataURI",
            "Metadata URI should be updated"
        );
        assertEq(
            listOfSongIDsAfter,
            _albumDB.getMetadata(assignedId).MusicIds,
            "Song IDs should be updated"
        );
        assertTrue(
            _albumDB.isPurchasable(assignedId),
            "Album should be purchasable"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).Price,
            2000,
            "Price should be updated"
        );
        assertTrue(
            _albumDB.getMetadata(assignedId).IsASpecialEdition,
            "Should be a special edition"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).SpecialEditionName,
            "Special Ultra Turbo Deluxe Edition Remaster Battle Royale with Banjo-Kazooie & Nnuckles NEW Funky Mode (Featuring Dante from Devil May Cry Series)",
            "Special edition name should be updated"
        );
        assertEq(
            _albumDB.getMetadata(assignedId).MaxSupplySpecialEdition,
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
        uint256 assignedId = _albumDB.register(
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
        _albumDB.changePurchaseability(assignedId, false);
        vm.stopPrank();
        assertFalse(
            _albumDB.isPurchasable(assignedId),
            "Album should not be purchasable"
        );
    }

    function test_unit_correct_AlbumDB__changePrice() public {
        uint256[] memory listOfSongIDs = new uint256[](3);
        listOfSongIDs[0] = 67;
        listOfSongIDs[1] = 21;
        listOfSongIDs[2] = 420;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _albumDB.register(
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
        _albumDB.changePrice(assignedId, 67);
        vm.stopPrank();
        assertEq(
            _albumDB.getMetadata(assignedId).Price,
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
        uint256 assignedId = _albumDB.register(
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
        _albumDB.setBannedStatus(assignedId, true);
        vm.stopPrank();
        assertTrue(
            _albumDB.getMetadata(assignedId).IsBanned,
            "Album should be banned"
        );
    }
}
