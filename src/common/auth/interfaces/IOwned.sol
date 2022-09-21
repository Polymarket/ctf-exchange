// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IOwnedEE {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    error OnlyOwner();
}

interface IOwned is IOwnedEE {
    function setOwner(address newOwner) external;
}
