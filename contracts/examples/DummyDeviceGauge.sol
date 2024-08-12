// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DummyDeviceGauge is ERC721Holder {
    event Deposit(address indexed user, uint256 tokenId);

    address public deviceNFT;
    mapping(uint256 => address) public deviceOwner;

    constructor(address _deviceNFT) {
        deviceNFT = _deviceNFT;
    }

    function stakingToken() external view returns (address) {
        return deviceNFT;
    }

    function deposit(uint256 _tokenId, address _recipient) external {
        IERC721(deviceNFT).safeTransferFrom(msg.sender, address(this), _tokenId);
        deviceOwner[_tokenId] = _recipient;

        emit Deposit(_recipient, _tokenId);
    }
}
