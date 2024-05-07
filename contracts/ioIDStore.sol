// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IProject.sol";
import "./interfaces/IioIDStore.sol";

contract ioIDStore is IioIDStore, OwnableUpgradeable {
    event SetIoIDRegistry(address indexed ioIDRegistry);

    address public project;
    address public ioIDRegistry;
    uint256 public override price;
    mapping(uint256 => address) public override projectDeviceContract;
    mapping(address => uint256) public override deviceContractProject;
    mapping(uint256 => uint256) public override projectAppliedAmount;
    mapping(uint256 => uint256) public override projectActivedAmount;

    function initialize(address _project) public initializer {
        __Ownable_init();

        project = _project;
        price = 1000 ether;
        ioIDRegistry = msg.sender;
        emit ChangePrice(price);
    }

    function applyIoIDs(uint256 _projectId, address _projectDevice, uint256 _amount) external payable override {
        require(msg.value >= _amount * price, "insufficient fund");
        require(IProject(project).ownerOf(_projectId) == msg.sender, "invald project owner");
        require(_projectDevice != address(0), "zero address");
        if (projectDeviceContract[_projectId] != address(0)) {
            _projectDevice = projectDeviceContract[_projectId];
        } else {
            projectDeviceContract[_projectId] = _projectDevice;
            deviceContractProject[_projectDevice] = _projectId;
        }
        unchecked {
            projectAppliedAmount[_projectId] += _amount;
        }
        emit ApplyIoIDs(_projectId, _projectDevice, _amount);
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
