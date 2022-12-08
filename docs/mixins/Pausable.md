# Pausable

Used to provide a trading "kill switch". Specifically, the primary entry points to `CTFExchange` are all decorated with the `notPaused` modifier, meaning trading can be paused if needed. This contract provides simple utilities for pausing/unpausing. 

## `notPaused`

Modifier that reverts in the case that the state variable `paused` is `true` (`bool`). Otherwise, execution of modified function continues without disruption.

## `_pauseTrading`

Internal function that sets the `paused` state variable to `true` which result in any `notPaused` decorated function to revert. 

Emits:

- `TradingPaused(msg.sender)`

## `unpauseTrading`

Internal function that sets the `paused` state variable to `false`. This unpauses trading by making the `notPaused` modifier not hit the revert path.

Emits:

- `TradingUnpaused(msg.sender)`


