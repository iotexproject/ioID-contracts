// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDeviceNFT {
    function weight(uint256 tokenId) external view returns (uint256);
}
