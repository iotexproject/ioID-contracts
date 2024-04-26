// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IProject.sol";
import "./interfaces/IioIDFactory.sol";

contract ioIDFactory is IioIDFactory, OwnableUpgradeable {
    event SetIoID(address indexed ioID);

    address public project;
    address public ioID;
    uint256 public override price;
    mapping(uint256 => address) public override projectPresaleContract;
    mapping(address => uint256) public override presaleContractProject;
    mapping(uint256 => uint256) public override projectAppliedAmount;
    mapping(uint256 => uint256) public override projectActivedAmount;

    function initialize(address _project) public initializer {
        __Ownable_init();

        project = _project;
        price = 1000 ether;
        emit ChangePrice(price);
    }

    function applyIoID(uint256 projectId, address presaleNFT, uint256 amount) external payable override {
        require(amount * price >= msg.value, "insufficient fund");
        require(IProject(project).ownerOf(projectId) == msg.sender, "invald project owner");
        require(presaleNFT != address(0), "zero address");
        if (projectPresaleContract[projectId] != address(0)) {
            presaleNFT = projectPresaleContract[projectId];
        } else {
            projectPresaleContract[projectId] = presaleNFT;
            presaleContractProject[presaleNFT] = projectId;
        }
        unchecked {
            projectAppliedAmount[projectId] += amount;
        }
        emit ApplyIoID(projectId, presaleNFT, amount);
    }

    function activeIoID(uint256 projectId) external override {
        require(ioID == msg.sender, "only ioID");
        require(projectAppliedAmount[projectId] > 0, "insufficient ioID");

        unchecked {
            projectAppliedAmount[projectId] -= 1;
        }
        emit ActiveIoID(projectId);
    }

    function changePrice(uint256 _price) external override onlyOwner {
        price = _price;
        emit ChangePrice(_price);
    }

    function setIoID(address _ioID) external onlyOwner {
        ioID = _ioID;
        emit SetIoID(_ioID);
    }
}
