// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IProfileResolver {
    event ChangeName(uint256 indexed id, string name);
    event ChangeAvatar(uint256 indexed id, string uri);

    function name(uint256 _id) external view returns (string memory);
    function avatar(uint256 _id) external view returns (string memory);
}
