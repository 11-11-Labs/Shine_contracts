// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "../../Constants.sol";
import {ArtistDB} from "@shine/contracts/database/ArtistDB.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract ArtistDB_test_unit_revert is Constants {
    function executeBeforeSetUp() internal override {
        artistDB = new ArtistDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_revert_ArtistDB__register__Unauthorized() public {
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        artistDB.register("Artist Name", "ipfs://metadataURI", ARTIST.Address);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(1).Name,
            "",
            "Artist name should be empty due to revert"
        );
        assertEq(
            artistDB.getMetadata(1).MetadataURI,
            "",
            "Metadata URI should be empty due to revert"
        );
        assertEq(
            artistDB.getMetadata(1).Address,
            address(0),
            "Artist address should be address(0) due to revert"
        );
        assertEq(
            artistDB.getMetadata(1).Balance,
            0,
            "Total earnings should be initialized to 0 due to revert"
        );
        assertEq(
            artistDB.getMetadata(1).AccumulatedRoyalties,
            0,
            "Accumulated royalties should be initialized to 0 due to revert"
        );
    }

    function test_unit_revert_ArtistDB__changeBasicData__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        artistDB.changeBasicData(
            assignedId,
            "New Artist Name",
            "ipfs://newMetadataURI"
        );
        vm.stopPrank();
        assertEq(
            artistDB.getMetadata(assignedId).Name,
            "Artist Name",
            "Artist name should not be updated due to revert"
        );
        assertEq(
            artistDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "Metadata URI should not be updated due to revert"
        );
    }

    function test_unit_revert_ArtistDB__changeBasicData__NameShouldNotBeEmpty()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        vm.expectRevert(ArtistDB.NameShouldNotBeEmpty.selector);
        artistDB.changeBasicData(assignedId, "", "ipfs://newMetadataURI");
        vm.stopPrank();
        assertEq(
            artistDB.getMetadata(assignedId).Name,
            "Artist Name",
            "Artist name should not be updated due to revert"
        );
        assertEq(
            artistDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "Metadata URI should not be updated due to revert"
        );
    }

    function test_unit_revert_ArtistDB__changeBasicData__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        artistDB.changeBasicData(1, "New Artist Name", "ipfs://newMetadataURI");
        vm.stopPrank();
        assertEq(
            artistDB.getMetadata(1).Name,
            "",
            "Artist name should not be updated due to revert"
        );
        assertEq(
            artistDB.getMetadata(1).MetadataURI,
            "",
            "Metadata URI should not be updated due to revert"
        );
    }

    function test_unit_revert_ArtistDB__changeBasicData__ArtistIsBanned()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.setBannedStatus(assignedId, true);
        vm.expectRevert(ArtistDB.ArtistIsBanned.selector);
        artistDB.changeBasicData(
            assignedId,
            "New Artist Name",
            "ipfs://newMetadataURI"
        );
        vm.stopPrank();
        assertEq(
            artistDB.getMetadata(assignedId).Name,
            "Artist Name",
            "Artist name should not be updated due to revert"
        );
        assertEq(
            artistDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "Metadata URI should not be updated due to revert"
        );
    }

    function test_unit_revert_ArtistDB__changeAddress__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        artistDB.changeAddress(assignedId, address(67));
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Address,
            ARTIST.Address,
            "Artist address should be the same because revert occurred"
        );
        assertEq(
            artistDB.getAddress(assignedId),
            ARTIST.Address,
            "getAddress should return the original address because revert occurred"
        );
    }

    function test_unit_revert_ArtistDB__changeAddress__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        artistDB.changeAddress(1, address(67));
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(1).Address,
            address(0),
            "Artist address should be return address(0) because revert occurred"
        );
        assertEq(
            artistDB.getAddress(1),
            address(0),
            "getAddress should return address(0) because revert occurred"
        );
    }

    function test_unit_revert_ArtistDB__changeAddress__ArtistIsBanned() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.setBannedStatus(assignedId, true);
        vm.expectRevert(ArtistDB.ArtistIsBanned.selector);
        artistDB.changeAddress(assignedId, address(67));
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Address,
            ARTIST.Address,
            "Artist address should be the same because revert occurred"
        );
        assertEq(
            artistDB.getAddress(assignedId),
            ARTIST.Address,
            "getAddress should return the original address because revert occurred"
        );
    }

    function test_unit_revert_ArtistDB__addBalance__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        artistDB.addBalance(assignedId, 1000);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Balance,
            0,
            "Balance should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__addBalance__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        artistDB.addBalance(1, 1000);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(1).Balance,
            0,
            "Balance should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__addBalance__ArtistIsBanned() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.setBannedStatus(assignedId, true);
        vm.expectRevert(ArtistDB.ArtistIsBanned.selector);
        artistDB.addBalance(assignedId, 1000);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Balance,
            0,
            "Balance should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__deductBalance__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.addBalance(assignedId, 1000);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        artistDB.deductBalance(assignedId, 500);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Balance,
            1000,
            "Balance should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__deductBalance__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        artistDB.deductBalance(1, 500);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(1).Balance,
            0,
            "Balance should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__addAccumulatedRoyalties__Unauthorized()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        artistDB.addAccumulatedRoyalties(assignedId, 1000);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).AccumulatedRoyalties,
            0,
            "Accumulated royalties should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__addAccumulatedRoyalties__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        artistDB.addAccumulatedRoyalties(1, 1000);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(1).AccumulatedRoyalties,
            0,
            "Accumulated royalties should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__addAccumulatedRoyalties__ArtistIsBanned()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.setBannedStatus(assignedId, true);
        vm.expectRevert(ArtistDB.ArtistIsBanned.selector);
        artistDB.addAccumulatedRoyalties(assignedId, 1000);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).AccumulatedRoyalties,
            0,
            "Accumulated royalties should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__deductAccumulatedRoyalties__Unauthorized()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.addAccumulatedRoyalties(assignedId, 1000);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        artistDB.deductAccumulatedRoyalties(assignedId, 500);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).AccumulatedRoyalties,
            1000,
            "Accumulated royalties should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__deductAccumulatedRoyalties__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        artistDB.deductAccumulatedRoyalties(1, 500);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(1).AccumulatedRoyalties,
            0,
            "Accumulated royalties should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__setBannedStatus__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        artistDB.setBannedStatus(assignedId, true);
        vm.stopPrank();

        assertFalse(
            artistDB.getMetadata(assignedId).IsBanned,
            "Artist should be not banned due to revert"
        );
    }

    function test_revert_correct_ArtistDB__setBannedStatus__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        artistDB.setBannedStatus(1, true);
        vm.stopPrank();

        assertFalse(
            artistDB.getMetadata(1).IsBanned,
            "Artist should be not banned due to revert"
        );
    }
}
