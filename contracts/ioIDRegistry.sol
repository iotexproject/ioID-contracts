// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IioID} from "./interfaces/IioID.sol";
import {IioIDRegistry} from "./interfaces/IioIDRegistry.sol";

contract ioIDRegistry is IioIDRegistry, Initializable {
    using Counters for Counters.Counter;
    using Strings for address;

    event NewDevice(address indexed device, address owner, bytes32 hash);
    event UpdateDevice(address indexed device, address owner, bytes32 hash);
    event RemoveDevice(address indexed device, address owner);

    bytes32 public constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    // solhint-disable var-name-mixedcase
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 internal constant PERMIT_TYPE_HASH = keccak256("Permit(address owner,uint256 nonce)");

    string public constant METHOD = "did:io:";
    mapping(address => Counters.Counter) private _nonces;

    struct Record {
        bytes32 hash;
        string uri;
    }

    mapping(address => Record) private records;
    mapping(address => uint256) private ids;
    address public ioID;

    modifier deviceExists(address owner) {
        require(records[owner].hash != bytes32(0), "device not exists");
        _;
    }

    function initialize(address _ioID) public initializer {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes("ioIDRegistry")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        ioID = _ioID;
    }

    function register(address device, bytes32 hash, string calldata uri, uint8 v, bytes32 r, bytes32 s) external {
        require(device != address(0), "device is the zero address");
        require(records[device].hash == bytes32(0), "device exists");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPE_HASH, msg.sender, _useNonce(device)))
            )
        );
        require(ecrecover(digest, v, r, s) == device, "invalid signature");

        _setRecord(device, hash, uri);
        uint256 _id = IioID(ioID).mint(device, msg.sender);
        ids[device] = _id;
        emit NewDevice(device, msg.sender, hash);
    }

    function update(
        address device,
        bytes32 hash,
        string calldata uri,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external deviceExists(device) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPE_HASH, msg.sender, _useNonce(device)))
            )
        );
        require(ecrecover(digest, v, r, s) == device, "invalid signature");

        _setRecord(device, hash, uri);
        emit UpdateDevice(device, msg.sender, hash);
    }

    // TODO: disable remove api?
    function remove(address device, uint8 v, bytes32 r, bytes32 s) external deviceExists(device) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPE_HASH, msg.sender, _useNonce(device)))
            )
        );
        require(ecrecover(digest, v, r, s) == device, "invalid signature");

        IioID(ioID).removeDID(device);
        delete records[device];
        delete ids[device];

        emit RemoveDevice(device, msg.sender);
    }

    function _setRecord(address device, bytes32 hash, string calldata uri) internal {
        require(hash != bytes32(0), "empty hash");
        records[device].hash = hash;
        records[device].uri = uri;
    }

    function _useNonce(address device) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[device];
        current = nonce.current();
        nonce.increment();
    }

    function permitHash(address owner, address device) external view returns (bytes32) {
        return keccak256(abi.encode(PERMIT_TYPE_HASH, owner, nonces(device)));
    }

    function nonces(address device) public view virtual returns (uint256) {
        return _nonces[device].current();
    }

    function exists(address device) external view returns (bool) {
        return records[device].hash != bytes32(0);
    }

    function documentID(address device) public pure returns (string memory) {
        return string(abi.encodePacked(METHOD, device.toHexString()));
    }

    function documentHash(address device) external view deviceExists(device) returns (bytes32) {
        return records[device].hash;
    }

    function documentURI(address device) external view deviceExists(device) returns (string memory) {
        return records[device].uri;
    }

    function deviceTokenId(address device) external view deviceExists(device) returns (uint256) {
        return ids[device];
    }
}
