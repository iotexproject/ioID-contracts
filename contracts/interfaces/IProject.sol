// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IProject {
    function mint(address _owner) external returns (uint256 projectId_);
    function mint(address _owner, string calldata _name) external returns (uint256 projectId_);
    function mint(address _owner, string calldata _name, uint8 _type) external returns (uint256 projectId_);

    function count() external view returns (uint256);
    function name(uint256 _projectId) external view returns (string memory);
    function projectType(uint256 _projectId) external view returns (uint8);
}

interface IProjectRegistry {
    function project() external returns (IProject);

    function register(string calldata _name, uint8 _type) external payable returns (uint256);
}
