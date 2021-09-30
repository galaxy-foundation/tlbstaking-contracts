// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**********************************************************************
████████╗██╗░░░░░██████╗░ ░░██████╗████████╗░█████╗░██╗░░██╗██╗███╗░░██╗░██████╗░
╚══██╔══╝██║░░░░░██╔══██╗░ ██╔════╝╚══██╔══╝██╔══██╗██║░██╔╝██║████╗░██║██╔════╝░
░░░██║░░░██║░░░░░██████╦╝░░╚█████╗░░░░██║░░░███████║█████═╝░██║██╔██╗██║██║░░██╗░
░░░██║░░░██║░░░░░██╔══██╗░░░╚═══██╗░░░██║░░░██╔══██║██╔═██╗░██║██║╚████║██║░░╚██╗
░░░██║░░░███████╗██████╦╝░░██████╔╝░░░██║░░░██║░░██║██║░╚██╗██║██║░╚███║╚██████╔╝
░░░╚═╝░░░╚══════╝╚═════╝░░░╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░
********************************************************************** */


// import "./lib/TransferHelper.sol";

import "./TlbBase.sol";

import "./ITlbFarm.sol";
import "./ITlbMlm.sol";

contract TLBFarm is TlbBase, ITlbFarm {
    //矿工初始价格，和推广收益表
    uint[][] _minerTiers = [
        [15000 * _usdtUnit, 150, 100, 30], //15000U,100T,10%,30%
        [7500 * _usdtUnit, 75, 50, 20], 
        [3500 * _usdtUnit, 35, 25, 10], 
        [100 * _usdtUnit, 1, 10, 5]// modify miner power
    ];

    //矿工列表
    // address[] _minerlist;
    mapping(address=>Miner) _miners;
    mapping(address=>address[]) _referedMiners;
    
    uint _minerTotalPower; //总算力
    uint _minerCount; //矿工个数
    uint[] _minerClass = new uint[](3); // 0:超级, 1:优质, 2:普通
    uint _minedTotal;
    
    address[] _minerlist = new address[](50);
    
    //计算 矿机价格每增加一层 认购价格 矿机认购价格在原基础上 增加0.1% 正确
    function _minerPrice(uint tier, uint currentLayer) public override view returns(uint) {
        onlyContract();
        require(tier>=0 && tier<=3, "#4");
        return _minerTiers[tier][0] + _minerTiers[tier][0] * currentLayer / 1000;
    }
    
    //计算 待领取的TLB 奖励 正确
    function _pendingPool(address account) internal view returns(uint,uint,bool) {
        Miner storage miner= _miners[account];
        bool overflowed = false;
        if (miner.lastBlock!=0) {
            if (miner.mineType==0) {
                uint diff = block.number - miner.lastBlock;
                if (diff>9600) diff = 9600;
                uint withdrawal = miner.pending + diff * 4800 * _tlbUnit * miner.tier / (28800 * _minerTotalPower);
                uint _total = miner.rewards + withdrawal;
                if (miner.minable <= _total) {
                    withdrawal -= _total - miner.minable;
                    overflowed = true;
                }
                return (diff, withdrawal, overflowed);
            }
        }
        return (0, miner.pending,overflowed);
    }
    
    //开始挖矿，每次提现后必须重新触发 （需要添加判断 没有购买矿机的人 不能触发该操作）
    function _startMine(address account) public override {
        onlyContract();
        Miner storage miner= _miners[account];
        require(miner.tier!=0, "#31");
        require(miner.lastBlock==0, "#32");
        
        uint i = 0;
        uint count = 0;
        uint k = 100;
        uint len = _minerlist.length;
        for (i=0; i<len; i++) {
            if (_minerlist[i]==address(0)) break;
            if (_miners[_minerlist[i]].lastBlock != 0 && block.number - _miners[_minerlist[i]].lastBlock <= 9600) {
                if (_minerlist[i]==account) {
                    k = count;
                }
                _minerlist[count++] = _minerlist[i];
            }
        }
        for (i=count; i<len; i++) {
            _minerlist[i]=address(0);
        }
        if (k==100) {
            for (i=0; i<count; i++) {
                if (miner.tier>_miners[_minerlist[i]].tier) {
                    k = i;
                    break;
                }
            }
            if (k==100) {
                if (count<len) _minerlist[count] = account;
            } else {
                if (count < len) count++;
                for(i = count - 1;i > k; i--) {
                    _minerlist[i] = _minerlist[i - 1];
                }
                _minerlist[k] = account;
            }
        }
        if (miner.tier>=100) {
            _minerClass[0]++;
        } else if (miner.tier>=50) {
            _minerClass[1]++;
        } else {
            _minerClass[2]++;
        }
        (,uint withdrawal,bool _overflowed) = _pendingPool(account);
        miner.pending = withdrawal;
        miner.lastBlock = _overflowed ? 0 : block.number;
    }
    function _stopMine(address account) public override returns(uint) {
        onlyContract();
        Miner storage miner= _miners[account];
        (,uint withdrawal,) = _pendingPool(account);
        if (miner.lastBlock!=0) {
            miner.pending = withdrawal;
            if (miner.tier>=100) {
                if (_minerClass[0]>0) _minerClass[0]--;
            } else if (miner.tier>=50) {
                if (_minerClass[1]>0) _minerClass[1]--;
            } else {
                if (_minerClass[2]>0) _minerClass[2]--;
            }
            miner.lastBlock = 0;
            return withdrawal;
        }
        return withdrawal;
    }
    
    function _mineInfo2(uint currentLayer) public override view returns(uint[9] memory) {
        return [
            _minerCount,
            _minerTotalPower,
            _minerPrice(0, currentLayer),
            _minerPrice(1, currentLayer),
            _minerPrice(2, currentLayer),
            _minerPrice(3, currentLayer),
            _minerClass[0],
            _minerClass[1],
            _minerClass[2]
        ];
    }
    function _mineInfo(address account) public override view returns(uint[12] memory,address) {
        onlyContract();
        address[] storage referees = _referedMiners[account];
        uint _minerRefTotal = 0;
        uint _count = referees.length;
        uint _minerStatus = 0;
        // (,uint _realpower) = _minerRealPower();
        for (uint i=0; i<referees.length; i++) {
            _minerRefTotal += _miners[referees[i]].tier;
        }
        
        Miner storage _mnr= _miners[account];
        if (_mnr.lastBlock>0) {
            if (_mnr.mineType==0) {
                _minerStatus = (block.number - _mnr.lastBlock)<9600 ? 1 : 0;
            } else {
                _minerStatus = 1;
            }
        }
        // pending
        (uint _pendingBlocks, uint _pending,bool _overflowed) = _pendingPool(account);
        // uint _blockRewards = _minerTotalPower!=0 ? _mnr.tier.mul(48000).mul(_tlbUnit).div(28800).div(_minerTotalPower) : 0;
        return ([
            _mnr.tier,
            _mnr.mineType,
            _count, 
            _minerRefTotal,
            _minerStatus,
            _mnr.lastBlock,
            _mnr.lastTime,
            _mnr.rewards,
            _pendingBlocks,
            _pending,
            _mnr.minable,
            _overflowed?1:0
        ],_mnr.referer);
    }
    //购买矿机 
    function _buyMiner(address sender, address referalLink, uint tier, uint currentLayer) public override returns(uint referalRewards) {
        onlyContract();
        Miner storage miner= _miners[sender];
        uint _tierpower = _minerTiers[tier][1];
        uint amountUsdt = _minerPrice(tier, currentLayer);
        if (currentLayer!=0) {
            uint referalRewardRate = currentLayer<=100 ? _minerTiers[tier][2] : _minerTiers[tier][3];
            referalRewards = amountUsdt * referalRewardRate / 1000;
            if (referalLink!=address(0)) {
                if (miner.tier==0) {
                    _referedMiners[referalLink].push(sender);
                    miner.referer = referalLink;
                } else {
                    require(miner.referer == referalLink, "#2");
                }
            }
        }
        
        //如果没有购买过
        if (miner.tier==0) {
            miner.mineType = 0;//挖矿种类
            miner.tier = _tierpower;//算力大小
            _minerCount++;//矿工数+1
        } else {
            _stopMine(sender);
            //矿工后续购买，该矿工算力增加
            miner.tier += _tierpower;
        }
        uint price = ITlbMlm(_contractTlb).getPrice();
        miner.minable += amountUsdt * _tlbUnit * 12 / (10 * price);
        _minerTotalPower += _tierpower;
        miner.lastTime = now;
        emit AddMiner(sender,_tierpower);
    }
    
    //触发领取奖励动作 正确
    function _withdrawFromPool(address account) public override returns(uint,uint) {
        onlyContract();
        Miner storage miner= _miners[account];
        uint withdrawal = _stopMine(account);
        require(withdrawal>0, "#1");
        miner.rewards += withdrawal;
        miner.pending = 0;
        _minedTotal += withdrawal;
        return (_minedTotal, withdrawal);
    }
    
    function _minerList(address _address) public override view returns(address[] memory,uint[] memory,uint[] memory) {
        onlyContract();
        address[] memory _aaddrs = new address[](10);
        uint[] memory _atiers = new uint[](10);
        uint[] memory _aBlocks = new uint[](10);
        uint k = 0;
        address account;
        for(uint i=0; i<50; i++) {
            account = _minerlist[i];
            if (account!=address(0) && account!=_address && _miners[account].lastBlock+9600 > block.number) {
                _aaddrs[k]  = account;
                _atiers[k]  = _miners[account].tier;
                _aBlocks[k] = _miners[account].lastBlock;
                k++;
                if (k==10) break;
            }
        }
        return (_aaddrs,_atiers,_aBlocks);
    }
}