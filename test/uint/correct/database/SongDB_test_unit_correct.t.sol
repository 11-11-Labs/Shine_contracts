// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "../../../Constants.sol";
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
        _songDB.purchase(assignedId, 10);
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
}
