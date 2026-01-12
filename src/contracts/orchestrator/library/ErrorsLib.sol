// SPDX-License-Identifier: SHINE-PPL-1.0
pragma solidity ^0.8.20;

/**
    ___ _ _____  _____ シ
  ,' _//// / / |/ / _/ ャ
 _\ `./ ` / / || / _/  イ
/___,/_n_/_/_/|_/___/  ヌ
                      
                                                            
 * @title Shine ISongDB
 * @author 11:11 Labs 
 * @notice This contract manages song metadata, user purchases, 
 *         and admin functionalities for the Shine platform.
 */

library ErrorsLib {
   error AddressSetupAlreadyDone();
   error AddressIsNotOwnerOfArtistId();
   error AddressIsNotOwnerOfUserId();
   error ArtistIdIsNotPrincipalArtistIdOfSong();

   error SenderIsNotPrincipalArtist();
   
   error TitleCannotBeEmpty();
   error SpecialEditionNameCannotBeEmpty();

   error AlbumIsASpecialEdition();
   error AlbumIsNotASpecialEdition();

   error MustBeGreaterThanCurrent();

   error MaxSupplyMustBeGreaterThanZero();

   error ArtistIdDoesNotExist(uint256 artistId);
   error SongIdDoesNotExist(uint256 songId);
   error UserIdDoesNotExist();


   error InsufficientBalance();


}
