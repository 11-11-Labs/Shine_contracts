// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Constants} from "testing/Constants.sol";
import {ArtistDB} from "@shine/contracts/database/ArtistDB.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";
import {ErrorsLib} from "@shine/contracts/orchestrator/library/ErrorsLib.sol";

contract Orchestrator_test_unit_revert_UserArtist is Constants {
    function test_unit_revert_chnageBasicData_AddressIsNotOwnerOfArtistId()
        public
    {
        uint256 artistId = _execute_orchestrator_register(
            true,
            "initial_artist",
            "https://arweave.net/initialURI",
            ARTIST_1.Address
        );

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfArtistId.selector);
        orchestrator.chnageBasicData(
            true,
            artistId,
            "updated_artist",
            "https://arweave.net/updatedURI"
        );
        vm.stopPrank();
    }

    function test_unit_revert_chnageBasicData_AddressIsNotOwnerOfUserId()
        public
    {
        uint256 userId = _execute_orchestrator_register(
            false,
            "initial_user",
            "https://arweave.net/initialUserURI",
            USER.Address
        );

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.chnageBasicData(
            false,
            userId,
            "updated_user",
            "https://arweave.net/updatedUserURI"
        );
        vm.stopPrank();
    }

    function test_unit_revert_changeAddress_AddressIsNotOwnerOfArtistId()
        public
    {
        uint256 artistId = _execute_orchestrator_register(
            true,
            "artist_name",
            "https://arweave.net/artistURI",
            ARTIST_1.Address
        );

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfArtistId.selector);
        orchestrator.changeAddress(true, artistId, WILDCARD_ACCOUNT.Address);
        vm.stopPrank();
    }

    function test_unit_revert_changeAddress_AddressIsNotOwnerOfUserId() public {
        uint256 userId = _execute_orchestrator_register(
            false,
            "user_name",
            "https://arweave.net/userURI",
            USER.Address
        );

        vm.startPrank(WILDCARD_ACCOUNT.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotOwnerOfUserId.selector);
        orchestrator.changeAddress(false, userId, WILDCARD_ACCOUNT.Address);
        vm.stopPrank();
    }
}
