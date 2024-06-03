// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IProject is IERC721 {
    function mint(address _owner) external returns (uint256 projectId_);
    function mint(address _owner, string calldata _name) external returns (uint256 projectId_);
    function count() external view returns (uint256);
}
