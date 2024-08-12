// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IProject.sol";
import "./proxies/VerifyingProxy.sol";

contract UniversalFactory {
    using Clones for address;

    event CreatedProxy(address indexed proxy);

    address public immutable proxyImplementation;

    constructor(address _proxyImplementation) {
        proxyImplementation = _proxyImplementation;
    }

    function create(
        uint8 _type,
        address _verifier,
        string calldata _projectName,
        string calldata _name,
        string calldata _symbol,
        uint256 _amount
    ) external payable returns (address) {
        bytes32 _salt = keccak256(abi.encodePacked(msg.sender, _type, _name));
        address _instance = proxyImplementation.cloneDeterministic(_salt);
        VerifyingProxy proxy = VerifyingProxy(_instance);

        proxy.initialize{value: msg.value}(_type, _verifier, _projectName, _name, _symbol, _amount);
        proxy.transferOwnership(msg.sender);

        emit CreatedProxy(address(proxy));

        return address(proxy);
    }
}
