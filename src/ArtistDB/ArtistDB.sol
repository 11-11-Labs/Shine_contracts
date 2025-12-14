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

import {ErrorsLib} from "@shine/ArtistDB/lib/ErrorsLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

contract ArtistDB {

    struct AddressTypeProposal {
        address current;
        address proposed;
        uint256 timeToExecuteProposal;
    }

    struct Artist {
        string name;
        string metadataURI;
        address payable artistAddress;
        uint256 totalEarnings;
        uint256 accumulatedRoyalties;
    }

    uint256 _nextTokenId;

    AddressTypeProposal private apiCaller;

    mapping(uint256 => Artist) artists;

    modifier onlyAPICaller() {
        if (msg.sender != apiCaller.current) {
            revert ErrorsLib.UnauthorizedCaller();
        }
        _;
    }

    function registerArtist(
        string memory name,
        string memory metadataURI,
        address payable artistAddress
    ) external returns (uint256) {
        _nextTokenId++;

        artists[_nextTokenId] = Artist({
            name: name,
            metadataURI: metadataURI,
            artistAddress: artistAddress,
            totalEarnings: 0,
            accumulatedRoyalties: 0
        });

        return _nextTokenId;
    }

    function proposeAPICallerChange(address newAPICaller) onlyAPICaller external {
        apiCaller.proposed = newAPICaller;
        apiCaller.timeToExecuteProposal = block.timestamp + 1 days;
    }

    function cancelAPICallerChange() onlyAPICaller external {
        apiCaller.proposed = address(0);
        apiCaller.timeToExecuteProposal = 0;
    }

    function executeAPICallerChange() onlyAPICaller external {
        if (
            apiCaller.proposed == address(0) ||
            block.timestamp < apiCaller.timeToExecuteProposal
        ) {
            revert ErrorsLib.InvalidProposalExecution();
        }

        apiCaller.current = apiCaller.proposed;
        apiCaller.proposed = address(0);
        apiCaller.timeToExecuteProposal = 0;
    }

    function getArtist(uint256 artistId) external view returns (Artist memory) {
        return artists[artistId];
    }
}
