// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import {ProjectType} from "./interfaces/IProject.sol";

contract Project is OwnableUpgradeable, ERC721Upgradeable {
    event SetMinter(address indexed minter);
    event SetName(uint256 indexed projectId, string name);

    address public minter;
    uint256 nextProjectId;
    bytes32 constant EMPTY_NAME_HASH = keccak256(abi.encodePacked(""));
    mapping(bytes32 => bool) nameHashes;
    mapping(uint256 => string) names;
    mapping(uint256 => ProjectType) types;

    function initialize(string calldata _name, string calldata _symbol) public initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        setMinter(msg.sender);
    }

    // @deprecated
    function mint(address _owner) external returns (uint256 projectId_) {
        require(msg.sender == minter, "not minter");

        projectId_ = ++nextProjectId;
        _mint(_owner, projectId_);
    }

    function mint(address _owner, string calldata _name) external returns (uint256 projectId_) {
        return _mintProject(_owner, _name, ProjectType.Hardware);
    }

    function mint(address _owner, string calldata _name, ProjectType _type) external returns (uint256) {
        return _mintProject(_owner, _name, _type);
    }

    function _mintProject(
        address _owner,
        string calldata _name,
        ProjectType _type
    ) internal returns (uint256 projectId_) {
        require(msg.sender == minter, "not minter");
        bytes32 _nameHash = keccak256(abi.encodePacked(_name));
        require(_nameHash != EMPTY_NAME_HASH, "empty name");
        require(!nameHashes[_nameHash], "exist name");

        projectId_ = ++nextProjectId;

        _mint(_owner, projectId_);
        names[projectId_] = _name;
        types[projectId_] = _type;
        nameHashes[_nameHash] = true;
        emit SetName(projectId_, _name);
    }

    function name(uint256 _projectId) external view returns (string memory) {
        _requireMinted(_projectId);
        return names[_projectId];
    }

    function projectType(uint256 _projectId) external view returns (ProjectType) {
        _requireMinted(_projectId);
        return types[_projectId];
    }

    function setName(uint256 _projectId, string calldata _name) external {
        require(msg.sender == ownerOf(_projectId), "invalid owner");
        bytes32 _nameHash = keccak256(abi.encodePacked(_name));
        require(_nameHash != EMPTY_NAME_HASH, "empty name");
        require(!nameHashes[_nameHash], "exist name");

        bytes32 _originNameHash = keccak256(abi.encodePacked(names[_projectId]));
        if (_originNameHash != EMPTY_NAME_HASH) {
            nameHashes[_originNameHash] = false;
        }
        names[_projectId] = _name;
        nameHashes[_nameHash] = true;
        emit SetName(_projectId, _name);
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;

        emit SetMinter(_minter);
    }

    function count() external view returns (uint256) {
        return nextProjectId;
    }
}
