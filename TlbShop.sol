// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
=======================================================================================
██████╗░██╗░░░██╗██╗░░░██╗  ░█████╗░███╗░░██╗██████╗░  ░██████╗███████╗██╗░░░░░██╗░░░░░
██╔══██╗██║░░░██║╚██╗░██╔╝  ██╔══██╗████╗░██║██╔══██╗  ██╔════╝██╔════╝██║░░░░░██║░░░░░
██████╦╝██║░░░██║░╚████╔╝░  ███████║██╔██╗██║██║░░██║  ╚█████╗░█████╗░░██║░░░░░██║░░░░░
██╔══██╗██║░░░██║░░╚██╔╝░░  ██╔══██║██║╚████║██║░░██║  ░╚═══██╗██╔══╝░░██║░░░░░██║░░░░░
██████╦╝╚██████╔╝░░░██║░░░  ██║░░██║██║░╚███║██████╔╝  ██████╔╝███████╗███████╗███████╗
╚═════╝░░╚═════╝░░░░╚═╝░░░  ╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░  ╚═════╝░╚══════╝╚══════╝╚══════╝
=======================================================================================
*/

// import "./lib/TransferHelper.sol";
import "./TlbBase.sol";
import "./ITlbShop.sol";
import "./ITlbMlm.sol";

