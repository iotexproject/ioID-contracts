// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IProfileResolver.sol";

abstract contract BaseResolver is ERC165 {
    function isAuthorised(uint256 _id) internal view virtual returns (bool);

    modifier authorised(uint256 _id) {
        require(isAuthorised(_id), "not authorised");
        _;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceID);
    }
}
