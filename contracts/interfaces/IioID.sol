// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IioID {
    function wallet(uint256 _id) external view returns (address wallet_, string memory did_);

    function mint(uint256 _projectId, address _device, address _owner) external returns (uint256);

    function removeDID(address _device) external;
}
