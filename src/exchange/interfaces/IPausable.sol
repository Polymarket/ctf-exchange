// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

interface IPausableEE {
    error Paused();

    event TradingPaused(address indexed pauser);

    event TradingUnpaused(address indexed pauser);
}

abstract contract IPausable is IPausableEE {
    function _pauseTrading() internal virtual;

    function _unpauseTrading() internal virtual;
}
