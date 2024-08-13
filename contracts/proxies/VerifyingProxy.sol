// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IProject.sol";
import "../interfaces/IioID.sol";
import "../interfaces/IioIDStore.sol";
import "../interfaces/IioIDRegistry.sol";

interface IDeviceNFT {
    function weight(uint256 tokenId) external view returns (uint256);
    function owner() external view returns (address);

    function initialize(string memory _name, string memory _symbol) external;
    function configureMinter(address _minter, uint256 _minterAllowedAmount) external;
    function setApprovalForAll(address operator, bool approved) external;
    function incrementMinterAllowance(address _minter, uint256 _allowanceIncrement) external;
    function transferOwnership(address newOwner) external;
    function mint(address _to) external returns (uint256);
}

interface IERC6551Executable {
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable returns (bytes memory);
}

interface IDeviceGauge {
    function stakingToken() external view returns (address);

    function deposit(uint256 _tokenId, address _recipient) external;
}

contract VerifyingProxy is OwnableUpgradeable, ERC721Holder {
    using ECDSA for bytes32;
    using ECDSA for bytes;
    using Clones for address;

    string public constant VERSION = "0.0.1";

    event Registered(address indexed owner, address indexed device, uint256 deviceTokenId, uint256 ioIDTokenID);
    event VerifierChanged(address indexed oldVerifier, address indexed newVerifier);
    event DeviceGaugeSetted(address indexed gauge);

    address public immutable projectRegistry;
    address public immutable ioIDStore;
    address public immutable deviceNFTImplementation;

    address public verifier;
    uint256 public projectId;
    IDeviceNFT public deviceNFT;
    address public deviceGauge;

    constructor(address _ioIDStore, address _projectRegistry, address _deviceNFTImplementation) {
        ioIDStore = _ioIDStore;
        projectRegistry = _projectRegistry;
        deviceNFTImplementation = _deviceNFTImplementation;
    }

    function initialize(
        uint8 _type,
        address _verifier,
        string calldata _projectName,
        string calldata _name,
        string calldata _symbol,
        uint256 _amount
    ) external payable initializer {
        require(_verifier != address(0), "zero address");
        __Ownable_init();

        verifier = _verifier;
        IioIDStore _ioIDStore = IioIDStore(ioIDStore);

        bytes32 _salt = keccak256(abi.encodePacked(msg.sender, _type, _name));
        address _instance = deviceNFTImplementation.cloneDeterministic(_salt);

        deviceNFT = IDeviceNFT(_instance);
        deviceNFT.initialize(_name, _symbol);
        deviceNFT.configureMinter(address(this), _amount);
        deviceNFT.setApprovalForAll(_ioIDStore.ioIDRegistry(), true);

        projectId = IProjectRegistry(projectRegistry).register(_projectName, _type);

        _ioIDStore.setDeviceContract(projectId, address(deviceNFT));
        if (0 == _type) {
            _ioIDStore.applyIoIDs{value: msg.value}(projectId, _amount);
        }

        emit VerifierChanged(address(0), _verifier);
    }

    function initialize(uint256 _projectId, address _verifier, address _deviceNFT, uint256 _amount) external onlyOwner {
        deviceNFT = IDeviceNFT(_deviceNFT);
        require(
            IERC721(address(IProjectRegistry(projectRegistry).project())).ownerOf(_projectId) == address(this) &&
                deviceNFT.owner() == address(this),
            "invalid owner"
        );

        projectId = _projectId;
        verifier = _verifier;
        deviceNFT.configureMinter(address(this), _amount);
        deviceNFT.setApprovalForAll(IioIDStore(ioIDStore).ioIDRegistry(), true);
    }

    function incrementMinterAllowance(uint256 _amount) external onlyOwner {
        deviceNFT.incrementMinterAllowance(address(this), _amount);
    }

    function changeVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "zero address");

        verifier = _verifier;
        emit VerifierChanged(address(0), _verifier);
    }

    function applyIoIDs(uint256 _amount) external payable onlyOwner {
        require(0 == IProjectRegistry(projectRegistry).project().projectType(projectId), "only hardware project");
        deviceNFT.incrementMinterAllowance(address(this), _amount);
        IioIDStore(ioIDStore).applyIoIDs{value: msg.value}(projectId, _amount);
    }

    function setName(string calldata _name) external onlyOwner {
        IProjectRegistry(projectRegistry).project().setName(projectId, _name);
    }

    function setMetadata(string calldata _name, bytes calldata _value) external onlyOwner {
        IProjectRegistry(projectRegistry).project().setMetadata(projectId, _name, _value);
    }

    function migrate(address _owner) external onlyOwner {
        deviceNFT.transferOwnership(_owner);
        IERC721(address(IProjectRegistry(projectRegistry).project())).safeTransferFrom(
            address(this),
            _owner,
            projectId
        );
    }

    function approveProjectNFT(address _to) external onlyOwner {
        IERC721(address(IProjectRegistry(projectRegistry).project())).approve(_to, projectId);
    }

    function setDeviceGauge(address _gauge) external onlyOwner {
        require(IDeviceGauge(_gauge).stakingToken() == address(deviceNFT), "invalid staking token");

        deviceGauge = _gauge;
        emit DeviceGaugeSetted(_gauge);
    }

    function register(
        bytes calldata _verifySignature,
        bytes32 _hash,
        string calldata _uri,
        address _owner,
        address _device,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        bytes memory verifyMessage = abi.encodePacked(block.chainid, _owner, _device);
        bytes32 verifyHash = verifyMessage.toEthSignedMessageHash();
        require(verifyHash.recover(_verifySignature) == verifier, "invalid verifier signature");

        uint256 _tokenId = deviceNFT.mint(address(this));

        IioIDRegistry _ioIDRegistry = IioIDRegistry(IioIDStore(ioIDStore).ioIDRegistry());
        _ioIDRegistry.register{value: msg.value}(
            address(deviceNFT),
            _tokenId,
            address(this),
            _device,
            _hash,
            _uri,
            _v,
            _r,
            _s
        );

        uint256 _ioIDTokenId = _ioIDRegistry.deviceTokenId(_device);

        if (deviceGauge != address(0)) {
            (address _walletAddr, ) = IioID(_ioIDRegistry.ioID()).wallet(_ioIDTokenId);
            IERC6551Executable _wallet = IERC6551Executable(_walletAddr);

            _wallet.execute(address(deviceNFT), 0, abi.encodeCall(IERC721.approve, (deviceGauge, _tokenId)), 0);
            _wallet.execute(deviceGauge, 0, abi.encodeCall(IDeviceGauge.deposit, (_tokenId, _owner)), 0);
        }

        IERC721(_ioIDRegistry.ioID()).safeTransferFrom(address(this), _owner, _ioIDTokenId);

        emit Registered(_owner, _device, _tokenId, _ioIDTokenId);
    }
}
