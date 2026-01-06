// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "../../Constants.sol";
import {ArtistDB} from "@shine/contracts/database/ArtistDB.sol";

contract ArtistDB_test_unit_correct is Constants {
    function executeBeforeSetUp() internal override {
        artistDB = new ArtistDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_correct_ArtistDB__register() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
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
        assertEq(
            artistDB.getMetadata(assignedId).Balance,
            0,
            "Total earnings should be initialized to 0"
        );
        assertEq(
            artistDB.getMetadata(assignedId).AccumulatedRoyalties,
            0,
            "Accumulated royalties should be initialized to 0"
        );
    }

    function test_unit_correct_ArtistDB__changeBasicData() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.changeBasicData(
            assignedId,
            "New Artist Name",
            "ipfs://newMetadataURI"
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
    }

    function test_unit_correct_ArtistDB__changeAddress() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.changeAddress(assignedId, address(67));
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Address,
            address(67),
            "Artist address should be updated to the new address"
        );
        assertEq(
            artistDB.getAddress(assignedId),
            address(67),
            "getAddress should return the updated address"
        );
    }

    function test_unit_correct_ArtistDB__addBalance() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.addBalance(assignedId, 1000);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Balance,
            1000,
            "Balance should be updated correctly"
        );
    }

    function test_unit_correct_ArtistDB__deductBalance() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.addBalance(assignedId, 1000);
        artistDB.deductBalance(assignedId, 500);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Balance,
            500,
            "Balance should be updated correctly"
        );
    }

    function test_unit_correct_ArtistDB__addAccumulatedRoyalties() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.addAccumulatedRoyalties(assignedId, 1000);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).AccumulatedRoyalties,
            1000,
            "Accumulated royalties should be updated correctly"
        );
    }

    function test_unit_correct_ArtistDB__deductAccumulatedRoyalties() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.addAccumulatedRoyalties(assignedId, 1000);
        artistDB.deductAccumulatedRoyalties(assignedId, 500);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).AccumulatedRoyalties,
            500,
            "Accumulated royalties should be updated correctly"
        );
    }

    function test_unit_correct_ArtistDB__setBannedStatus() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.setBannedStatus(assignedId, true);
        vm.stopPrank();

        assertTrue(
            artistDB.getMetadata(assignedId).isBanned,
            "Artist should be marked as banned"
        );
    }
}
