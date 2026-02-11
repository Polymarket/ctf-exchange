event TradeExecuted(address indexed buyer, address indexed seller, uint256 amount);

function executeTrade(address buyer, address seller, uint256 amount) external {
    // existing logic ...
    emit TradeExecuted(buyer, seller, amount);
}
