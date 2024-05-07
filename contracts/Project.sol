// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract Project is OwnableUpgradeable, ERC721Upgradeable {
    event SetMinter(address indexed minter);

    address public minter;
    uint256 nextProjectId;

    function initialize(string calldata _name, string calldata _symbol) public initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        setMinter(msg.sender);
    }

    function mint(address _owner) external returns (uint256 projectId_) {
        require(msg.sender == minter, "not minter");

        projectId_ = ++nextProjectId;

        _mint(_owner, projectId_);
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;

        emit SetMinter(_minter);
    }

    function count() external view returns (uint256) {
        return nextProjectId;
    }
}
