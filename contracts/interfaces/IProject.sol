// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

enum ProjectType {
    Hardware,
    Virtual
}

interface IProject is IERC721 {
    function mint(address _owner) external returns (uint256 projectId_);
    function mint(address _owner, string calldata _name) external returns (uint256 projectId_);
    function mint(address _owner, string calldata _name, ProjectType _type) external returns (uint256 projectId_);

    function count() external view returns (uint256);
    function name(uint256 _projectId) external view returns (string memory);
    function projectType(uint256 _projectId) external view returns (ProjectType);
}

interface IProjectRegistry {
    function project() external returns (IProject);

    function register(string calldata _name, ProjectType _type) external payable returns (uint256);
}
