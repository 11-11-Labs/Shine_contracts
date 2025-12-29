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

    function test_unit_correct_UserDB__addSong() public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.addSong(assignedId, 101);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB
            .getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songs,
            "Purchased song IDs array should have one entry"
        );
    }


    function test_unit_correct_UserDB__deleteSong() public {
        uint256[] memory songsBefore = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            songsBefore[i] = i + 100;
        }
        uint256[] memory songsAfter = new uint256[](9);
        songsAfter[0] = 100;
        songsAfter[1] = 101;
        songsAfter[2] = 102;
        songsAfter[3] = 103;
        songsAfter[4] = 105;
        songsAfter[5] = 106;
        songsAfter[6] = 107;
        songsAfter[7] = 108;
        songsAfter[8] = 109;
        
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.addSongs(assignedId, songsBefore);
        userDB.deleteSong(assignedId, 104);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB
            .getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songsAfter,
            "Purchased song IDs array should have the correct entries after removal"
        );
    }


    function test_unit_correct_UserDB__addSongs() public {
        uint256[] memory songsBefore = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            songsBefore[i] = i + 100;
        }
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.addSongs(assignedId, songsBefore);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB
            .getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songsBefore,
            "Purchased song IDs array should have all added entries"
        );
    }

    function test_unit_correct_UserDB__deleteSongs() public {
        uint256[] memory songsBefore = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            songsBefore[i] = i + 100;
        }
        uint256[] memory songsAfter = new uint256[](8);
        songsAfter[0] = 100;
        songsAfter[1] = 101;
        songsAfter[2] = 102;
        songsAfter[3] = 103;
        songsAfter[4] = 105;
        songsAfter[5] = 106;
        songsAfter[6] = 107;
        songsAfter[7] = 109;

        uint256[] memory songsToDelete = new uint256[](2);
        songsToDelete[0] = 104;
        songsToDelete[1] = 108;
        
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.addSongs(assignedId, songsBefore);
        userDB.deleteSongs(assignedId, songsToDelete);
        vm.stopPrank();

        uint256[] memory purchasedSongs = userDB
            .getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songsAfter,
            "Purchased song IDs array should have the correct entries after removal"
        );
    }

    function test_unit_correct_UserDB__addBalance() public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.addBalance(assignedId, 100);
        vm.stopPrank();

        assertEq(
            userDB.getBalance(assignedId),
            100,
            "Balance should be updated correctly"
        );
    }

    function test_unit_correct_UserDB__deductBalance() public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        userDB.addBalance(assignedId, 100);
        userDB.deductBalance(assignedId, 50);
        vm.stopPrank();

        assertEq(
            userDB.getBalance(assignedId),
            50,
            "Balance should be updated correctly"
        );
    }




}
