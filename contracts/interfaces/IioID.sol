// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IioID {
    function deviceProject(address _device) external view returns (uint256);

    function projectDeviceCount(uint256 _projectId) external view returns (uint256);

    function projectIDs(
        uint256 _projectId,
        address _start,
        uint256 _pageSize
    ) external view returns (address[] memory array, address next);

    function did(address _device) external view returns (string memory);

    function wallet(uint256 _id) external view returns (address wallet_, string memory did_);

    function mint(uint256 _projectId, address _device, address _owner) external returns (uint256);

    function removeDID(address _device) external;
}
