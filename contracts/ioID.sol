// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IProject} from "./interfaces/IProject.sol";

contract ioID is ERC721Upgradeable {
    uint256 nextId;
    address public project;

    // projectId => project minted count
    mapping(uint256 => uint256) public projectMinted;
    // ioID => projectId
    mapping(uint256 => uint256) public projectId;

    function initialize(address _project, string calldata _name, string calldata _symbol) public initializer {
        __ERC721_init(_name, _symbol);
        project = _project;
    }

    function mint(uint256 _projectId, address _owner) external returns (uint256) {
        require(IProject(project).ownerOf(_projectId) == msg.sender, "not project owner");
        // TODO: check project mint privilege

        return _mint(_projectId, _owner);
    }

    function mint(uint256 _projectId, address[] calldata _owners) external returns (uint256[] memory) {
        require(IProject(project).ownerOf(_projectId) == msg.sender, "not project owner");
        // TODO: check project mint privilege

        uint256[] memory _ids = new uint256[](_owners.length);
        for (uint i = 0; i < _owners.length; i++) {
            _ids[i] = _mint(_projectId, _owners[i]);
        }

        return _ids;
    }

    function _mint(uint256 _projectId, address _owner) internal returns (uint256 id_) {
        id_ = ++nextId;
        projectMinted[_projectId] += 1;
        projectId[id_] = _projectId;
        _mint(_owner, id_);
    }
}
