// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDeviceNFT {
    function mint(string calldata _did, address _owner) external returns (uint256);

    function removeDID(string calldata _did) external;
}
