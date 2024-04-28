// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IProjectRegistrar {
    function registrationFee() external view returns (uint256);
    function register() external payable returns (uint256);
}
