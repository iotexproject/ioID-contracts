// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IProject.sol";
import "./interfaces/IioIDFactory.sol";

contract ioIDFactory is IioIDFactory, OwnableUpgradeable {
    event SetIoIDRegistry(address indexed ioIDRegistry);

    address public project;
    address public ioIDRegistry;
    uint256 public override price;
    mapping(uint256 => address) public override projectDeviceNFTContract;
    mapping(address => uint256) public override deviceNFTContractProject;
    mapping(uint256 => uint256) public override projectAppliedAmount;
    mapping(uint256 => uint256) public override projectActivedAmount;

    function initialize(address _project) public initializer {
        __Ownable_init();

        project = _project;
        price = 1000 ether;
        ioIDRegistry = msg.sender;
        emit ChangePrice(price);
    }

    function applyIoID(uint256 projectId, address deviceNFT, uint256 amount) external payable override {
        require(msg.value >= amount * price, "insufficient fund");
        require(IProject(project).ownerOf(projectId) == msg.sender, "invald project owner");
        require(deviceNFT != address(0), "zero address");
        if (projectDeviceNFTContract[projectId] != address(0)) {
            deviceNFT = projectDeviceNFTContract[projectId];
        } else {
            projectDeviceNFTContract[projectId] = deviceNFT;
            deviceNFTContractProject[deviceNFT] = projectId;
        }
        unchecked {
            projectAppliedAmount[projectId] += amount;
        }
        emit ApplyIoID(projectId, deviceNFT, amount);
    }

    function activeIoID(uint256 projectId) external override {
        require(ioIDRegistry == msg.sender, "only ioIDRegistry");
        require(projectAppliedAmount[projectId] > projectActivedAmount[projectId], "insufficient ioID");

        unchecked {
            projectActivedAmount[projectId] += 1;
        }
        emit ActiveIoID(projectId);
    }

    function changePrice(uint256 _price) external override onlyOwner {
        price = _price;
        emit ChangePrice(_price);
    }

    function setIoIDRegistry(address _ioIDRegistry) public onlyOwner {
        ioIDRegistry = _ioIDRegistry;
        emit SetIoIDRegistry(_ioIDRegistry);
    }

    function withdraw(address[] calldata _recipicents, uint256[] calldata _amounts) external onlyOwner {
        require(_recipicents.length == _amounts.length, "invalid request");

        for (uint i = 0; i < _recipicents.length; i++) {
            (bool success, ) = _recipicents[i].call{value: _amounts[i]}("");
            require(success, "transfer fail");
        }
    }
}
