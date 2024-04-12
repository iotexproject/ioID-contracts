// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC6551Registry} from "./interfaces/IERC6551Registry.sol";

contract DeviceNFT is ERC721Upgradeable {
    event DeviceNFTCreate(address indexed owner, uint256 id, address wallet, string did);
    event MinterSet(address indexed minter);
    event DIDWalletRemove(address indexed wallet, string did);

    uint256 nextId;
    address public minter;
    address public walletRegistry;
    address public walletImplementation;

    mapping(bytes32 => address) _didWallet;

    function initialize(
        address _minter,
        address _walletRegistry,
        address _walletImplementation,
        string calldata _name,
        string calldata _symbol
    ) public initializer {
        __ERC721_init(_name, _symbol);
        minter = _minter;
        walletRegistry = _walletRegistry;
        walletImplementation = _walletImplementation;

        emit MinterSet(_minter);
    }

    function setMinter(address _minter) external {
        require(_minter != address(0), "zero minter");
        require(minter == msg.sender, "invalid minter");
        minter = _minter;

        emit MinterSet(_minter);
    }

    function wallet(uint256 _id) external view returns (address) {
        return IERC6551Registry(walletRegistry).account(walletImplementation, 0, block.chainid, address(this), _id);
    }

    function wallet(string calldata _did) external view returns (address) {
        return _didWallet[keccak256(abi.encodePacked(_did))];
    }

    function mint(string calldata _did, address _owner) external returns (uint256) {
        return _mint(_did, _owner);
    }

    function _mint(string calldata _did, address _owner) internal returns (uint256 id_) {
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
        _didWallet[keccak256(abi.encodePacked(_did))] = _wallet;
        emit DeviceNFTCreate(_owner, id_, _wallet, _did);
    }

    function removeDID(string calldata _did) external {
        require(minter == msg.sender, "invalid minter");

        address _wallet = _didWallet[keccak256(abi.encodePacked(_did))];
        require(_wallet != address(0), "wallet not exist");
        delete _didWallet[keccak256(abi.encodePacked(_did))];

        emit DIDWalletRemove(_wallet, _did);
    }
}
