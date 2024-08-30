// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IioIDStore {
    event ApplyIoIDs(uint256 indexed projectId, uint256 amount);
    event ActiveIoID(uint256 indexed projectId);
    event SetDeviceContract(uint256 indexed projectId, address indexed deviceContract);

    event Initialize(address indexed project, uint256 price);
    event ChangePrice(uint256 price);

    function price() external view returns (uint256);

    function projectDeviceContract(uint256 _projectId) external view returns (address);
    function deviceContractProject(address _contract) external view returns (uint256);

    function projectAppliedAmount(uint256 _projectId) external view returns (uint256);
    function projectActivedAmount(uint256 _projectId) external view returns (uint256);
    function feeReceiver() external view returns (address);

    function ioIDRegistry() external view returns (address);

    function applyIoIDs(uint256 _projectId, uint256 _amount) external payable;
    function setDeviceContract(uint256 _projectId, address _contract) external;
    function changeDeviceContract(uint256 _projectId, address _contract) external;

    function activeIoID(uint256 _projectId) external payable;

    function changePrice(uint256 _price) external;
}
