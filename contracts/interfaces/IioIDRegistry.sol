// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IioIDRegistry {
    function documentID(address device) external pure returns (string memory);
    function deviceTokenId(address device) external view returns (uint256);

    function registeredNFT(address presaleContract, uint256 tokenId) external view returns (bool);

    function register(
        address presaleContract,
        uint256 tokenId,
        address device,
        bytes32 hash,
        string calldata uri,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
