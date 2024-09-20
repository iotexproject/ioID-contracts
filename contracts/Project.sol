// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import {IProject} from "./interfaces/IProject.sol";

contract Project is IProject, OwnableUpgradeable, ERC721Upgradeable {
    event SetMinter(address indexed minter);
    event SetName(uint256 indexed projectId, string name);
    event AddMetadata(uint256 indexed projectId, string name, bytes32 key, bytes value);
    event AddOperator(uint256 indexed projectId, address operator);
    event RemoveOperator(uint256 indexed projectId, address operator);

    address public minter;
    uint256 nextProjectId;
    bytes32 constant EMPTY_NAME_HASH = keccak256(abi.encodePacked(""));
    mapping(bytes32 => bool) nameHashes;
    mapping(uint256 => string) names;
    mapping(uint256 => uint8) types;
    mapping(uint256 => mapping(bytes32 => bytes)) _metadata;
    mapping(uint256 => mapping(address => bool)) operators;

    modifier onlyMinter() {
        require(msg.sender == minter, "not minter");
        _;
    }

    modifier onlyProjectOwner(uint256 projectId) {
        require(msg.sender == ownerOf(projectId), "invalid owner");
        _;
    }

    modifier onlyProjectOperator(uint256 projectId) {
        require(msg.sender == ownerOf(projectId) || operators[projectId][msg.sender], "invalid operator");
        _;
    }

    function initialize(string calldata _name, string calldata _symbol) public initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        setMinter(msg.sender);
    }

    // @deprecated
    function mint(address _owner) external onlyMinter returns (uint256 projectId_) {
        projectId_ = ++nextProjectId;
        _mint(_owner, projectId_);
    }

    function mint(address _owner, string calldata _name) external returns (uint256 projectId_) {
        return _mintProject(_owner, _name, 0);
    }

    function mint(address _owner, string calldata _name, uint8 _type) external returns (uint256) {
        return _mintProject(_owner, _name, _type);
    }

    function _mintProject(
        address _owner,
        string calldata _name,
        uint8 _type
    ) internal onlyMinter returns (uint256 projectId_) {
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

    function projectType(uint256 _projectId) external view returns (uint8) {
        _requireMinted(_projectId);
        return types[_projectId];
    }

    function metadata(uint256 _projectId, string calldata _name) external view returns (bytes memory) {
        _requireMinted(_projectId);
        bytes32 _key = keccak256(abi.encodePacked(_name));
        return _metadata[_projectId][_key];
    }

    function setMetadata(
        uint256 _projectId,
        string calldata _name,
        bytes calldata _value
    ) external onlyProjectOperator(_projectId) {
        bytes32 _key = keccak256(abi.encodePacked(_name));

        _metadata[_projectId][_key] = _value;
        emit AddMetadata(_projectId, _name, _key, _value);
    }

    function setName(uint256 _projectId, string calldata _name) external onlyProjectOwner(_projectId) {
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

    function addOperator(uint256 _projectId, address _operator) external onlyProjectOwner(_projectId) {
        require(!operators[_projectId][_operator], "already operator");

        operators[_projectId][_operator] = true;
        emit AddOperator(_projectId, _operator);
    }

    function removeOperator(uint256 _projectId, address _operator) external onlyProjectOwner(_projectId) {
        require(operators[_projectId][_operator], "not operator");

        operators[_projectId][_operator] = false;
        emit RemoveOperator(_projectId, _operator);
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;

        emit SetMinter(_minter);
    }

    function count() external view returns (uint256) {
        return nextProjectId;
    }
}
