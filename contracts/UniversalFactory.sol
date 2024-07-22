// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IProject.sol";
import "./proxies/VerifyingProxy.sol";

contract UniversalFactory {
    event CreatedProxy(address indexed proxy);

    address public immutable projectRegistry;
    address public immutable ioIDStore;

    constructor(address _ioIDStore, address _projectRegistry) {
        ioIDStore = _ioIDStore;
        projectRegistry = _projectRegistry;
    }

    function create(
        ProjectType _type,
        address _verifier,
        string calldata _projectName,
        string calldata _name,
        string calldata _symbol,
        uint256 _amount
    ) external payable returns (address) {
        VerifyingProxy proxy = new VerifyingProxy(ioIDStore, projectRegistry);

        proxy.initialize{value: msg.value}(_type, _verifier, _projectName, _name, _symbol, _amount);
        proxy.transferOwnership(msg.sender);

        emit CreatedProxy(address(proxy));

        return address(proxy);
    }
}
