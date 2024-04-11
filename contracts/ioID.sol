// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IProject} from "./interfaces/IProject.sol";
import {IERC6551Registry} from "./interfaces/IERC6551Registry.sol";

contract ioID is ERC721Upgradeable {
    event IDCreated(uint256 indexed projectId, address indexed owner, uint256 id);
    event WalletCreated(uint256 indexed id, address indexed wallet);

    uint256 nextId;
    address public project;
    address public registry;
    address public implementation;

    // projectId => project created count
    mapping(uint256 => uint256) public projectCreated;
    // ioID => projectId
    mapping(uint256 => uint256) public projectId;

    function initialize(
        address _project,
        address _registry,
        address _implementation,
        string calldata _name,
        string calldata _symbol
    ) public initializer {
        __ERC721_init(_name, _symbol);
        project = _project;
        registry = _registry;
        implementation = _implementation;
    }

    function createWallet(uint256 _id) external returns (address wallet_) {
        _requireMinted(_id);
        wallet_ = IERC6551Registry(registry).createAccount(implementation, 0, block.chainid, address(this), _id);
        emit WalletCreated(_id, wallet_);
    }

    function wallet(uint256 _id) external view returns (address) {
        return IERC6551Registry(registry).account(implementation, 0, block.chainid, address(this), _id);
    }

    function create(uint256 _projectId, address _owner) external returns (uint256) {
        require(IProject(project).ownerOf(_projectId) == msg.sender, "not project owner");
        // TODO: check project mint privilege

        return _create(_projectId, _owner);
    }

    function create(uint256 _projectId, address[] calldata _owners) external returns (uint256[] memory) {
        require(IProject(project).ownerOf(_projectId) == msg.sender, "not project owner");
        // TODO: check project mint privilege

        uint256[] memory _ids = new uint256[](_owners.length);
        for (uint i = 0; i < _owners.length; i++) {
            _ids[i] = _create(_projectId, _owners[i]);
        }

        return _ids;
    }

    function _create(uint256 _projectId, address _owner) internal returns (uint256 id_) {
        id_ = ++nextId;
        projectCreated[_projectId] += 1;
        projectId[id_] = _projectId;
        _mint(_owner, id_);
        emit IDCreated(_projectId, _owner, id_);
    }
}
