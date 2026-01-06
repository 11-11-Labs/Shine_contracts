// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "../../Constants.sol";
import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract SongDB_test_unit_revert is Constants {
    function executeBeforeSetUp() internal override {
        songDB = new SongDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_revert_SongDB__register__Unauthorized() public {
        uint256[] memory artistIDs = new uint256[](2);
        artistIDs[0] = 2;
        artistIDs[1] = 3;

        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        songDB.register(
            "Song Title",
            1,
            artistIDs,
            "ipfs://mediaURI",
            "ipfs://metadataURI",
            true,
            500
        );
        vm.stopPrank();

        assertEq(
            songDB.getMetadata(1).PrincipalArtistId,
            0,
            "Song principalArtistId should be 0 as registration failed"
        );
    }

    function test_unit_revert_SongDB__change__Unauthorized() public {
        uint256[] memory artistIDsBefore = new uint256[](2);
        artistIDsBefore[0] = 2;
        artistIDsBefore[1] = 3;

        uint256[] memory artistIDsAfter = new uint256[](1);
        artistIDsAfter[0] = 4;

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
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        songDB.change(
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
            songDB.getMetadata(assignedId).Title,
            "Song Title",
            "Song title should be unchanged due to revert"
        );
    }

    function test_unit_revert_SongDB__change__SongDoesNotExist() public {
        uint256[] memory artistIDsBefore = new uint256[](2);
        artistIDsBefore[0] = 2;
        artistIDsBefore[1] = 3;

        uint256[] memory artistIDsAfter = new uint256[](1);
        artistIDsAfter[0] = 4;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        songDB.change(
            67,
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
            songDB.getMetadata(67).Title,
            "",
            "Song title should be unexistent due to revert"
        );
    }

    function test_unit_revert_SongDB__change__SongIsBanned() public {
        uint256[] memory artistIDsBefore = new uint256[](2);
        artistIDsBefore[0] = 2;
        artistIDsBefore[1] = 3;

        uint256[] memory artistIDsAfter = new uint256[](1);
        artistIDsAfter[0] = 4;

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
        songDB.setBannedStatus(assignedId, true);
        vm.expectRevert(SongDB.SongIsBanned.selector);
        songDB.change(
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
            songDB.getMetadata(assignedId).Title,
            "Song Title",
            "Song title should be unchanged due to revert"
        );
    }

    function test_unit_revert_SongDB__purchase__Unauthorized() public {
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
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        songDB.purchase(assignedId, 10);
        vm.stopPrank();

        assertEq(
            songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__purchase__SongCannotBePurchased() public {
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
            false,
            500
        );
        vm.expectRevert(SongDB.SongCannotBePurchased.selector);
        songDB.purchase(assignedId, 10);
        vm.stopPrank();

        assertEq(
            songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__purchase__SongIsBanned() public {
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
        songDB.setBannedStatus(assignedId, true);
        vm.expectRevert(SongDB.SongIsBanned.selector);
        songDB.purchase(assignedId, 10);
        vm.stopPrank();

        assertEq(
            songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__purchase__UserAlreadyBought() public {
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
        songDB.purchase(assignedId, 10);
        vm.expectRevert(SongDB.UserAlreadyBought.selector);
        songDB.purchase(assignedId, 10);
        vm.stopPrank();

        assertEq(
            songDB.getMetadata(assignedId).TimesBought,
            1,
            "Times bought should remain 1 due to revert"
        );
    }

    function test_unit_revert_SongDB__purchase__SongDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        songDB.purchase(42, 10);
        vm.stopPrank();

        assertEq(
            songDB.getMetadata(42).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__refund__Unauthorised() public {
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
        songDB.purchase(assignedId, 10);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        songDB.refund(assignedId, 10);
        vm.stopPrank();
        assertTrue(
            songDB.isBoughtByUser(assignedId, 10),
            "Song should not be marked as bought by user ID 10 after refund"
        );
    }

    function test_unit_revert_SongDB__refund__UserHasNotBought() public {
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
        vm.expectRevert(SongDB.UserHasNotBought.selector);
        songDB.refund(assignedId, 10);
        vm.stopPrank();
        assertEq(
            songDB.getMetadata(assignedId).TimesBought,
            0,
            "Times bought should remain 0 due to revert"
        );
    }

    function test_unit_revert_SongDB__refund__SongDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        songDB.refund(55, 10);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__changePurchaseability__Unauthorized()
        public
    {
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
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        songDB.changePurchaseability(assignedId, false);
        vm.stopPrank();
        assertTrue(
            songDB.getMetadata(assignedId).CanBePurchased,
            "Song purchaseability should be true after revert"
        );
    }

    function test_unit_revert_SongDB__changePurchaseability__SongIsBanned()
        public
    {
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
        songDB.setBannedStatus(assignedId, true);
        vm.expectRevert(SongDB.SongIsBanned.selector);
        songDB.changePurchaseability(assignedId, false);
        vm.stopPrank();
        assertTrue(
            songDB.getMetadata(assignedId).CanBePurchased,
            "Song purchaseability should be true after revert"
        );
    }

    function test_unit_revert_SongDB__changePurchaseability__SongDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        songDB.changePurchaseability(88, false);
        vm.stopPrank();
    }

    function test_unit_revert_SongDB__changePrice__Unauthorized() public {
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
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        songDB.changePrice(assignedId, 1000);
        vm.stopPrank();
        assertEq(
            songDB.getMetadata(assignedId).Price,
            500,
            "Song price should be unchanged due to revert"
        );
    }

    function test_unit_revert_SongDB__changePrice__SongIsBanned() public {
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
        songDB.setBannedStatus(assignedId, true);
        vm.expectRevert(SongDB.SongIsBanned.selector);
        songDB.changePrice(assignedId, 1000);
        vm.stopPrank();
        assertEq(
            songDB.getMetadata(assignedId).Price,
            500,
            "Song price should be unchanged due to revert"
        );
    }

    function test_unit_revert_SongDB__changePrice__SongDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        songDB.changePrice(99, 1000);
        vm.stopPrank();
    }

    function test_unit_correct_SongDB__setBannedStatus__Unauthorized() public {
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
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        songDB.setBannedStatus(assignedId, true);
        vm.stopPrank();
        assertFalse(
            songDB.getMetadata(assignedId).IsBanned,
            "Song banned status should remain false after revert"
        );
    }

    function test_unit_correct_SongDB__setBannedStatus__SongDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(SongDB.SongDoesNotExist.selector);
        songDB.setBannedStatus(77, true);
        vm.stopPrank();
    }
}
