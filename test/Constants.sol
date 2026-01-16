// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {AlbumDB} from "@shine/contracts/database/AlbumDB.sol";
import {ArtistDB} from "@shine/contracts/database/ArtistDB.sol";
import {SongDB} from "@shine/contracts/database/SongDB.sol";
import {UserDB} from "@shine/contracts/database/UserDB.sol";
import {Orchestrator} from "@shine/contracts/orchestrator/Orchestrator.sol";

abstract contract Constants is Test {
    ///@dev this are the contract instances used in separate tests 
    AlbumDB _albumDB;
    ArtistDB _artistDB;
    SongDB _songDB;
    UserDB _userDB;

    ///@dev these are the contract instances used in conjunction with orchestrator
    AlbumDB albumDB;
    ArtistDB artistDB;
    SongDB songDB;
    UserDB userDB;
    Orchestrator orchestrator;

    MockUsdc usdc;

    struct AccountData {
        address Address;
        uint256 PrivateKey;
    }

    AccountData ACCOUNT1 =
        AccountData({
            Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            PrivateKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        });

    AccountData ACCOUNT2 =
        AccountData({
            Address: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            PrivateKey: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        });

    AccountData ACCOUNT3 =
        AccountData({
            Address: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
            PrivateKey: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
        });

    AccountData ACCOUNT4 =
        AccountData({
            Address: 0x90F79bf6EB2c4f870365E785982E1f101E93b906,
            PrivateKey: 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
        });

    AccountData ACCOUNT5 =
        AccountData({
            Address: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
            PrivateKey: 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
        });

    AccountData ACCOUNT6 =
        AccountData({
            Address: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
            PrivateKey: 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
        });

    AccountData ACCOUNT7 =
        AccountData({
            Address: 0x976EA74026E726554dB657fA54763abd0C3a0aa9,
            PrivateKey: 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
        });

    AccountData ACCOUNT8 =
        AccountData({
            Address: 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955,
            PrivateKey: 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
        });

    AccountData FAKE_ORCHESTRATOR = ACCOUNT1;
    AccountData ADMIN = ACCOUNT2;
    AccountData API = ACCOUNT3;
    AccountData SUDO = ACCOUNT4;
    AccountData USER = ACCOUNT5;
    AccountData ARTIST = ACCOUNT6;

    function setUp() public {

        usdc = new MockUsdc();

        orchestrator = new Orchestrator(
            ADMIN.Address,
            address(usdc)
        );

        albumDB = new AlbumDB(address(orchestrator));
        artistDB = new ArtistDB(address(orchestrator));
        songDB = new SongDB(address(orchestrator));
        userDB = new UserDB(address(orchestrator));

        orchestrator.setDatabaseAddresses(
            address(albumDB),
            address(artistDB),
            address(songDB),
            address(userDB)
        );        


        executeBeforeSetUp();
    }

    function executeBeforeSetUp() internal virtual {}
}

contract MockUsdc is ERC20 {
    
    function name() public pure override returns (string memory) {
        return "USD Coin";
    }

    function symbol() public pure override returns (string memory) {
        return "USDC";
    }
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
