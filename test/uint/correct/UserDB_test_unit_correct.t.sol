// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "../../Constants.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";

contract UserDB_test_unit_correct is Constants {
    function executeBeforeSetUp() internal override {
        userDB = new UserDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_correct_UserDB__register() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        vm.stopPrank();

        assertEq(assignedId, 1, "Assigned ID should be 1 for the first user");
        assertEq(
            userDB.getMetadata(assignedId).username,
            "User Name",
            "Username should match the registered name"
        );
        assertEq(
            userDB.getMetadata(assignedId).metadataURI,
            "ipfs://metadataURI",
            "Metadata URI should match the registered URI"
        );
        assertEq(
            userDB.getMetadata(assignedId).userAddress,
            USER.Address,
            "User address should match the registered address"
        );
        assertEq(
            userDB.getMetadata(assignedId).purchasedSongIds.length,
            0,
            "Purchased song IDs should be initialized to an empty array"
        );
        assertEq(
            userDB.getMetadata(assignedId).balance,
            0,
            "Balance should be initialized to 0"
        ); 
    }

    function test_unit_correct_UserDB__changeBasicData() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.changeBasicData(
            assignedId,
            "New User Name",
            "ipfs://newMetadataURI"
        );
        vm.stopPrank();

        assertEq(
            userDB.getMetadata(assignedId).username,
            "New User Name",
            "Username should be updated correctly"
        );
        assertEq(
            userDB.getMetadata(assignedId).metadataURI,
            "ipfs://newMetadataURI",
            "Metadata URI should be updated correctly"
        );
    }

    function test_unit_correct_UserDB__changeAddress() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.changeAddress(assignedId, address(67));
        vm.stopPrank();

        assertEq(
            userDB.getMetadata(assignedId).userAddress,
            address(67),
            "User address should be updated correctly"
        );
        assertEq(
            userDB.getId(address(67)),
            assignedId,
            "Address to ID mapping should be updated correctly"
        );
        assertEq(
            userDB.getId(USER.Address),
            0,
            "Old address should no longer map to any user ID"
        );
    }
}
