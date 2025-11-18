// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract yPUSDStorage {
    /* ========== Role Definitions ========== */
    uint256 public cap;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Lock status for MINTER_ROLE: once set to true, can never be modified
    bool public minterRoleLocked;

    // Placeholder
    uint256[50] private __gap;
}
