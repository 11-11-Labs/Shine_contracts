// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SongDB} from "@shine/SongDB/SongDB.sol";

contract SongDBScript is Script {
    address public constant ADMIN = 0x5cBf2D4Bbf834912Ad0bD59980355b57695e8309;
    SongDB public songDataBase;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        songDataBase = new SongDB(ADMIN);

        vm.stopBroadcast();
    }
}
