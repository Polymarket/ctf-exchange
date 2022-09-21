// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IAuthorizedEE {
    event AuthorizationAdded(address _account);
    event AuthorizationRemoved(address _account);

    error OnlyAuthorized();
}

interface IAuthorized is IAuthorizedEE {
    function addAuthorization(address _account) external;

    function removeAuthorization(address _account) external;
}
