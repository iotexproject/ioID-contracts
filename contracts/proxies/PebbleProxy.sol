// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IProject.sol";
import "../interfaces/IioIDStore.sol";
import "../interfaces/IioIDRegistry.sol";
import {DeviceNFT} from "../examples/DeviceNFT.sol";

interface Registration {
    function find(string memory imei) external view returns (address device, address owner, bytes32 sn);
}

contract PebbleProxy is Ownable, Initializable, ERC721Holder {
    event NewPebbleProxy(address indexed pebbleNFT, uint256 projectId, uint256 amount);
    event PebbleRegistered(
        string imei,
        address indexed device,
        address indexed owner,
        uint256 pebbleTokenId,
        uint256 ioIDTokenID
    );

    address public registration;
    address public projectRegistry;
    address public ioIDStore;
    uint256 public projectId;
    DeviceNFT public pebbleNFT;

    mapping(bytes32 => uint256) public registerTime;

    constructor(address _registration, address _ioIDStore, address _projectRegistry) {
        registration = _registration;
        ioIDStore = _ioIDStore;
        projectRegistry = _projectRegistry;
    }

    function initialize(
        string calldata _projectName,
        string calldata _name,
        string calldata _symbol,
        uint256 _amount
    ) external payable initializer {
        IioIDStore _ioIDStore = IioIDStore(ioIDStore);

        pebbleNFT = new DeviceNFT(_name, _symbol);
        pebbleNFT.configureMinter(address(this), _amount);
        pebbleNFT.setApprovalForAll(_ioIDStore.ioIDRegistry(), true);

        projectId = IProjectRegistry(projectRegistry).register(_projectName, ProjectType.Hardware);

        _ioIDStore.setDeviceContract(projectId, address(pebbleNFT));
        _ioIDStore.applyIoIDs{value: msg.value}(projectId, _amount);
    }

    function applyIoIDs(uint256 _amount) external payable onlyOwner {
        IioIDStore(ioIDStore).applyIoIDs{value: msg.value}(projectId, _amount);
    }

    function migrate(address _owner) external onlyOwner {
        pebbleNFT.transferOwnership(_owner);
        IProjectRegistry(projectRegistry).project().safeTransferFrom(address(this), _owner, projectId);
    }

    function approveProjectNFT(address _to) external onlyOwner {
        IProjectRegistry(projectRegistry).project().approve(_to, projectId);
    }

    function register(
        string calldata imei,
        bytes32 hash,
        string calldata uri,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        (address _device, address _owner, ) = Registration(registration).find(imei);
        require(_device != address(0) && _owner != address(0), "invalid pebble");
        require(msg.sender == _owner, "invalid owner");

        bytes32 deviceHash = keccak256(abi.encodePacked(imei));
        require(registerTime[deviceHash] == 0, "already registered");

        uint256 _tokenId = pebbleNFT.mint(address(this));

        IioIDRegistry _ioIDRegistry = IioIDRegistry(IioIDStore(ioIDStore).ioIDRegistry());
        _ioIDRegistry.register(address(pebbleNFT), _tokenId, _device, hash, uri, v, r, s);

        uint256 _ioIDTokenId = _ioIDRegistry.deviceTokenId(_device);
        IERC721(_ioIDRegistry.ioID()).safeTransferFrom(address(this), _owner, _ioIDTokenId);
        registerTime[deviceHash] = block.timestamp;

        emit PebbleRegistered(imei, _device, _owner, _tokenId, _ioIDTokenId);
    }
}
