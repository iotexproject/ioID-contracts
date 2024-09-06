// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ProfileResolver} from "./ProfileResolver.sol";

contract PublicResolver is ProfileResolver {
    IERC721 public ioID;

    constructor(address _ioID) {
        ioID = IERC721(_ioID);
    }

    function isAuthorised(uint256 _id) internal view virtual override returns (bool) {
        return ioID.ownerOf(_id) == msg.sender;
    }

    function supportsInterface(bytes4 interfaceID) public view override(ProfileResolver) returns (bool) {
        return super.supportsInterface(interfaceID);
    }
}
