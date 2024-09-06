// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IProfileResolver.sol";
import {BaseResolver} from "./BaseResolver.sol";

abstract contract ProfileResolver is IProfileResolver, BaseResolver {
    mapping(uint256 => string) names;
    mapping(uint256 => string) avatars;

    function setName(uint256 _id, string calldata _name) external authorised(_id) {
        names[_id] = _name;
        emit ChangeName(_id, _name);
    }

    function setAvatar(uint256 _id, string calldata _avatar) external authorised(_id) {
        avatars[_id] = _avatar;
        emit ChangeAvatar(_id, _avatar);
    }

    function name(uint256 _id) external view override returns (string memory) {
        return names[_id];
    }

    function avatar(uint256 _id) external view override returns (string memory) {
        return avatars[_id];
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IProfileResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}
