// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PebbleRegistration {
    mapping(bytes32 => address) devices;
    mapping(bytes32 => address) owners;

    function register(string calldata imei, address device, address owner) external {
        bytes32 deviceKey = keccak256(abi.encodePacked(imei));
        devices[deviceKey] = device;
        owners[deviceKey] = owner;
    }

    function find(string memory imei) external view returns (address device, address owner, bytes32 sn) {
        bytes32 deviceKey = keccak256(abi.encodePacked(imei));
        device = devices[deviceKey];
        owner = owners[deviceKey];
        sn = deviceKey;
    }
}
