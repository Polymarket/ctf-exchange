// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Owned} from "solmate/auth/Owned.sol";
import {IAuthorized, IAuthorizedEE} from "common/auth/interfaces/IAuthorized.sol";

abstract contract Authorized is Owned, IAuthorized {
    mapping(address => bool) public authorized;

    constructor(address _owner) Owned(_owner) {}

    modifier onlyAuthorized() {
        if (!authorized[msg.sender]) revert OnlyAuthorized();
        _;
    }

    function addAuthorization(address _account) external onlyOwner {
        authorized[_account] = true;

        emit AuthorizationAdded(_account);
    }

    function removeAuthorization(address _account) external onlyOwner {
        authorized[_account] = false;

        emit AuthorizationRemoved(_account);
    }
}
