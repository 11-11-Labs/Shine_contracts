// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "testing/Constants.sol";
import {ArtistDB} from "@shine/contracts/database/ArtistDB.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";

contract Orchestrator_test_fuzz_UserArtist is Constants {
    struct RegisterInput {
        bool isArtist;
        string nameOrUsername;
        string metadataURI;
        address userAddress;
    }
    function test_fuzz_register(RegisterInput memory input) public {
        vm.assume(bytes(input.nameOrUsername).length > 0);
        vm.startPrank(input.userAddress);
        uint256 artistId = orchestrator.register(
            input.isArtist,
            input.nameOrUsername,
            input.metadataURI,
            input.userAddress
        );
        vm.stopPrank();

        if (input.isArtist) {
            ArtistDB.Metadata memory artist = artistDB.getMetadata(artistId);

            assertEq(artist.Name, input.nameOrUsername, "Name should match");
            assertEq(
                artist.MetadataURI,
                input.metadataURI,
                "Artist metadata URI should match"
            );
            assertEq(artist.Address, input.userAddress, "Artist address should match");
            assertEq(artist.Balance, 0, "Artist balance should be zero");
            assertEq(
                artist.AccumulatedRoyalties,
                0,
                "Artist accumulated royalties should be zero"
            );
            assertFalse(artist.IsBanned, "Artist should not be banned");
        } else {
            UserDB.Metadata memory user = userDB.getMetadata(artistId);

            assertEq(user.Username, input.nameOrUsername, "Username should match");
            assertEq(
                user.MetadataURI,
                input.metadataURI,
                "User metadata URI should match"
            );
            assertEq(user.Address, input.userAddress, "User address should match");
            assertEq(user.Balance, 0, "User balance should be zero");
            assertEq(
                user.PurchasedSongIds,
                new uint256[](0),
                "User should have no purchased songs"
            );
            assertFalse(user.IsBanned, "User should not be banned");
        }
    }

        
    struct ChangeBasicDataInput {
        address callerAddress;
        string updatedNameOrUsername;
        string updatedMetadataURI;
    }
    function test_fuzz_chnageBasicData_artist(ChangeBasicDataInput memory input) public {
        vm.assume(bytes(input.updatedNameOrUsername).length > 0);
        uint256 artistId = _execute_orchestrator_register(
            true,
            "initial_artist",
            "https://arweave.net/initialURI",
            input.callerAddress
        );

        vm.startPrank(input.callerAddress);
        orchestrator.chnageBasicData(
            true,
            artistId,
            input.updatedNameOrUsername,
            input.updatedMetadataURI
        );
        vm.stopPrank();

        ArtistDB.Metadata memory artist = artistDB.getMetadata(artistId);

        assertEq(artist.Name, input.updatedNameOrUsername, "Updated name should match");
        assertEq(
            artist.MetadataURI,
            input.updatedMetadataURI,
            "Updated metadata URI should match"
        );
    }

    function test_fuzz_chnageBasicData_user(ChangeBasicDataInput memory input) public {
        vm.assume(bytes(input.updatedNameOrUsername).length > 0);
        uint256 userId = _execute_orchestrator_register(
            false,
            "initial_user",
            "https://arweave.net/initialUserURI",
            input.callerAddress
        );

        vm.startPrank(input.callerAddress);
        orchestrator.chnageBasicData(
            false,
            userId,
            input.updatedNameOrUsername,
            input.updatedMetadataURI
        );
        vm.stopPrank();

        UserDB.Metadata memory user = userDB.getMetadata(userId);

        assertEq(
            user.Username,
            input.updatedNameOrUsername,
            "Updated username should match"
        );
        assertEq(
            user.MetadataURI,
            input.updatedMetadataURI,
            "Updated metadata URI should match"
        );
    }

    struct ChangeAddressInput {
        address initialAddress;
        address newAddress;
    }
    function test_fuzz_changeAddress_artist(ChangeAddressInput memory input) public {
        vm.assume(input.initialAddress != input.newAddress);
        vm.assume(input.newAddress != address(0));
        uint256 artistId = _execute_orchestrator_register(
            true,
            "artist_name",
            "https://arweave.net/artistURI",
            input.initialAddress
        );

        vm.startPrank(input.initialAddress);
        orchestrator.changeAddress(true, artistId, input.newAddress);
        vm.stopPrank();

        ArtistDB.Metadata memory artist = artistDB.getMetadata(artistId);

        assertEq(
            artist.Address,
            input.newAddress,
            "Updated address should match"
        );
        assertEq(
            artistDB.getId(input.newAddress),
            artistId,
            "New address should map to correct artist ID"
        );
        assertEq(
            artistDB.getId(input.initialAddress),
            0,
            "Old address should no longer map to any artist ID"
        );
    }

    function test_fuzz_changeAddress_user(ChangeAddressInput memory input) public {
        vm.assume(input.initialAddress != input.newAddress);
        vm.assume(input.newAddress != address(0));
        uint256 userId = _execute_orchestrator_register(
            false,
            "user_name",
            "https://arweave.net/userURI",
            input.initialAddress
        );

        vm.startPrank(input.initialAddress);
        orchestrator.changeAddress(false, userId, input.newAddress);
        vm.stopPrank();

        UserDB.Metadata memory user = userDB.getMetadata(userId);

        assertEq(
            user.Address,
            input.newAddress,
            "Updated address should match"
        );
        assertEq(
            userDB.getId(input.newAddress),
            userId,
            "New address should map to correct user ID"
        );
        assertEq(
            userDB.getId(input.initialAddress),
            0,
            "Old address should no longer map to any user ID"
        );
    }

}
