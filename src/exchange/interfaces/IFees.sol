// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

interface IFeesEE {
    error FeeTooHigh();

    /// @notice Emitted when a fee is charged
    event FeeCharged(address indexed receiver, uint256 tokenId, uint256 amount);
}

abstract contract IFees is IFeesEE {
    function getMaxFeeRate() public pure virtual returns (uint256);
}
