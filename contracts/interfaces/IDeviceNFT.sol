// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDeviceNFT {
    function mint(address _device, address _owner) external returns (uint256);

    function removeDID(address _device) external;
}
