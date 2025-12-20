// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
                                                            
 * @title Shine ArtistDB Contract
 * @author 11:11 Labs 
 * @notice This contract manages artist registrations and their associated data.
 */

import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

contract UserDB {

    struct AddressTypeProposal {
        address current;
        address proposed;
        uint256 timeToExecuteProposal;
    }

    struct User {
        string name;
        string metadataURI;
        address payable userAddress;
        uint256 amount;
        uint256 accumulatedRoyalties;
        uint256[] purchasedSongIds;
    }

    uint256 _nextTokenId;

    AddressTypeProposal private apiCaller;

    mapping(uint256 => User) users;

    modifier onlyAPICaller() {
        if (msg.sender != apiCaller.current) {
            revert();
        }
        _;
    }

    
    
}
