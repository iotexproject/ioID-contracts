// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../interfaces/IProject.sol";
import "../interfaces/IioIDStore.sol";
import "../interfaces/IioIDRegistry.sol";
import {DeviceNFT} from "../examples/DeviceNFT.sol";

contract VerifyingProxy is Ownable, Initializable, ERC721Holder {
    using ECDSA for bytes32;
    using ECDSA for bytes;

    string public constant VERSION = "0.0.1";

    event Registered(address indexed owner, address indexed device, uint256 deviceTokenId, uint256 ioIDTokenID);
    event VerifierChanged(address indexed oldVerifier, address indexed newVerifier);

    address public immutable projectRegistry;
    address public immutable ioIDStore;

    address public verifier;
    uint256 public projectId;
    DeviceNFT public deviceNFT;

    constructor(address _ioIDStore, address _projectRegistry) {
        ioIDStore = _ioIDStore;
        projectRegistry = _projectRegistry;
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

        verifier = _verifier;
        IioIDStore _ioIDStore = IioIDStore(ioIDStore);

        deviceNFT = new DeviceNFT(_name, _symbol);
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
        deviceNFT = DeviceNFT(_deviceNFT);
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
        IERC721(_ioIDRegistry.ioID()).safeTransferFrom(address(this), _owner, _ioIDTokenId);

        emit Registered(_owner, _device, _tokenId, _ioIDTokenId);
    }
}
