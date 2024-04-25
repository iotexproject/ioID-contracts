// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IioIDRegistry {
    function documentID(address device) external pure returns (string memory);
    function deviceTokenId(address device) external view returns (uint256);
}
