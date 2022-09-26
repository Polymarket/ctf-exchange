// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import { IAssets } from "../interfaces/IAssets.sol";

abstract contract Assets is IAssets {
    address internal immutable collateral;
    address internal immutable ctf;

    constructor(address _collateral, address _ctf) {
        collateral = _collateral;
        ctf = _ctf;
        IERC20(collateral).approve(ctf, type(uint256).max);
    }

    function getCollateral() public view override returns (address) {
        return collateral;
    }

    function getCtf() public view override returns (address) {
        return ctf;
    }
}
