// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IProject.sol";
import "./interfaces/IioIDStore.sol";

contract ioIDStore is IioIDStore, OwnableUpgradeable {
    event SetIoIDRegistry(address indexed ioIDRegistry);

    address public project;
    address public override ioIDRegistry;
    uint256 public override price;
    mapping(uint256 => address) public override projectDeviceContract;
    mapping(address => uint256) public override deviceContractProject;
    mapping(uint256 => uint256) public override projectAppliedAmount;
    mapping(uint256 => uint256) public override projectActivedAmount;

    function initialize(address _project, uint256 _price) public initializer {
        __Ownable_init();

        project = _project;
        price = _price;
        ioIDRegistry = msg.sender;
        emit Initialize(_project, _price);
    }

    function applyIoIDs(uint256 _projectId, uint256 _amount) external payable override {
        require(IERC721(project).ownerOf(_projectId) == msg.sender, "invald project owner");
        require(IProject(project).projectType(_projectId) == 0, "only hardware project");
        require(msg.value >= _amount * price, "insufficient fund");
        unchecked {
            projectAppliedAmount[_projectId] += _amount;
        }
        emit ApplyIoIDs(_projectId, _amount);
    }

    function setDeviceContract(uint256 _projectId, address _contract) external override {
        require(IERC721(project).ownerOf(_projectId) == msg.sender, "invald project owner");
        require(projectDeviceContract[_projectId] == address(0), "project setted");
        require(deviceContractProject[_contract] == 0, "contract setted");

        projectDeviceContract[_projectId] = _contract;
        deviceContractProject[_contract] = _projectId;
        emit SetDeviceContract(_projectId, _contract);
    }

    function changeDeviceContract(uint256 _projectId, address _contract) external override onlyOwner {
        require(deviceContractProject[_contract] == 0, "contract setted");

        projectDeviceContract[_projectId] = _contract;
        deviceContractProject[_contract] = _projectId;
        emit SetDeviceContract(_projectId, _contract);
    }

    function activeIoID(uint256 _projectId) external payable override {
        require(ioIDRegistry == msg.sender, "only ioIDRegistry");
        if (IProject(project).projectType(_projectId) == 0) {
            require(projectAppliedAmount[_projectId] > projectActivedAmount[_projectId], "insufficient ioID");
        } else {
            require(msg.value >= price, "insufficient fund");
            unchecked {
                projectAppliedAmount[_projectId] += 1;
            }
        }

        unchecked {
            projectActivedAmount[_projectId] += 1;
        }
        emit ActiveIoID(_projectId);
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

        for (uint256 i = 0; i < _recipicents.length; i++) {
            (bool success, ) = _recipicents[i].call{value: _amounts[i]}("");
            require(success, "transfer fail");
        }
    }
}
