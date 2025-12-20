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

import {OwnableRoles} from "@solady/auth/OwnableRoles.sol";

abstract contract RoleUtils is OwnableRoles {
    uint256 constant ORCHESTRATOR_ROLE = 1;
    uint256 constant API_ROLE = 2;

    constructor(
        address initialAdmin,
        address initialOrchestratorAddress,
        address initialAPIAddress
    ) {
        _initializeOwner(initialAdmin);
        _grantRoles(initialOrchestratorAddress, ORCHESTRATOR_ROLE);
        _grantRoles(initialAPIAddress, API_ROLE);
    }


    function setAPIRole(address apiAddress) external onlyOwner {
        _grantRoles(apiAddress, API_ROLE);
    }

    function setOrchestratorRole(address orchestratorAddress) external onlyOwner {
        _grantRoles(orchestratorAddress, ORCHESTRATOR_ROLE);
    }

    function revokeOrchestratorRole(address orchestratorAddress) external onlyOwner {
        _removeRoles(orchestratorAddress, ORCHESTRATOR_ROLE);
    }

    function revokeAPIRole(address apiAddress) external onlyOwner {
        _removeRoles(apiAddress, API_ROLE);
    }


}
