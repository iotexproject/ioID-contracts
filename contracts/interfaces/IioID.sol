// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IioID {
    function mint(uint256 _projectId, address _device, address _owner) external returns (uint256);

    function removeDID(address _device) external;
}
