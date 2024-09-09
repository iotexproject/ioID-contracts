// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Upgradeable, ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import {IERC6551Registry} from "./interfaces/IERC6551Registry.sol";
import "./libraries/LinkedAddressList.sol";
import "./interfaces/IioID.sol";
import "./interfaces/IioIDRegistry.sol";

contract ioID is IioID, ERC721EnumerableUpgradeable {
    using LinkedAddressList for mapping(address => address);

    event CreateIoID(address indexed owner, uint256 id, address wallet, string did);
    event SetMinter(address indexed minter);
    event RemoveDIDWallet(address indexed wallet, string did);
    event SetResolver(uint256 id, address indexed resolver);

    uint256 nextId;
    address public minter;
    address public walletRegistry;
    address public walletImplementation;

    mapping(bytes32 => address) _wallets;
    mapping(uint256 => address) _devices;

    mapping(address => uint256) public override deviceProject;
    mapping(uint256 => uint256) public override projectDeviceCount;
    mapping(uint256 => mapping(address => address)) _projectIDs;
    mapping(uint256 => address) _resolvers;

    function initialize(
        address _minter,
        address _walletRegistry,
        address _walletImplementation,
        string calldata _name,
        string calldata _symbol
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();

        minter = _minter;
        walletRegistry = _walletRegistry;
        walletImplementation = _walletImplementation;
        emit SetMinter(_minter);
    }

    function setMinter(address _minter) external {
        require(_minter != address(0), "zero minter");
        require(minter == msg.sender, "invalid minter");

        minter = _minter;
        emit SetMinter(_minter);
    }

    function wallet(uint256 _id) external view override returns (address wallet_, string memory did_) {
        wallet_ = IERC6551Registry(walletRegistry).account(walletImplementation, 0, block.chainid, address(this), _id);
        address _device = _devices[_id];
        if (_device != address(0)) {
            did_ = IioIDRegistry(minter).documentID(_device);
        }
    }

    function wallet(string calldata _did) external view returns (address) {
        return _wallets[keccak256(abi.encodePacked(_did))];
    }

    function mint(uint256 _projectId, address _device, address _owner) external override returns (uint256) {
        return _mint(_projectId, _device, _owner);
    }

    function _mint(uint256 _projectId, address _device, address _owner) internal returns (uint256 id_) {
        require(minter == msg.sender, "invalid minter");

        id_ = ++nextId;
        _mint(_owner, id_);

        address _wallet = IERC6551Registry(walletRegistry).createAccount(
            walletImplementation,
            0,
            block.chainid,
            address(this),
            id_
        );
        string memory _did = IioIDRegistry(minter).documentID(_device);
        _wallets[keccak256(abi.encodePacked(_did))] = _wallet;
        _devices[id_] = _device;

        mapping(address => address) storage projectIDs_ = _projectIDs[_projectId];
        projectIDs_.add(_device);
        projectDeviceCount[_projectId] += 1;
        deviceProject[_device] = _projectId;

        emit CreateIoID(_owner, id_, _wallet, _did);
    }

    function removeDID(address _device) external {
        require(minter == msg.sender, "invalid minter");

        IioIDRegistry _registry = IioIDRegistry(minter);
        string memory _did = _registry.documentID(_device);

        address _wallet = _wallets[keccak256(abi.encodePacked(_did))];
        require(_wallet != address(0), "wallet not exist");
        delete _wallets[keccak256(abi.encodePacked(_did))];
        uint256 _id = _registry.deviceTokenId(_device);
        delete _devices[_id];

        emit RemoveDIDWallet(_wallet, _did);
    }

    function projectIDs(
        uint256 _projectId,
        address _start,
        uint256 _pageSize
    ) external view override returns (address[] memory array, address next) {
        return _projectIDs[_projectId].page(_start, _pageSize);
    }

    function did(address _device) public view override returns (string memory) {
        return IioIDRegistry(minter).documentID(_device);
    }

    function setResolver(uint256 _id, address _resolver) external override {
        require(ownerOf(_id) == msg.sender, "not ioID owner");
        require(_resolver != address(0), "zero address");
        _resolvers[_id] = _resolver;
        emit SetResolver(_id, _resolver);
    }

    function resolver(uint256 _id) external view override returns (address) {
        return _resolvers[_id];
    }
}
