// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
                                                            
 * @title Id Utility Contract
 * @author 11:11 Labs 
 */

abstract contract IdUtils {
    uint256 internal _id;
    uint256 constant NULL_ID = 0;


    function _getNextId() internal returns (uint256) {
        _id++;
        return _id;
    }

    function peekNextId() public view returns (uint256) {
        return _id + 1;
    }

    function getCurrentId() public view returns (uint256) {
        return _id;
    }

    function exists(uint256 id) public view returns (bool) {
        return _id >= id && id != NULL_ID;
    }
}