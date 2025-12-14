// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.13;

/**
   ____                         
  / _____________  _______      
 / _// __/ __/ _ \/ __(_-<      
/___/_/ /_/  \___/_/ /___/      
                                
   __   _ __                    
  / /  (_/ /  _______ _______ __
 / /__/ / _ \/ __/ _ `/ __/ // /
/____/_/_.__/_/  \_,_/_/  \_, / 
                         /___/  

 * @title Errors Library
 * @author 11:11 Labs
 * @notice This library defines custom errors for the Shine platform.
 */

library ErrorsLib {
    error UnauthorizedCaller();
    error InvalidProposalExecution();
}
