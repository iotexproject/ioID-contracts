// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../interfaces/IDeviceNFT.sol";

contract DeviceNFT is IDeviceNFT, ERC721, Ownable {
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed minter);
    event WeightSetted(uint256 tokenId, uint256 weight);
    event MinterAllowanceIncremented(address indexed owner, address indexed minter, uint256 allowanceIncrement);

    uint256 public immutable DEFAULT_WEIGHT = 1;

    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;
    uint256 public total;
    mapping(uint256 => uint256) internal weights;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function minterAllowance(address minter) external view returns (uint256) {
        return minterAllowed[minter];
    }

    function isMinter(address account) external view returns (bool) {
        return minters[account];
    }

    function configureMinter(address _minter, uint256 _minterAllowedAmount) external onlyOwner {
        minters[_minter] = true;
        minterAllowed[_minter] = _minterAllowedAmount;
        emit MinterConfigured(_minter, _minterAllowedAmount);
    }

    function incrementMinterAllowance(address _minter, uint256 _allowanceIncrement) external onlyOwner {
        require(_allowanceIncrement > 0, "zero amount");
        require(minters[_minter], "not minter");

        minterAllowed[_minter] += _allowanceIncrement;
        emit MinterAllowanceIncremented(msg.sender, _minter, _allowanceIncrement);
    }

    function removeMinter(address _minter) external onlyOwner {
        minters[_minter] = false;
        minterAllowed[_minter] = 0;
        emit MinterRemoved(_minter);
    }

    function mint(address _to) external returns (uint256) {
        return __mint(_to, 0);
    }

    function mint(address _to, uint256 _weight) external returns (uint256) {
        return __mint(_to, _weight);
    }

    function __mint(address _to, uint256 _weight) internal returns (uint256) {
        require(_to != address(0), "zero address");

        uint256 mintingAllowedAmount = minterAllowed[msg.sender];
        require(mintingAllowedAmount > 0, "exceeds minterAllowance");
        unchecked {
            minterAllowed[msg.sender] -= 1;
        }

        uint256 _tokenId = ++total;
        _mint(_to, _tokenId);
        if (_weight != 0) {
            weights[_tokenId] = _weight;
            emit WeightSetted(_tokenId, _weight);
        } else {
            emit WeightSetted(_tokenId, DEFAULT_WEIGHT);
        }
        return _tokenId;
    }

    function setWeight(uint256 _tokenId, uint256 _weight) external onlyOwner {
        weights[_tokenId] = _weight;
        emit WeightSetted(_tokenId, _weight);
    }

    function weight(uint256 _tokenId) external view override returns (uint256) {
        uint256 _weight = weights[_tokenId];
        if (_weight == 0) {
            return DEFAULT_WEIGHT;
        }
        return _weight;
    }
}