contract TlbShop is TlbBase, ITlbShop { 
    Order[] _buyBook;
    Order[] _sellBook;
    uint[][] _txBook;

    function _buy(address sender, uint amountUsdt) public override {
        onlyContract();
        uint price = ITlbMlm(_contractTlb).getPrice();
        uint _tlbInit = amountUsdt * _tlbUnit / price;
        uint _tlb = _tlbInit;
        
        uint countRemove = 0;
        uint txCount = _txBook.length;
        // TransferHelper.safeTransferFrom(USDTToken, sender, address(this), amountUsdt);
        for(uint i=0; i<_sellBook.length; i++) {
            Order storage order = _sellBook[i];
            if (order.balance>=_tlb) {
                uint amount = _tlb * price * 998 / _tlbUnit / 1000;
                ITlbMlm(_contractTlb).safeTokenTransfer(USDTToken, order.account, amount);
                // TransferHelper.safeTransfer(USDTToken, order.account, amount);
                _txBook.push([10001 + (txCount++),0,_tlb,now]);
                order.balance -= _tlb;
                _tlb = 0;
                if (order.balance==0) countRemove++;
                break;
            } else {
                uint amount = order.balance * price * 998 / _tlbUnit / 1000; // * price * 998 )  / (_tlbUnit * 1000);
                ITlbMlm(_contractTlb).safeTokenTransfer(USDTToken, order.account, amount);
                // TransferHelper.safeTransfer(USDTToken, order.account, amount);
                _txBook.push([10001 + (txCount++),0,order.balance,now]);
                _tlb -= order.balance;
                order.balance = 0;
                countRemove++;
            }
        }
        
        if (countRemove>0) _rebuildOrders(false);
        if (_tlb>0) {
            require(_buyBook.length<100, "#20");
            uint balance = _tlb * price / _tlbUnit; // * price / _tlbUnit;
            _buyBook.push(Order({
                time:now,
                account:sender,
                initial:amountUsdt,
                balance:balance
            }));
            emit BuyOrderAdded(sender, balance);
        }
        if (_tlbInit - _tlb > 0) {
            ITlbMlm(_contractTlb).safeTransfer(_contractTlb, sender, _tlbInit - _tlb);
        }
        // _processSellOrder(86400);
    }

    //撤销买单，当 卖队列无法满足 买队列时 正确
    function _cancelBuyOrder(address sender) public override {
        onlyContract();
        uint balance = 0;
        for(uint i=0;i<_buyBook.length;i++) {
            if (_buyBook[i].account==sender) {
                balance  += _buyBook[i].balance;
                _buyBook[i].balance = 0;
            }
        }
        if (balance>0) {
            _rebuildOrders(true);
            ITlbMlm(_contractTlb).safeTokenTransfer(USDTToken, sender, balance);
            // TransferHelper.safeTransfer(USDTToken, sender, balance);
            emit BuyOrderCancelled(sender, balance);
        }
    }
    function _sell(address sender, uint amountTlb) public override {
        onlyContract();
        uint price = ITlbMlm(_contractTlb).getPrice();
        uint _usdtInit = amountTlb * price / _tlbUnit;
        uint _usdt = _usdtInit;
        
        uint countRemove = 0;
        uint txCount = _txBook.length;
        ITlbMlm(_contractTlb).safeTransfer(sender, _contractTlb, amountTlb);
        for(uint i=0; i<_buyBook.length; i++) {
            Order storage order = _buyBook[i];
            if (order.balance>=_usdt) {
                uint _tlb = _usdt * _tlbUnit / price; // * _tlbUnit / price;
                ITlbMlm(_contractTlb).safeTransfer(_contractTlb, order.account, _tlb);
                _txBook.push([10001 + (txCount++),1,_tlb,now]);
                order.balance -= _usdt;
                _usdt = 0;
                if (order.balance==0) countRemove++;
                break;
            } else {
                uint _tlb = order.balance * _tlbUnit / price; // * _tlbUnit / price;
                ITlbMlm(_contractTlb).safeTransfer(_contractTlb, order.account, _tlb);
                _txBook.push([10001 + (txCount++), 1, _tlb, now]);
                _usdt -= order.balance;
                order.balance = 0;
                countRemove++;
            }
        }
        if (countRemove>0) _rebuildOrders(true);
        if (_usdt>0) {
            require(_buyBook.length<100, "#20");
            uint balance = _usdt * _tlbUnit / price; // * _tlbUnit / price;
            _sellBook.push(Order({
                time: now,
                account:sender,
                initial:amountTlb,
                balance:balance
            }));
            emit SellOrderAdded(sender, balance);
        }
        if (_usdtInit-_usdt>0) {
            ITlbMlm(_contractTlb).safeTokenTransfer(USDTToken, sender, (_usdtInit - _usdt) * 998 / 1000);
            // TransferHelper.safeTransfer(USDTToken, sender, (_usdtInit - _usdt) * 998 / 1000);
        }
    }
    
    function _cancelSellOrder(address sender) public override {
        onlyContract();
        uint balance = 0;
        for(uint i=0;i<_sellBook.length;i++) {
            if (_sellBook[i].account==sender) {
                balance += _sellBook[i].balance;
                _sellBook[i].balance = 0;
            }
        }
        if (balance>0) {
            _rebuildOrders(false);
            
            ITlbMlm(_contractTlb).safeTransfer(_contractTlb, sender, balance);
            emit SellOrderCancelled(sender, balance);
        }
        // _processSellOrder(86400);
    }
    
    function _orderHistory() public override view returns(uint[4][] memory) {
        onlyContract();
        uint count = _txBook.length>10 ? 10 : _txBook.length;
        // uint[][] memory logs = new uint[][](count);
        uint[4][] memory logs = new uint[4][](count);
        for(uint i=0; i<count; i++) {
            uint[] storage order= _txBook[_txBook.length - count + i];
            logs[i][0] = order[0];  // order id
            logs[i][1] = order[1];  // 0: buy, 1: sell
            logs[i][2] = order[2];  // amount
            logs[i][3] = order[3];  // time
        }
        return logs;
    }
    function _pendingOrder(address account) public override view returns(uint[4][] memory) {
        onlyContract();
        uint count = 0;
        for(uint i=0;i<_buyBook.length;i++) {
            Order storage order = _buyBook[i];
            if (order.account==account) count++;
        }
        for(uint i=0;i<_sellBook.length;i++) {
            Order storage order = _sellBook[i];
            if (order.account==account) count++;
        }
        uint[4][] memory logs = new uint[4][](count);
        uint k=0;
        for(uint i=0;i<_buyBook.length;i++) {
            Order storage order = _buyBook[i];
            if (order.account==account) {
                logs[k][0] = order.time;    // time
                logs[k][1] = 0;             // 0: buy, 1: sell
                logs[k][2] = order.initial; // initial
                logs[k][3] = order.balance; // amount
                k++;
            }
        }
        for(uint i=0;i<_sellBook.length;i++) {
            Order storage order = _sellBook[i];
            if (order.account==account) {
                logs[k][0] = order.time;    // time
                logs[k][1] = 1;             // 0: buy, 1: sell
                logs[k][2] = order.initial; // initial
                logs[k][3] = order.balance; // amount
                k++;
            }
        }
        return logs;
    }
    function _rebuildOrders(bool isBuy) internal {
        Order[] storage _tmp = isBuy ? _buyBook : _sellBook;
        uint len = _tmp.length;
        uint k = 0;
        for(uint i=0;i<len;i++) {
            if (k!=i) {
                _tmp[k].account = _tmp[i].account;
                _tmp[k].initial = _tmp[i].initial;
                _tmp[k].balance = _tmp[i].balance;    
            }
            if (_tmp[i].balance!=0) {
                k++;
            }
        }
        for(uint i=k;i<len;i++) _tmp.pop();
    }
    //触发回购操作
    function _redeemSellOrders(address _redeemAddress) public override {
        onlyContract();
        uint price = ITlbMlm(_contractTlb).getPrice();
        uint redeemAmount = ITlbMlm(_contractTlb).getRedeemAmount();
        uint _redeem = redeemAmount * 5 / 100;
        uint _count = _sellBook.length;
        uint _sumTps = 0;
        uint _usdt = 0;
        uint _tlb = 0;
        uint txCount = _txBook.length;
        if (_redeem>0) {
            if (_count>5) _count = 5;
            uint _total = 0;
            for(uint i=0;i<_count;i++) _total += _sellBook[i].balance; 
            uint rate = _redeem * 1e4 / (_total * price / _tlbUnit);
            if (rate>1e4) rate = 1e4; // 1e4 = 100%
            for(uint i=0;i<_count;i++) {
                Order storage order = _sellBook[i];
                _usdt = order.balance * rate * price / _tlbUnit / 1e4;
                _tlb = _usdt * _tlbUnit / price;
                order.balance -= _tlb;
                redeemAmount -= _usdt;
                _redeem -= _usdt;
                _sumTps += _tlb;
                ITlbMlm(_contractTlb).safeTokenTransfer(USDTToken, order.account, _usdt * 998 / 1000);
                // TransferHelper.safeTransfer(USDTToken, order.account, _usdt * 998 / 1000);
                _txBook.push([10001 + (txCount++),1,_tlb,now]); // 2 means redeem
            }
            if (_sumTps>0) {
                _rebuildOrders(false);
                ITlbMlm(_contractTlb).safeTransfer(_contractTlb, _redeemAddress, _sumTps);
            }
        }
        emit RedeemOrder(_count,_sumTps);
    }
}