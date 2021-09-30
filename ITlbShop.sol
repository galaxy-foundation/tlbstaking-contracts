// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ITlbShop{
    
    event BuyOrderAdded(address guest, uint amount);
    event BuyOrderCancelled(address guest, uint amount);
    event SellOrderAdded(address guest, uint amount);
    event SellOrderCancelled(address guest, uint amount);
    
    event RedeemOrder(uint _orderCount,uint _sumTps);
    
    struct Order {
        uint time;
        address account;
        uint initial;
        uint balance;
    }
    
    function _buy(address sender, uint amountUsdt) external;
    function _cancelBuyOrder(address sender) external;
    function _sell(address sender, uint amountTlb) external;
    function _cancelSellOrder(address sender) external;
    function _orderHistory() external view returns(uint[4][] memory);
    function _pendingOrder(address account) external view returns(uint[4][] memory);
    function _redeemSellOrders(address _redeemAddress) external;
}