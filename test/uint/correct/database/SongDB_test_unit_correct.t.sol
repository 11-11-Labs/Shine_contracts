// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {SongDB} from "@shine/contracts/database/SongDB.sol";

contract SongDB_test_unit_correct is Constants {
    function executeBeforeSetUp() internal override {
        _songDB = new SongDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_correct_SongDB__register() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);

        vm.expectEmit();
        emit SongDB.Registered(1);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.stopPrank();

        assertEq(assignedId, 1, "Assigned ID should be 1 for the first song");
        assertEq(
            _songDB.getMetadata(assignedId).Title,
            "Song Title",
            "Song title should match the registered title"
        );
        assertEq(
            artistIDs,
            _songDB.getMetadata(assignedId).ArtistIDs,
            "Artist IDs should match the registered artist IDs"
        );
        assertEq(
            _songDB.getMetadata(assignedId).MediaURI,
            "ipfs://mediaURI",
            "Media URI should match the registered URI"
        );
        assertEq(
            _songDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "Metadata URI should match the registered URI"
        );
        assertTrue(
            _songDB.getMetadata(assignedId).CanBePurchased,
            "Song should be purchasable"
        );
        assertEq(
            _songDB.getMetadata(assignedId).Price,
            500,
            "Price should match the registered price"
        );
        assertEq(
            _songDB.getMetadata(assignedId).listOfOwners,
            new uint256[](0),
            "List of owners should be initialized as empty"
        );
    }

    function test_unit_correct_SongDB__change() public {
        uint256[] memory artistIDsBefore = new uint256[](2);
        artistIDsBefore[0] = 2;
        artistIDsBefore[1] = 3;

        uint256[] memory artistIDsAfter = new uint256[](1);
        artistIDsAfter[0] = 4;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDsBefore,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);

        vm.expectEmit();
        emit SongDB.Changed(
            1,
            block.timestamp,
            SongDB.ChangeType.MetadataUpdated
        );
        _songDB.change(
            assignedId,
            "New Song Title",
            2,
            artistIDsAfter,
            "ipfs://newMediaURI",
            "ipfs://newMetadataURI",
            false,
            1000
        );
        vm.stopPrank();

        assertEq(
            _songDB.getMetadata(assignedId).Title,
            "New Song Title",
            "Song title should be updated to the new title"
        );
        assertEq(
            artistIDsAfter,
            _songDB.getMetadata(assignedId).ArtistIDs,
            "Artist IDs should be updated to the new artist IDs"
        );
        assertEq(
            _songDB.getMetadata(assignedId).MediaURI,
            "ipfs://newMediaURI",
            "Media URI should be updated to the new URI"
        );
        assertEq(
            _songDB.getMetadata(assignedId).MetadataURI,
            "ipfs://newMetadataURI",
            "Metadata URI should be updated to the new URI"
        );
        assertFalse(
            _songDB.getMetadata(assignedId).CanBePurchased,
            "Song should not be purchasable after update"
        );
        assertEq(
            _songDB.getMetadata(assignedId).Price,
            1000,
            "Price should be updated to the new price"
        );
    }

    function test_unit_correct_SongDB__purchase() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);

        vm.expectEmit();
        emit SongDB.Purchased(assignedId, 10, block.timestamp);
        _songDB.purchase(assignedId, 10);
        vm.stopPrank();
        assertEq(
            uint256(uint8(_songDB.userOwnershipStatus(assignedId, 10))),
            uint256(0x01),
            "Song should be marked as bought by user ID 10"
        );
        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be incremented to 1"
        );
        assertEq(
            _songDB.getMetadata(assignedId).listOfOwners[0],
            10,
            "User ID 10 should be in the list of owners"
        );
    }

    function test_unit_correct_SongDB__gift() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);

        vm.expectEmit();
        emit SongDB.Gifted(assignedId, 20, block.timestamp);
        _songDB.gift(assignedId, 20);
        vm.stopPrank();
        assertEq(
            uint256(uint8(_songDB.userOwnershipStatus(assignedId, 20))),
            uint256(0x02),
            "Song should be marked as gifted to user ID 20"
        );
        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should be incremented to 1 after gifting"
        );
        assertEq(
            _songDB.getMetadata(assignedId).listOfOwners[0],
            20,
            "User ID 20 should be in the list of owners after gifting"
        );
    }

    function test_unit_correct_SongDB__refund() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        _songDB.purchase(assignedId, 10);

        vm.expectEmit();
        emit SongDB.Refunded(assignedId, 10, block.timestamp);
        _songDB.refund(assignedId, 10);
        vm.stopPrank();
        assertFalse(
            _songDB.isUserOwner(assignedId, 10),
            "Song should not be marked as bought by user ID 10 after refund"
        );
        assertEq(
            _songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should be decremented to 0 after refund"
        );
        assertEq(
            _songDB.getMetadata(assignedId).listOfOwners.length,
            0,
            "List of owners should be empty after refund"
        );
    }

    function test_unit_correct_SongDB__changePurchaseability() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);

        vm.expectEmit();
        emit SongDB.Changed(
            1,
            block.timestamp,
            SongDB.ChangeType.PurchaseabilityChanged
        );
        _songDB.changePurchaseability(assignedId, false);
        vm.stopPrank();
        assertFalse(
            _songDB.getMetadata(assignedId).CanBePurchased,
            "Song purchaseability should be updated to false"
        );
    }

    function test_unit_correct_SongDB__changePrice() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);

        vm.expectEmit();
        emit SongDB.Changed(1, block.timestamp, SongDB.ChangeType.PriceChanged);
        _songDB.changePrice(assignedId, 1000);
        vm.stopPrank();
        assertEq(
            _songDB.getMetadata(assignedId).Price,
            1000,
            "Song price should be updated to 1000"
        );
    }

    function test_unit_correct_SongDB__setBannedStatus() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.setBannedStatus(assignedId, true);
        vm.stopPrank();
        assertTrue(
            _songDB.getMetadata(assignedId).IsBanned,
            "Song should be marked as banned"
        );
    }

    function test_unit_correct_SongDB__setBannedStatusBatch() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 songId1 = _songDB.register(
            "Song Title 1",
            1,
            artistIDs,
            "ipfs://mediaURI1",
            "ipfs://metadataURI1",
            true,
            500
        );
        uint256 songId2 = _songDB.register(
            "Song Title 2",
            1,
            artistIDs,
            "ipfs://mediaURI2",
            "ipfs://metadataURI2",
            true,
            600
        );

        uint256[] memory songIds = new uint256[](2);
        songIds[0] = songId1;
        songIds[1] = songId2;

        _songDB.setBannedStatusBatch(songIds, true);
        vm.stopPrank();
        assertTrue(
            _songDB.getMetadata(songId1).IsBanned,
            "Song ID 1 should be marked as banned"
        );
        assertTrue(
            _songDB.getMetadata(songId2).IsBanned,
            "Song ID 2 should be marked as banned"
        );
    }

    function test_unit_correct_SongDB_assignToAlbum() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );

        _songDB.assignToAlbum(assignedId, 1);
        vm.stopPrank();
        assertEq(
            _songDB.getAssignedAlbumId(assignedId),
            1,
            "Song should be assigned to album ID 1"
        );
    }

    function test_unit_correct_SongDB_assignToAlbumBatch() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 songId1 = _songDB.register(
            "Song Title 1",
            1,
            artistIDs,
            "ipfs://mediaURI1",
            "ipfs://metadataURI1",
            true,
            500
        );
        uint256 songId2 = _songDB.register(
            "Song Title 2",
            1,
            artistIDs,
            "ipfs://mediaURI2",
            "ipfs://metadataURI2",
            true,
            600
        );

        uint256[] memory songIds = new uint256[](2);
        songIds[0] = songId1;
        songIds[1] = songId2;

        _songDB.assignToAlbumBatch(songIds, 2);
        vm.stopPrank();
        assertEq(
            _songDB.getAssignedAlbumId(songId1),
            2,
            "Song ID 1 should be assigned to album ID 2"
        );
        assertEq(
            _songDB.getAssignedAlbumId(songId2),
            2,
            "Song ID 2 should be assigned to album ID 2"
        );
    }

    function test_unit_correct_SongDB_setListVisibility() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        _songDB.assignToAlbum(assignedId, 1);
        _songDB.purchase(assignedId, 10);

        _songDB.setListVisibility(true);
        vm.stopPrank();

        (uint256[] memory owners) = _songDB.getListOfOwners(assignedId);

        assertEq(
            owners.length,
            1,
            "List of owners should be retrievable when visibility is true"
        );

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        _songDB.setListVisibility(false);
        vm.stopPrank();

        vm.expectRevert(SongDB.CannotSeeListOfOwners.selector);
        _songDB.getListOfOwners(assignedId);
    }
}
