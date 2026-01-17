// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "../../Constants.sol";
import {ArtistDB} from "@shine/contracts/database/ArtistDB.sol";

contract ArtistDB_test_fuzz is Constants {
    function executeBeforeSetUp() internal override {
        artistDB = new ArtistDB(FAKE_ORCHESTRATOR.Address);
    }

    struct ArtistDataInputs {
        string name;
        string metadataURI;
        address artistAddress;
    }
    function test_fuzz_ArtistDB__register(
        ArtistDataInputs memory inputs
    ) public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            inputs.name,
            inputs.metadataURI,
            inputs.artistAddress
        );
        vm.stopPrank();

        assertEq(assignedId, 1, "Assigned ID should be 1 for the first artist");
        assertEq(
            artistDB.getMetadata(assignedId).Name,
            inputs.name,
            "Artist name should match the registered name"
        );
        assertEq(
            artistDB.getMetadata(assignedId).MetadataURI,
            inputs.metadataURI,
            "Metadata URI should match the registered URI"
        );
        assertEq(
            artistDB.getMetadata(assignedId).Address,
            inputs.artistAddress,
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

    struct ChangeBasicDataInputs {
        string newName;
        string newMetadataURI;
    }
    function test_fuzz_ArtistDB__changeBasicData(ChangeBasicDataInputs memory inputs) public {
        vm.assume(bytes(inputs.newName).length > 0);
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.changeBasicData(
            assignedId,
            inputs.newName,
            inputs.newMetadataURI
        );
        vm.stopPrank();
        assertEq(
            artistDB.getMetadata(assignedId).Name,
            inputs.newName,
            "Artist name should be updated to the new name"
        );
        assertEq(
            artistDB.getMetadata(assignedId).MetadataURI,
            inputs.newMetadataURI,
            "Metadata URI should be updated to the new URI"
        );
    }

    function test_fuzz_ArtistDB__changeAddress(address newAddress) public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.changeAddress(assignedId, newAddress);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Address,
            newAddress,
            "Artist address should be updated to the new address"
        );
        assertEq(
            artistDB.getAddress(assignedId),
            newAddress,
            "getAddress should return the updated address"
        );
    }

    function test_fuzz_ArtistDB__addBalance(uint256 amount) public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.addBalance(assignedId, amount);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Balance,
            amount,
            "Balance should be updated correctly"
        );
    }

    function test_fuzz_ArtistDB__deductBalance(uint256 amount, uint256 deductAmount) public {
        vm.assume(deductAmount <= amount);
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.addBalance(assignedId, amount);
        artistDB.deductBalance(assignedId, deductAmount);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).Balance,
            amount - deductAmount,
            "Balance should be updated correctly"
        );
    }

    function test_fuzz_ArtistDB__addAccumulatedRoyalties(uint256 amount) public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.addAccumulatedRoyalties(assignedId, amount);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).AccumulatedRoyalties,
            amount,
            "Accumulated royalties should be updated correctly"
        );
    }

    function test_fuzz_ArtistDB__deductAccumulatedRoyalties(uint256 amount, uint256 deductAmount) public {
        vm.assume(deductAmount <= amount);
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.addAccumulatedRoyalties(assignedId, amount);
        artistDB.deductAccumulatedRoyalties(assignedId, deductAmount);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).AccumulatedRoyalties,
            amount - deductAmount,
            "Accumulated royalties should be updated correctly"
        );
    }

    function test_fuzz_ArtistDB__setBannedStatus(bool statusFlag) public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = artistDB.register(
            "Artist Name",
            "ipfs://metadataURI",
            ARTIST.Address
        );
        artistDB.setBannedStatus(assignedId, statusFlag);
        vm.stopPrank();

        assertEq(
            artistDB.getMetadata(assignedId).IsBanned,
            statusFlag,
            "Artist should have the correct banned status"
        );
    }
}
