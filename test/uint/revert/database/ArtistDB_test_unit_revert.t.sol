// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "testing/Constants.sol";

import {ArtistDB} from "@shine/contracts/database/ArtistDB.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract ArtistDB_test_unit_revert is Constants {
    function executeBeforeSetUp() internal override {
        _artistDB = new ArtistDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_revert_ArtistDB__register__Unauthorized() public {
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _artistDB.register("Artist Name", "ipfs://metadataURI", ARTIST_1.Address);
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(1).Name,
            "",
            "Artist name should be empty due to revert"
        );
        assertEq(
            _artistDB.getMetadata(1).MetadataURI,
            "",
            "Metadata URI should be empty due to revert"
        );
        assertEq(
            _artistDB.getMetadata(1).Address,
            address(0),
            "Artist address should be address(0) due to revert"
        );
        assertEq(
            _artistDB.getMetadata(1).Balance,
            0,
            "Total earnings should be initialized to 0 due to revert"
        );
        assertEq(
            _artistDB.getMetadata(1).AccumulatedRoyalties,
            0,
            "Accumulated royalties should be initialized to 0 due to revert"
        );
    }

    function test_unit_revert_ArtistDB__changeBasicData__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _artistDB.changeBasicData(
            assignedId,
            "New Artist Name",
            "ipfs://newMetadataURI"
        );
        vm.stopPrank();
        assertEq(
            _artistDB.getMetadata(assignedId).Name,
            "Artist Name",
            "Artist name should not be updated due to revert"
        );
        assertEq(
            _artistDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "Metadata URI should not be updated due to revert"
        );
    }

    function test_unit_revert_ArtistDB__changeBasicData__NameShouldNotBeEmpty()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        vm.expectRevert(ArtistDB.NameShouldNotBeEmpty.selector);
        _artistDB.changeBasicData(assignedId, "", "ipfs://newMetadataURI");
        vm.stopPrank();
        assertEq(
            _artistDB.getMetadata(assignedId).Name,
            "Artist Name",
            "Artist name should not be updated due to revert"
        );
        assertEq(
            _artistDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "Metadata URI should not be updated due to revert"
        );
    }

    function test_unit_revert_ArtistDB__changeBasicData__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        _artistDB.changeBasicData(1, "New Artist Name", "ipfs://newMetadataURI");
        vm.stopPrank();
        assertEq(
            _artistDB.getMetadata(1).Name,
            "",
            "Artist name should not be updated due to revert"
        );
        assertEq(
            _artistDB.getMetadata(1).MetadataURI,
            "",
            "Metadata URI should not be updated due to revert"
        );
    }

    function test_unit_revert_ArtistDB__changeBasicData__ArtistIsBanned()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        _artistDB.setBannedStatus(assignedId, true);
        vm.expectRevert(ArtistDB.ArtistIsBanned.selector);
        _artistDB.changeBasicData(
            assignedId,
            "New Artist Name",
            "ipfs://newMetadataURI"
        );
        vm.stopPrank();
        assertEq(
            _artistDB.getMetadata(assignedId).Name,
            "Artist Name",
            "Artist name should not be updated due to revert"
        );
        assertEq(
            _artistDB.getMetadata(assignedId).MetadataURI,
            "ipfs://metadataURI",
            "Metadata URI should not be updated due to revert"
        );
    }

    function test_unit_revert_ArtistDB__changeAddress__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _artistDB.changeAddress(assignedId, address(67));
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(assignedId).Address,
            ARTIST_1.Address,
            "Artist address should be the same because revert occurred"
        );
        assertEq(
            _artistDB.getAddress(assignedId),
            ARTIST_1.Address,
            "getAddress should return the original address because revert occurred"
        );
    }

    function test_unit_revert_ArtistDB__changeAddress__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        _artistDB.changeAddress(1, address(67));
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(1).Address,
            address(0),
            "Artist address should be return address(0) because revert occurred"
        );
        assertEq(
            _artistDB.getAddress(1),
            address(0),
            "getAddress should return address(0) because revert occurred"
        );
    }

    function test_unit_revert_ArtistDB__changeAddress__ArtistIsBanned() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        _artistDB.setBannedStatus(assignedId, true);
        vm.expectRevert(ArtistDB.ArtistIsBanned.selector);
        _artistDB.changeAddress(assignedId, address(67));
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(assignedId).Address,
            ARTIST_1.Address,
            "Artist address should be the same because revert occurred"
        );
        assertEq(
            _artistDB.getAddress(assignedId),
            ARTIST_1.Address,
            "getAddress should return the original address because revert occurred"
        );
    }

    function test_unit_revert_ArtistDB__addBalance__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _artistDB.addBalance(assignedId, 1000);
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(assignedId).Balance,
            0,
            "Balance should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__addBalance__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        _artistDB.addBalance(1, 1000);
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(1).Balance,
            0,
            "Balance should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__addBalance__ArtistIsBanned() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        _artistDB.setBannedStatus(assignedId, true);
        vm.expectRevert(ArtistDB.ArtistIsBanned.selector);
        _artistDB.addBalance(assignedId, 1000);
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(assignedId).Balance,
            0,
            "Balance should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__deductBalance__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        _artistDB.addBalance(assignedId, 1000);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _artistDB.deductBalance(assignedId, 500);
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(assignedId).Balance,
            1000,
            "Balance should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__deductBalance__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        _artistDB.deductBalance(1, 500);
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(1).Balance,
            0,
            "Balance should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__addAccumulatedRoyalties__Unauthorized()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _artistDB.addAccumulatedRoyalties(assignedId, 1000);
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(assignedId).AccumulatedRoyalties,
            0,
            "Accumulated royalties should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__addAccumulatedRoyalties__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        _artistDB.addAccumulatedRoyalties(1, 1000);
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(1).AccumulatedRoyalties,
            0,
            "Accumulated royalties should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__addAccumulatedRoyalties__ArtistIsBanned()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        _artistDB.setBannedStatus(assignedId, true);
        vm.expectRevert(ArtistDB.ArtistIsBanned.selector);
        _artistDB.addAccumulatedRoyalties(assignedId, 1000);
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(assignedId).AccumulatedRoyalties,
            0,
            "Accumulated royalties should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__deductAccumulatedRoyalties__Unauthorized()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        _artistDB.addAccumulatedRoyalties(assignedId, 1000);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _artistDB.deductAccumulatedRoyalties(assignedId, 500);
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(assignedId).AccumulatedRoyalties,
            1000,
            "Accumulated royalties should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__deductAccumulatedRoyalties__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        _artistDB.deductAccumulatedRoyalties(1, 500);
        vm.stopPrank();

        assertEq(
            _artistDB.getMetadata(1).AccumulatedRoyalties,
            0,
            "Accumulated royalties should be unchanged due to revert"
        );
    }

    function test_unit_revert_ArtistDB__setBannedStatus__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST_1.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _artistDB.setBannedStatus(assignedId, true);
        vm.stopPrank();

        assertFalse(
            _artistDB.getMetadata(assignedId).IsBanned,
            "Artist should be not banned due to revert"
        );
    }

    function test_revert_correct_ArtistDB__setBannedStatus__ArtistDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(ArtistDB.ArtistDoesNotExist.selector);
        _artistDB.setBannedStatus(1, true);
        vm.stopPrank();

        assertFalse(
            _artistDB.getMetadata(1).IsBanned,
            "Artist should be not banned due to revert"
        );
    }
}
