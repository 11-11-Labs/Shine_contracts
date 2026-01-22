// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "testing/Constants.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract UserDB_test_unit_revert is Constants {
    function executeBeforeSetUp() internal override {
        _userDB = new UserDB(FAKE_ORCHESTRATOR.Address);
    }

    function test_unit_revert_UserDB__register__Unauthorized() public {
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(assignedId).Username,
            "",
            "Username should be empty after revert"
        );
    }

    function test_unit_revert_UserDB__changeBasicData__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _userDB.changeBasicData(
            assignedId,
            "New User Name",
            "ipfs://newMetadataURI"
        );
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(assignedId).Username,
            "User Name",
            "Username should be unchanged after revert"
        );
    }
    function test_unit_revert_UserDB__changeBasicData__UserDoesNotExist()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(UserDB.UserDoesNotExist.selector);
        _userDB.changeBasicData(1, "New User Name", "ipfs://newMetadataURI");
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(1).Username,
            "",
            "Username should be empty after revert"
        );
    }
    function test_unit_revert_UserDB__changeBasicData__UserIsBanned() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.setBannedStatus(assignedId, true);
        vm.expectRevert(UserDB.UserIsBanned.selector);
        _userDB.changeBasicData(
            assignedId,
            "New User Name",
            "ipfs://newMetadataURI"
        );
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(assignedId).Username,
            "User Name",
            "Username should be unchanged after revert"
        );
    }
    function test_unit_revert_UserDB__changeBasicData__UsernameIsEmpty()
        public
    {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        vm.expectRevert(UserDB.UsernameIsEmpty.selector);
        _userDB.changeBasicData(assignedId, "", "ipfs://newMetadataURI");
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(assignedId).Username,
            "User Name",
            "Username should be unchanged after revert"
        );
    }

    function test_unit_revert_UserDB__changeAddress__Unauthorized() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _userDB.changeAddress(assignedId, address(67));
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(assignedId).Address,
            USER.Address,
            "User address should be unchanged after revert"
        );
    }

    function test_unit_revert_UserDB__changeAddress__UserDoesNotExist() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(UserDB.UserDoesNotExist.selector);
        _userDB.changeAddress(1, address(67));
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(1).Address,
            address(0),
            "User address should be address(0) after revert"
        );
    }

    function test_unit_revert_UserDB__changeAddress__UserIsBanned() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.setBannedStatus(assignedId, true);
        vm.expectRevert(UserDB.UserIsBanned.selector);
        _userDB.changeAddress(assignedId, address(67));
        vm.stopPrank();

        assertEq(
            _userDB.getMetadata(assignedId).Address,
            USER.Address,
            "User address should be unchanged after revert"
        );
    }

    function test_unit_revert_UserDB__addSong__Unauthorized() public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _userDB.addSong(assignedId, 101);
        vm.stopPrank();

        assertEq(
            _userDB.getPurchasedSong(assignedId).length,
            0,
            "Purchased song IDs array should be empty after revert"
        );
    }

    function test_unit_revert_UserDB__addSong__UserDoesNotExist() public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(UserDB.UserDoesNotExist.selector);
        _userDB.addSong(1, 101);
        vm.stopPrank();

        assertEq(
            _userDB.getPurchasedSong(1).length,
            0,
            "Purchased song IDs array should be empty after revert"
        );
    }

    function test_unit_revert_UserDB__addSong__UserIsBanned() public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.setBannedStatus(assignedId, true);
        vm.expectRevert(UserDB.UserIsBanned.selector);
        _userDB.addSong(assignedId, 101);
        vm.stopPrank();

        assertEq(
            _userDB.getPurchasedSong(assignedId).length,
            0,
            "Purchased song IDs array should be empty after revert"
        );
    }

    function test_unit_revert_UserDB__deleteSong__Unauthorized() public {
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
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.addSongs(assignedId, songsBefore);
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _userDB.deleteSong(assignedId, 104);
        vm.stopPrank();

        uint256[] memory purchasedSongs = _userDB.getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songsBefore,
            "Purchased song IDs should be unchanged after revert"
        );
    }

    function test_unit_revert_UserDB__deleteSong__UserDoesNotExist() public {
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
        vm.expectRevert(UserDB.UserDoesNotExist.selector);
        _userDB.deleteSong(1, 104);
        vm.stopPrank();
    }

    function test_unit_revert_UserDB__deleteSong__UserIsBanned() public {
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
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.addSongs(assignedId, songsBefore);
        _userDB.setBannedStatus(assignedId, true);
        vm.expectRevert(UserDB.UserIsBanned.selector);
        _userDB.deleteSong(assignedId, 104);
        vm.stopPrank();

        uint256[] memory purchasedSongs = _userDB.getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songsBefore,
            "Purchased song IDs should be unchanged after revert"
        );
    }

    function test_unit_revert_UserDB__addSongs__Unauthorized() public {
        uint256[] memory songsBefore = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            songsBefore[i] = i + 100;
        }
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        vm.stopPrank();
        vm.startPrank(USER.Address);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _userDB.addSongs(assignedId, songsBefore);
        vm.stopPrank();

        assertEq(
            _userDB.getPurchasedSong(assignedId).length,
            0,
            "Purchased song IDs array should be empty after revert"
        );
    }

    function test_unit_revert_UserDB__addSongs__UserIsBanned() public {
        uint256[] memory songsBefore = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            songsBefore[i] = i + 100;
        }
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.setBannedStatus(assignedId, true);
        vm.expectRevert(UserDB.UserIsBanned.selector);
        _userDB.addSongs(assignedId, songsBefore);
        vm.stopPrank();

        assertEq(
            _userDB.getPurchasedSong(assignedId).length,
            0,
            "Purchased song IDs array should be empty after revert"
        );
    }

    function test_unit_revert_UserDB__addSongs__UserDoesNotExist() public {
        uint256[] memory songsBefore = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            songsBefore[i] = i + 100;
        }
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        vm.expectRevert(UserDB.UserDoesNotExist.selector);
        _userDB.addSongs(1, songsBefore);
        vm.stopPrank();

        assertEq(
            _userDB.getPurchasedSong(1).length,
            0,
            "Purchased song IDs array should be empty after revert"
        );
    }

    /*
    

    

    

    function test_unit_revert_UserDB__deleteSongs() public {
        uint256[] memory songsBefore = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            songsBefore[i] = i + 100;
        }
        uint256[] memory songsAfter = new uint256[](8);
        songsAfter[0] = 100;
        songsAfter[1] = 101;
        songsAfter[2] = 102;
        songsAfter[3] = 103;
        //songToDelete  104;
        songsAfter[4] = 105;
        songsAfter[5] = 106;
        songsAfter[6] = 107;
        //songToDelete  108;
        songsAfter[7] = 109;

        uint256[] memory songsToDelete = new uint256[](2);
        songsToDelete[0] = 104;
        songsToDelete[1] = 108;

        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.addSongs(assignedId, songsBefore);
        _userDB.deleteSongs(assignedId, songsToDelete);
        vm.stopPrank();

        uint256[] memory purchasedSongs = _userDB.getPurchasedSong(assignedId);

        assertEq(
            purchasedSongs,
            songsAfter,
            "Purchased song IDs array should have the correct entries after removal"
        );
    }

    function test_unit_revert_UserDB__addBalance() public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.addBalance(assignedId, 100);
        vm.stopPrank();

        assertEq(
            _userDB.getBalance(assignedId),
            100,
            "Balance should be updated correctly"
        );
    }

    function test_unit_revert_UserDB__deductBalance() public {
        uint256[] memory songs = new uint256[](1);
        songs[0] = 101;
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.addBalance(assignedId, 100);
        _userDB.deductBalance(assignedId, 50);
        vm.stopPrank();

        assertEq(
            _userDB.getBalance(assignedId),
            50,
            "Balance should be updated correctly"
        );
    }

    function test_unit_revert_UserDB__setBannedStatus() public {
        vm.startPrank(FAKE_ORCHESTRATOR.Address);
        uint256 assignedId = _userDB.register(
            "User Name",
            "ipfs://metadataURI",
            USER.Address
        );
        _userDB.setBannedStatus(assignedId, true);
        vm.stopPrank();

        assertTrue(
            _userDB.getMetadata(assignedId).IsBanned,
            "User should be marked as banned"
        );
    }
    */
}
