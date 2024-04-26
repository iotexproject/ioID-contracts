// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IioIDFactory {
    event ApplyIoID(uint256 indexed projectId, address indexed presaleNFT, uint256 amount);
    event ActiveIoID(uint256 indexed projectId);

    event ChangePrice(uint256 indexed price);

    function price() external view returns (uint256);

    function projectPresaleContract(uint256 _projectId) external view returns (address);
    function presaleContractProject(address _contract) external view returns (uint256);

    function projectAppliedAmount(uint256 _projectId) external view returns (uint256);

    function projectActivedAmount(uint256 _projectId) external view returns (uint256);

    function applyIoID(uint256 _projectId, address _presaleNFT, uint256 _amount) external payable;

    function activeIoID(uint256 _projectId) external;

    function changePrice(uint256 _price) external;
}
