// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Owned} from "solmate/auth/Owned.sol";
// Only import IAuthorized, assuming it covers the abstract function signatures.
import {IAuthorized} from "common/auth/interfaces/IAuthorized.sol";

// Define the custom error used by the modifier (required for compilation)
error OnlyAuthorized(); 

/**
 * @title Authorized
 * @notice Abstract contract to manage a simple, mapping-based authorization list for function execution.
 * @dev Inherits single-owner governance from Solmate's Owned contract. 
 * Authorization changes are restricted to the contract owner.
 */
abstract contract Authorized is Owned, IAuthorized {
    // Define the events expected by the IAuthorized interface
    event AuthorizationAdded(address indexed account);
    event AuthorizationRemoved(address indexed account);

    // Using a mapping for O(1) authorization checks.
    mapping(address => bool) public authorized;

    // Initialized by passing the contract owner's address
    constructor(address _owner) Owned(_owner) {}

    /**
     * @notice Modifier that restricts function calls to only addresses marked as authorized.
     */
    modifier onlyAuthorized() {
        // Use gas-efficient custom error
        if (!authorized[msg.sender]) revert OnlyAuthorized();
        _;
    }

    /**
     * @inheritdoc IAuthorized
     * @notice Grants authorization to a specific account. Only callable by the owner.
     */
    function addAuthorization(address _account) external onlyOwner {
        // Optimization: Skip state change if the account is already authorized (gas saving)
        if (authorized[_account]) return;

        authorized[_account] = true;

        emit AuthorizationAdded(_account);
    }

    /**
     * @inheritdoc IAuthorized
     * @notice Revokes authorization from a specific account. Only callable by the owner.
     */
    function removeAuthorization(address _account) external onlyOwner {
        // Optimization: Skip state change if the account is already unauthorized (gas saving)
        if (!authorized[_account]) return;

        authorized[_account] = false;

        emit AuthorizationRemoved(_account);
    }
}
