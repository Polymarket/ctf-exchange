// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

interface IAuthEE {
    error NotAdmin();
    error NotOperator();

    /// @notice Emitted when a new admin is added
    event NewAdmin(address indexed newAdminAddress, address indexed admin);

    /// @notice Emitted when a new operator is added
    event NewOperator(address indexed newOperatorAddress, address indexed admin);

    /// @notice Emitted when an admin is removed
    event RemovedAdmin(address indexed removedAdmin, address indexed admin);

    /// @notice Emitted when an operator is removed
    event RemovedOperator(address indexed removedOperator, address indexed admin);
}

interface IAuth is IAuthEE {
    function isAdmin(address) external view returns (bool);

    function isOperator(address) external view returns (bool);

    function addAdmin(address) external;

    function addOperator(address) external;

    function removeAdmin(address) external;

    function removeOperator(address) external;

    function renounceAdminRole() external;

    function renounceOperatorRole() external;
}
