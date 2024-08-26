// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract DeviceNFT is ERC721Upgradeable, OwnableUpgradeable {
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed minter);
    event MinterAllowanceIncremented(address indexed owner, address indexed minter, uint256 allowanceIncrement);
    event SetBastURI(string uri);

    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;
    string internal uri;
    uint256 public total;

    function initialize(string memory _name, string memory _symbol) external initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        uri = "";
    }

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
        require(_to != address(0), "zero address");

        uint256 mintingAllowedAmount = minterAllowed[msg.sender];
        require(mintingAllowedAmount > 0, "exceeds minterAllowance");
        unchecked {
            minterAllowed[msg.sender] -= 1;
        }

        uint256 _tokenId = ++total;
        _mint(_to, _tokenId);
        return _tokenId;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        uri = _uri;
        emit SetBastURI(_uri);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }
}
