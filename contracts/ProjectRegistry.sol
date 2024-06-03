// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IProject.sol";

contract ProjectRegistry is Initializable {
    IProject public project;

    function initialize(address _project) public initializer {
        project = IProject(_project);
    }

    // @deprecated
    function register() external payable returns (uint256) {
        return project.mint(msg.sender);
    }

    function register(string calldata _name) external payable returns (uint256) {
        return project.mint(msg.sender, _name);
    }
}
