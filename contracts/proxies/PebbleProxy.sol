// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../interfaces/IProject.sol";
import "../interfaces/IioIDStore.sol";
import "../interfaces/IioIDRegistry.sol";
import {DeviceNFT} from "../examples/DeviceNFT.sol";

contract PebbleProxy is Ownable, Initializable, ERC721Holder {
    using ECDSA for bytes32;

    event NewPebbleProxy(address indexed pebbleNFT, uint256 projectId, uint256 amount);
    event PebbleRegistered(
        string imei,
        address indexed owner,
        address indexed device,
        uint256 pebbleTokenId,
        uint256 ioIDTokenID
    );
    event VerifierChanged(address indexed oldVerifier, address indexed newVerifier);

    address public verifier;
    address public projectRegistry;
    address public ioIDStore;
    uint256 public projectId;
    DeviceNFT public pebbleNFT;

    mapping(bytes32 => uint256) public ioIds;
    mapping(bytes32 => uint256) public deviceTokens;
    mapping(bytes32 => address) public owners;
    mapping(bytes32 => address) public devices;

    constructor(address _ioIDStore, address _projectRegistry) {
        ioIDStore = _ioIDStore;
        projectRegistry = _projectRegistry;
    }

    function initialize(
        address _verifier,
        string calldata _projectName,
        string calldata _name,
        string calldata _symbol,
        uint256 _amount
    ) external payable initializer {
        require(_verifier != address(0), "zero address");

        verifier = _verifier;
        IioIDStore _ioIDStore = IioIDStore(ioIDStore);

        pebbleNFT = new DeviceNFT(_name, _symbol);
        pebbleNFT.configureMinter(address(this), _amount);
        pebbleNFT.setApprovalForAll(_ioIDStore.ioIDRegistry(), true);

        projectId = IProjectRegistry(projectRegistry).register(_projectName, ProjectType.Hardware);

        _ioIDStore.setDeviceContract(projectId, address(pebbleNFT));
        _ioIDStore.applyIoIDs{value: msg.value}(projectId, _amount);

        emit VerifierChanged(address(0), _verifier);
    }

    function changeVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "zero address");

        verifier = _verifier;
        emit VerifierChanged(address(0), _verifier);
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

    function pebble(
        string calldata _imei
    ) external view returns (address owner, address device, uint256 ioId, uint256 deviceTokenId) {
        bytes32 deviceHash = keccak256(abi.encodePacked(_imei));
        owner = owners[deviceHash];
        device = devices[deviceHash];
        ioId = ioIds[deviceHash];
        deviceTokenId = deviceTokens[deviceHash];
    }

    function register(
        string calldata _imei,
        bytes calldata _verifySignature,
        bytes32 _hash,
        string calldata _uri,
        address _owner,
        address _device,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        bytes32 deviceHash = keccak256(abi.encodePacked(_imei));
        require(ioIds[deviceHash] == 0, "already registered");

        bytes32 verifyMessage = keccak256(abi.encodePacked(block.chainid, _imei, _owner, _device));
        require(verifyMessage.recover(_verifySignature) == verifier, "invalid verifier signature");

        uint256 _tokenId = pebbleNFT.mint(address(this));

        IioIDRegistry _ioIDRegistry = IioIDRegistry(IioIDStore(ioIDStore).ioIDRegistry());
        _ioIDRegistry.register(address(pebbleNFT), _tokenId, _device, _hash, _uri, _v, _r, _s);

        uint256 _ioIDTokenId = _ioIDRegistry.deviceTokenId(_device);
        IERC721(_ioIDRegistry.ioID()).safeTransferFrom(address(this), _owner, _ioIDTokenId);
        ioIds[deviceHash] = _ioIDTokenId;
        deviceTokens[deviceHash] = _tokenId;
        owners[deviceHash] = _owner;
        devices[deviceHash] = _device;

        emit PebbleRegistered(_imei, _owner, _device, _tokenId, _ioIDTokenId);
    }
}
