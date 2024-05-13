// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Upgradeable, ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {IERC6551Registry} from "./interfaces/IERC6551Registry.sol";
import "./interfaces/IioID.sol";
import "./interfaces/IioIDRegistry.sol";

contract ioID is IioID, ERC721EnumerableUpgradeable {
    event CreateIoID(address indexed owner, uint256 id, address wallet, string did);
    event SetMinter(address indexed minter);
    event RemoveDIDWallet(address indexed wallet, string did);

    uint256 nextId;
    address public minter;
    address public walletRegistry;
    address public walletImplementation;

    mapping(bytes32 => address) _wallets;
    mapping(uint256 => address) _devices;

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

    // TODO:
    // 1. add to project device list
    // 2. remove sprout project NFT to ioID
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
}
