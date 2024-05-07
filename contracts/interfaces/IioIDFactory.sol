// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IioIDFactory {
    event ApplyIoID(uint256 indexed projectId, address indexed deviceNFT, uint256 amount);
    event ActiveIoID(uint256 indexed projectId);

    event ChangePrice(uint256 indexed price);

    function price() external view returns (uint256);

    function projectNftContract(uint256 _projectId) external view returns (address);
    function nftContractProject(address _contract) external view returns (uint256);

    function projectAppliedAmount(uint256 _projectId) external view returns (uint256);
    function projectActivedAmount(uint256 _projectId) external view returns (uint256);

    function applyIoID(uint256 _projectId, address _nft, uint256 _amount) external payable;

    function activeIoID(uint256 _projectId) external;

    function changePrice(uint256 _price) external;
}
