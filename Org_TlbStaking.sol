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


import "./lib/HRC20.sol";
import "./lib/TransferHelper.sol";

import "./ITLB10.sol";

contract TLBStaking is HRC20("TLB Staking", "TLB", 4, 48000 * 365 * 2 * (10 ** 4)), ITLB10 { 
    // using SafeMath for uint256;
    address hero = ;
    // heco mainnet 
    // address USDTToken = 0xa71EdC38d189767582C38A3145b5873052c3e47a;
    //火币链上usdt代币地址
    address USDTToken = 0x529ffe728594590Ca0F4f5E113B85C6d36F69206;
    //代币精度
    uint8   USDTPrecision = 18;
    uint    _usdtUnit = uint(10) ** USDTPrecision;
    uint    _tlbUnit = uint(10) ** 4;

    
    //管理员
    Admin _admin;
    //张总
    Admin _zhang;
    //李总
    Admin _lee;
    
    uint    _tlbIncrement = _usdtUnit / 100; //TLB涨幅，每一层
    
    uint    price = _usdtUnit / 10;// TLB 初始价格
    uint32  maxUsers = 1e6; //最大用户数
    uint32  totalUsers = 0;//目前用户数
    uint16  currentLayer = 0;//当前层级
    //累计销毁
    uint    totalBurnt = 0;
    uint16  _positionInLayer = 0;//当前位置在 某一层中的位置
    
    uint    totalMineable = 28032000 * _tlbUnit; //总计可以挖出来的矿
    uint    totalDeposit = 0;//系统总计存款
    uint    totalWithdraw = 0;//系统总计存款
    
    //保险状态
    uint    _insuranceInitial = now;
    uint    _insuranceCounterTime = now;
    uint    _insuranceLimit = 36 hours; // 36hrs
    uint    _insuranceTime = 0;
    uint    _insuranceDeposit = 0; // last total deposit
    address _insuranceLastMember;
    // uint    _insuranceMemberCount;
    
    //动态收益列表
    uint8[][] sprigs = [
        [1, 1, 200], // 吃 第1层 静态收益的20%
        [2, 2, 150],// 吃 第2层 静态收益的15%
        [3, 7, 100],// 吃 第3-7层 静态收益的10%
        [8, 15, 50],// 吃 第8-15层 静态收益的5%
        [16, 20, 20]// 吃 第15-20层 静态收益的2%
    ];
    
    //第一个地址
    address firstAddress; // by admin
    
    mapping(uint32 => address) private _prism;
    mapping(address => Node) private _nodes;
    address[] _accounts;
    Tier[]  _tiers;
    
    address _redeemAddress; // 1.5% redeem
    uint    redeemAmount; // 1.5% redeem
    // uint    _controlAmount; // 1.5% redeem
    
    // FundLog[] _inLogs; // all deposit logs; 所有入金账本
    // FundLog[] _totalLogs;
    FundLog[] _luckyLogs;  // for 999 ~ 1001 layers; 位置奖金账本


    Order[] _buyBook;
    Order[] _sellBook;
    uint[][] _txBook;
    
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
    
    address[] _minerlist = new address[](50); //address  10ge
    
    // mapping(address=>uint) _minePool; // _minerlist index
    
    //构造方法， 合约创建时候执行
    constructor () public {
        _admin.account = ;
        _lee.account = ;
        _zhang.account = ;
        _redeemAddress = ;
        
        // uint _initialSupply  = maxSupply() * 20 / 100;
        // _mint(_admin.account, _initialSupply);

        //初始化会员等级
        _tiers.push(Tier({
            index: 1,
            min: 200 * _usdtUnit,
            staticRewards: 16,  // 0.1%
            sprigs: 1,
            limit: 2200        // 0.1% 综合收益倍数
        }));
        _tiers.push(Tier({
            index: 2,
            staticRewards: 14,
            min: 1001 * _usdtUnit,
            sprigs: 2,
            limit: 2100        // 0.1%
        }));
        _tiers.push(Tier({
            index: 3,
            staticRewards: 12,
            min: 2001 * _usdtUnit,
            sprigs: 3,
            limit: 2000        // 0.1%
        }));
        _tiers.push(Tier({
            index: 4,
            staticRewards: 10,
            min: 5001 * _usdtUnit,
            sprigs: 4,
            limit: 1900        // 0.1%
        }));    }
    /** 
    =================================================================
    ███╗░░░███╗██╗░░░░░███╗░░░███╗  ████████╗██████╗░███████╗███████╗

    ████╗░████║██║░░░░░████╗░████║  ╚══██╔══╝██╔══██╗██╔════╝██╔════╝
    ██╔████╔██║██║░░░░░██╔████╔██║  ░░░██║░░░██████╔╝█████╗░░█████╗░░
    ██║╚██╔╝██║██║░░░░░██║╚██╔╝██║  ░░░██║░░░██╔══██╗██╔══╝░░██╔══╝░░
    ██║░╚═╝░██║███████╗██║░╚═╝░██║  ░░░██║░░░██║░░██║███████╗███████╗
    ╚═╝░░░░░╚═╝╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚══════╝
    =================================================================
    */
    /**
     * @dev Return required number of TPS to member. 计算入金时候需要的TLB数量
     */
    function amountForDeposit(uint amount) public override view returns(uint256) {
        return (amount * _tlbUnit) / (price * 10); // 10% TPS of amount  // amount.mul(_tlbUnit).div(price.mul(10));   // 
    }
    /**
     * @dev Return required number of TPS to member. 计算出金的时候TLB数量，前1000层 5个，1001层开始2个
     */
    function amountForWithdraw(address account) public override view returns(uint256) {
        if (account==_zhang.account || account==_lee.account || account==_admin.account) return 0;
        return (_nodes[account].layer<1001 ? 5 : 2) * _tlbUnit; //  uint(10) ** decimals();
    }
    /**
     * internal
     * @dev Logically add users to prism.
     * At this time, if the current layer is filled by the user, the number of layers and the price of TPS tokens will change.
     * 新增用户时候，把用户加入到棱形位置中 返回总用户数
     */
    function addUserToPrism() internal returns(uint32) {
        //当前层 可以允许的最大用户数
        uint32 maxUsersInLayer = currentLayer < 1001 ? currentLayer : 2000 - currentLayer;
        //当前层会员填满，需要新加一层，TLB涨价0.01
        if (maxUsersInLayer == _positionInLayer) {
            currentLayer++;
            price += _tlbIncrement;
            _positionInLayer = 1;
        } else {
            _positionInLayer++;
        }
        //总用户增加1
        totalUsers++;
        return totalUsers;
    }
    
    /**
     * internal
     * @dev Returns tier index corresponding to deposit amount. 根据入金数额获取当前会员等级
     */
    function getTier(uint amount) internal view returns(uint) {
        for(uint i=_tiers.length; i>0;i--) {
            if (amount>=_tiers[i-1].min) return i;
        }
        return 0;
    }
    
    /**
     * internal
     * @dev returns last node in branch. 返回分支上的最长路径节点 递归 recursive
     */
    // function getLastInBranch(address parent) internal view returns(address){
        // Node storage parentNode = _nodes[parent];
        // return _nodes[parent].children.length==0 ? parent : getLastInBranch(_nodes[parent].children[0]);
    //}
    
    /**
     * internal
     * @dev Add or update a node when a user is deposited into the pool. 当用户存钱的时候，更新树形结构
     */
    function _deposit(address sender,address referalLink, uint amount, uint time) internal {
        uint32 userCount = totalUsers;
        // require(userCount < maxUsers, "# full_users");
        Node storage node = _nodes[sender];
        uint lastDeposit = node.lastAmount;
        uint _needTps = amountForDeposit(amount);
        require(sender!=_admin.account && sender!=_zhang.account && sender!=_lee.account,"#10");
        if (userCount==0 || node.position==1) {
            require(referalLink==_admin.account,"#11");    
        } else if (userCount<10 || node.position>1 && node.position<=10) {
            require(referalLink==firstAddress,"#12");
        } else if (_nodes[sender].lastAmount!=0) {
            require(_nodes[sender].referer==referalLink, "#13");
        } else {
            require(_nodes[referalLink].lastAmount!=0 && referalLink!=firstAddress, "#14");
        }
        require(balanceOf(sender)>=_needTps, "#15");
        require(lastDeposit==0 && amount>=_usdtUnit * 200 || lastDeposit>0 && (amount>=10000 || (amount - lastDeposit) >= _usdtUnit * 100), "#16");
        

        TransferHelper.safeTransferFrom(USDTToken, sender, address(this), amount);
        _burn(sender, _needTps);
        totalBurnt = totalBurnt.add(_needTps);
        
        //新用户第一次入金，改变树形结构
        if (node.lastTime==0) {
            uint32 position = addUserToPrism();
            //共生节点
            if (totalUsers==1) {
                node.role = NodeType.PNode;
                firstAddress = sender;
                node.parent = referalLink;
            } else if (currentLayer<5) { //股东节点
                node.parent = referalLink;
                node.role = NodeType.Shareholder;
                _nodes[node.parent].children.push(sender);
            } else { //其他用户
                Node storage refererNode = _nodes[referalLink];
                
                node.role = NodeType.Guest;
                // Node storage shareholderNode;
                node.shareholder = refererNode.role==NodeType.Shareholder ? referalLink : refererNode.shareholder;
                uint refcount = refererNode.referalCount;
                refererNode.referalCount++;
                //如果之前的路径上 推荐满了3个用户，则新开分支
                if (refcount>0 && refcount%3==0) {
                    node.parent = referalLink;
                    _nodes[referalLink].children.push(sender);
                } else {
                    uint len = refererNode.children.length;
                    address childaddr = len==0 ? referalLink : refererNode.children[len-1];
                    Node storage cnode = _nodes[childaddr];
                    if (cnode.root==address(0)) {
                        node.parent = cnode.lastChild==address(0) ? childaddr : cnode.lastChild;
                        node.root = childaddr;
                        cnode.lastChild = sender;
                    } else {
                        node.parent = _nodes[cnode.root].lastChild==address(0) ? childaddr : _nodes[cnode.root].lastChild;
                        node.root = cnode.root;
                        _nodes[cnode.root].lastChild = sender;
                    }
                    _nodes[node.parent].children.push(sender);
                }
            }
            node.userid = 100880011 + userCount;
            node.referer = referalLink;
            node.position = position;
            node.layer = currentLayer;
            node.balance = amount;
            
            // node.isOverflowed = false;
            node.referalCount = 0;
            if (position > 502503) { // save prism position from 1002 layer
                _prism[position] = sender;
            }
            _accounts.push(sender);
            emit AddUser(sender,totalUsers);
        } else { //老用户入金，不改变结构，直接改变本金
            /*
            if (_insuranceTime<node.lastTime) {
                (bool overflowed,uint staticRewards,,,) = profits(sender);
                if (!overflowed && staticRewards > 0) {
                    _updateDynamicRewardsAllParentNode(node);
                }
            }
            */
            node.staticRewards = 0;
            node.dynamicRewards = 0;
            node.balance += amount;
        }
        if (node.shareholder!=address(0)) {
            _nodes[node.shareholder].rewards += amount / 25; // 4%; 股东奖金
            // _nodes[node.shareholder].rewards = _nodes[node.shareholder].rewards.add(amount.mul(40).div(1000));// * 40 / 1000; // 4%; 股东奖金
        }
        
        //更新最后一次存款金额    
        node.lastAmount = amount;
        //更新最后一次存款时间
        node.lastTime = time;
        node.totalDeposit += amount;
        //重新计算会员等级
        uint8 tier = (uint8)(getTier(node.balance));
        //根据新的会员等级，计算综合收益
        node.limit = node.balance * _tiers[tier-1].limit / 1000;// * _tiers[tier-1].limit / 1000;
        //更新会员等级
        node.tier = tier;
        //更新爆仓状态 (这里可能需要修改，爆仓状态接触后，需要把会员的动态+静态 部分 设计为0， 股东奖励部分 不清零)
        redeemAmount += amount / 20;// * 50 / 1000; // 5% 回购资金
        _admin.rewards += amount / 50;// * 20 / 1000; // 2% 管理员奖金
        _zhang.rewards += amount * 15 / 1000; // * 15 / 1000; // 1.5% 张总奖金
        _lee.rewards += amount * 15 / 1000; // 1.5% 李总奖金
        
        totalDeposit += amount;
        _insuranceLastMember = sender;
        /*
        if (_insuranceMemberCount==36) {
            for(uint i=1; i<_insuranceMemberCount;i++) {
                _insuranceMembers[i-1] = _insuranceMembers[i-1];
            }
            _insuranceMemberCount = 35;
        }
        _insuranceMembers[_insuranceMemberCount] = sender;
        _insuranceMemberCount++;
        */
    }
    
    // update dynamicRewards of all parents (max 20)
    function _updateDynamicRewardsAllParentNode(Node storage node) internal {
        // Node storage parent;
        uint8 tier;
        uint rewards = 0;
        for(uint i=0; i<20; i++) {
            tier = node.parent==_admin.account ? 4 : _nodes[node.parent].tier;
            if (tier>=1 && i==1) {
                 rewards = node.staticRewards * sprigs[0][2] / 1000;// * sprigs[0][2] / 1000;
            } else if (tier>=1 && i==2) {
                 rewards = node.staticRewards * sprigs[1][2] / 1000;
            } else if (tier>=2 && i>=3 && i<=7) {
                 rewards = node.staticRewards * sprigs[2][2] / 1000;
            } else if (tier>=3 && i>=8 && i<=16) {
                 rewards = node.staticRewards * sprigs[3][2] / 1000;
            } else if (tier>=4) {
                 rewards = node.staticRewards * sprigs[4][2] / 1000;
            }
            if (rewards>0) {
                if (node.parent==_admin.account) {
                    _admin.rewards += rewards;
                    break;
                } else {
                    _nodes[node.parent].dynamicRewards += rewards;
                }
            }
        }
    }
    // for test
    function _staticRewardOf(Node storage node,uint lasttime) internal view returns(uint) {
        if (lasttime<node.lastTime) lasttime = node.lastTime;
        if (lasttime<_insuranceTime || node.tier<1) return 0;
        uint date = (now - lasttime).div(1 days); //1 days
        return node.staticRewards + node.balance * _tiers[node.tier-1].staticRewards * date / 1000;
    }
    
    function _childrenInfo(address account, uint lasttime, uint deep, uint maxDeep) internal view returns(uint) {
        if (lasttime<_insuranceTime) return 0;
        Node storage node = _nodes[account];
        uint countBranch = (deep!=0 || account==firstAddress) ? node.children.length : node.referalCount / 3;
        uint staticRewards = 0;
        uint rewards = 0;
        for (uint i = 0; i<countBranch; i++) {
            address _child = node.children[i];
            Node storage _childNode = _nodes[node.children[i]];
            
            staticRewards = _staticRewardOf(_childNode,lasttime);
            if (deep==0) {
                 rewards += staticRewards * sprigs[0][2] / 1000;
            } else if (deep==1) {
                 rewards += staticRewards * sprigs[1][2] / 1000;
            } else if (deep>=2 && deep<=6) {
                 rewards += staticRewards * sprigs[2][2] / 1000;
            } else if (deep>=7 && deep<=15) {
                 rewards += staticRewards * sprigs[3][2] / 1000;
            } else {
                 rewards += staticRewards * sprigs[4][2] / 1000;
            }
            if (deep<maxDeep-1) {
                rewards += _childrenInfo(_child, lasttime, deep+1, maxDeep);
            }
        }
        return rewards;
    }
    
    function _childrenInfoAll(address account, uint deep) internal view returns(uint, uint) {
        Node storage node = _nodes[account];
        uint _children = 0;
        uint _totalDeposit = 0;
        for(uint i = 0; i<node.children.length; i++) {
            address _child = node.children[i];
            Node storage _childNode = _nodes[node.children[i]];
            if (deep<19) {
                (uint count, uint funds)= _childrenInfoAll(_child, deep+1);
                _children += count;
                _totalDeposit += funds;
            }
            _children++;
            _totalDeposit += _childNode.totalDeposit;
        }
        
        return (_children, _totalDeposit);
    }
    //计算合约中剩余USDT数目
    function _totalUsdtBalance() internal view returns(uint) {
        return IHRC20(USDTToken).balanceOf(address(this));
    }
    //计算合约中剩余USDT数目
    function _insuranceAmount() internal view returns(uint) {
        return _totalUsdtBalance() / 20;// * 50 / 1000;
    }
    
    function contractInfo() public view returns(uint[21] memory) {
        // (uint _mCount,) = _minerRealPower();
        return [
            price,
            currentLayer,
            totalUsers,
            totalMineable,
            _insuranceTime,
            totalDeposit,
            totalWithdraw,
            redeemAmount,
            _totalSupply,
            totalBurnt,
            _insuranceCounterTime,
            _insuranceAmount(),
            // 矿机信息
            _minerCount,
            _minerTotalPower,
            // _minerCount,
            _minerPrice(0),
            _minerPrice(1),
            _minerPrice(2),
            _minerPrice(3),
            _minerClass[0],
            _minerClass[1],
            _minerClass[2]
            
        ];
    }
    
    function accountInfo(address account) public view returns(uint[9] memory,address) {
        require(account!=address(0), "invalid_account");
        uint _userid = 0;
        uint _adep = 0;
        uint _aw = 0;
        uint _limit = 0;
        uint _lastAmount = 0;
        uint _children = 0;
        uint _totalDeposit = 0;
        uint _tlb = balanceOf(account);
        uint _balance = 0;
        Node storage node = _nodes[account];
        if (account==_admin.account) {
            _aw = _admin.totalRewards;
            (uint count,uint funds) = _childrenInfoAll(firstAddress, 1);
            _children = 1 + count;
            _totalDeposit = _nodes[firstAddress].totalDeposit + funds;
        } else if (account==_zhang.account) {
            _aw = _zhang.totalRewards;
        } else if (account==_lee.account) {
            _aw = _lee.totalRewards;
        } else {
            _userid = node.userid;
            _lastAmount = node.lastAmount;
            _aw = node.totalWithdrawal;
            _adep = node.totalDeposit;
            _limit = node.limit;
            _balance = node.balance;
            (_children,_totalDeposit) = _childrenInfoAll(account, 0);
        }
        
        return ([
            _userid,_tlb,_lastAmount,_adep,_aw,_limit,_children,_totalDeposit,_balance
        ],node.referer);
    }
    function nodeinfo(address sender) public view returns(uint, address, address, address, address, address[] memory) {
        return (_nodes[sender].referalCount, _nodes[sender].shareholder, _nodes[sender].root, _nodes[sender].parent, _nodes[sender].parent,_nodes[sender].children);
    }
    function mlmtree(uint start_,uint count_) public view returns(address[] memory addrs) {
        if (count_==0) count_ = _accounts.length;
        addrs = new address[](count_ * 2);
        if (start_==0) {
            addrs[0] = firstAddress;
            start_ = 1;
        } else {
            start_--;
        }
        for(uint i=start_; i<count_; i++) {
            addrs[i*2] = _accounts[i];
            addrs[i*2+1] = _nodes[_accounts[i]].parent;
        }
    }
    
    function profits(address account) public view returns(bool, uint, uint, uint, uint) {
        bool overflowed = false;
        uint staticRewards = 0;
        uint dynamicRewards = 0;
        uint rewards = 0;
        uint withdrawal = 0;
        //计算管理员可提现 正确
        if (account==_admin.account) {
            Node storage node = _nodes[firstAddress];
            rewards = _admin.rewards;
            uint lastTime = _admin.lastWithdrawTime > node.lastTime ? _admin.lastWithdrawTime : node.lastTime;
            dynamicRewards = _staticRewardOf(node,lastTime) * sprigs[0][2] / 1000 + _childrenInfo(firstAddress,lastTime, 1, 19);
            withdrawal = rewards.add(dynamicRewards);
        } else if (account==_zhang.account) { //计算张总可提现金额 正确
            rewards = _zhang.rewards;
            withdrawal = rewards;
        } else if (account==_lee.account) { //计算李总可提现 正确
            rewards = _lee.rewards;
            withdrawal = rewards;
        } else { //计算其他会员可提现 动态+静态+奖金（位置奖金 或者 股东奖励）正确
            Node storage node = _nodes[account];
            overflowed = node.lastTime < _insuranceTime;
            if (node.tier>0) {
                rewards = node.rewards;
                Tier storage tier = _tiers[node.tier-1];
                staticRewards = _staticRewardOf(node,node.lastTime);
                dynamicRewards = _childrenInfo(account,node.lastTime, 0, sprigs[tier.sprigs][1]);
                if (node.layer>998 && node.layer<1002) {
                    for(uint i=0;i<_luckyLogs.length;i++) {
                        FundLog storage _log1 = _luckyLogs[i];
                        if (_log1.time>node.lastTime) { //如果上一次提现时间，在奖金统计时间中。 则将奖励 计算给用户
                            rewards = _log1.balance / 2998;
                        }
                    }
                }
                overflowed = overflowed || staticRewards + dynamicRewards + rewards > node.balance * tier.limit / 1000;
                if (!overflowed) {
                    if (node.layer<5) {
                        withdrawal = (staticRewards + dynamicRewards) * 85 / 100 + rewards;
                    } else if (node.layer>998) {
                        withdrawal = (staticRewards + dynamicRewards + rewards) * 85 / 100;
                    } else {
                        withdrawal = (staticRewards + dynamicRewards) * 85 / 100;
                    }
                }
            }
        }
        return (overflowed, staticRewards, dynamicRewards, rewards, withdrawal);
    }
    
    // must call this function every 36hrs on server backend
    function checkInsurance() public override {
        require(msg.sender==hero, "#21");
        if (now - _insuranceInitial >= 60 days - _insuranceLimit) {
            uint diff = now - _insuranceCounterTime;
            if (_insuranceDeposit>0) {
                bool triggered = ((totalDeposit - _insuranceDeposit) * 10000 / _insuranceDeposit) < 20 &&  diff >= _insuranceLimit;
                uint amount = _insuranceAmount();
                if (triggered) {
                    TransferHelper.safeTransfer(USDTToken, _insuranceLastMember, amount);
                    _insuranceTime = now;
                }
                emit Insurance(_insuranceLastMember, amount);
            }
            _insuranceDeposit = totalDeposit;
            _insuranceCounterTime = now - diff % _insuranceLimit;
            // _insuranceMemberCount = 0;
        }
    }
    
    //入金方法 外部调用 正确
    function deposit(address referalLink, uint amount) public override{
        address sender = msg.sender;
        require(sender!=address(0) && referalLink!=address(0), "#1");
        // require(referalLink!=address(0), "#2");
        _deposit(sender, referalLink, amount, now);
    }

    //提现方法 管理员 出金也需要TLB 管理员购买矿机，可以不要钱
    function withdraw() public override {
        address sender = msg.sender;
        require(sender!=address(0), "#1");
        //计算当时间，会员可提金额
        (bool overflowed, uint staticRewards, uint dynamicRewards, uint rewards, uint withdrawable) = profits(sender);
        require(!overflowed, "#3");
        //管理员提现，不扣任何手续费，然后系统记录总账 管理员不能作为用户 参与游戏）
        if (sender==_admin.account) {
            _admin.rewards = 0;
            _admin.totalRewards += withdrawable;
            _admin.lastWithdrawTime = now;
        } else if (sender==_zhang.account) { //张总提现，只扣张的奖金部分，然后系统记录总账（注意，张总地址不能作为用户 参与游戏）
            _zhang.rewards = 0;
            _zhang.totalRewards += withdrawable;
            _zhang.lastWithdrawTime = now;
        } else if (sender==_lee.account) { //李总提现，只扣李的奖金部分，然后系统记录总账（注意，李总地址不能作为用户 参与游戏）
            _lee.rewards = 0;
            _lee.totalRewards += withdrawable;
            _lee.lastWithdrawTime = now;
        } else { //会员提现
            Node storage node = _nodes[sender];
            if (node.balance>0) {
                if (staticRewards > 0) {
                    _updateDynamicRewardsAllParentNode(node);
                }
                node.totalWithdrawal += withdrawable;
                node.lastTime = now;
                node.staticRewards = 0;
                node.dynamicRewards = 0;
                node.rewards = 0;
                
                //计算方式 正确
                uint benefit = staticRewards + dynamicRewards;
                uint half = (benefit + rewards) / 2;
                if (node.balance > half) {
                    node.balance -= half;
                    uint8 tier = (uint8)(getTier(node.balance));
                    if (tier==0) {
                        node.tier = 0;
                        // node.balance = 0;
                        node.limit = 0;
                    } else {
                        node.tier = tier;
                        node.limit = node.balance * _tiers[tier-1].limit / 1000;
                    }
                } else {
                    node.tier = 0;
                    node.balance = 0;
                    node.limit = 0;
                }
                // Symmetrische Positionsbelohnung 对称位置奖金  (动态收益+静态收益)*50%*30%*50%
                if (node.layer<999) {
                    uint pos = benefit * 75 / 1000; 
                    uint32 idx = 1e6 - node.position;
                    if (totalUsers>idx) {
                        //该位置没有用户时候，应该记录奖金累计数。 有用户时候，应该将该奖金加到用户rewards
                        
                        address posAddr = _prism[idx]; //对称位置 计算错误
                        Node storage posNode = _nodes[posAddr];
                        posNode.rewards += pos;
                    }
                    // Belohnung für jede Position 999-1000-1001 (insgesamt 2998 Personen) 999-1000-1001层 2998 个位置 
                    _luckyLogs.push(FundLog({
                        time:now,
                        balance:pos,
                        tier:0
                    }));
                } else { //其他情况，记录回购资金
                    redeemAmount += benefit * 15 / 100;
                }
            }
        }
        //如果可提金额大于0
        if (withdrawable>0) {
            //计算需要燃烧的TLB数量
            TransferHelper.safeTransfer(USDTToken, sender, withdrawable);
            totalWithdraw += withdrawable;
            uint _needTps = amountForWithdraw(sender);
            if (_needTps>0) {
                //燃烧用户钱包中的TLB
                _burn(sender, _needTps);
                //统计 总计燃烧数额
                totalBurnt += _needTps;
            }
        }
        // _processSellOrder(86400);
    }
    
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

    function _buy(address sender, uint amountUsdt) internal {
        uint _tlbInit = amountUsdt * _tlbUnit / price; // amountUsdt.mul(_tlbUnit).div(price);
        uint _tlb = _tlbInit;
        
        uint countRemove = 0;
        uint txCount = _txBook.length;
        TransferHelper.safeTransferFrom(USDTToken, sender, address(this), amountUsdt);
        for(uint i=0; i<_sellBook.length; i++) {
            Order storage order = _sellBook[i];
            if (order.balance>=_tlb) {
                uint amount = _tlb * price * 998 / _tlbUnit / 1000;
                TransferHelper.safeTransfer(USDTToken, order.account, amount);
                _txBook.push([10001 + (txCount++),0,_tlb,now]);
                order.balance -= _tlb;
                _tlb = 0;
                if (order.balance==0) countRemove++;
                break;
            } else {
                uint amount = order.balance * price * 998 / _tlbUnit / 1000; // * price * 998 )  / (_tlbUnit * 1000);
                TransferHelper.safeTransfer(USDTToken, order.account, amount);
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
            _transfer(address(this), sender, _tlbInit - _tlb);
        }
        // _processSellOrder(86400);
    }
    //购买TLB 方法正确
    function buy(uint amountUsdt) public override {
        address sender = msg.sender;
        require(sender!=address(0), "#1");
        _buy(sender, amountUsdt);
    }

    //撤销买单，当 卖队列无法满足 买队列时 正确
    function cancelBuyOrder() public override {
        address sender = msg.sender;
        require(sender!=address(0), "#1");
        uint balance = 0;
        for(uint i=0;i<_buyBook.length;i++) {
            if (_buyBook[i].account==sender) {
                balance  = balance.add(_buyBook[i].balance);
                _buyBook[i].balance = 0;
            }
        }
        if (balance>0) {
            _rebuildOrders(true);
            TransferHelper.safeTransfer(USDTToken, sender, balance);
            emit BuyOrderCancelled(sender, balance);
        }
    }
    function _sell(address sender, uint amountTlb) internal {
        uint _usdtInit = amountTlb * price / _tlbUnit;
        uint _usdt = _usdtInit;
        
        uint countRemove = 0;
        uint txCount = _txBook.length;
        _transfer(sender, address(this), amountTlb);
        for(uint i=0; i<_buyBook.length; i++) {
            Order storage order = _buyBook[i];
            if (order.balance>=_usdt) {
                uint _tlb = _usdt * _tlbUnit / price; // * _tlbUnit / price;
                _transfer(address(this), order.account, _tlb);
                _txBook.push([10001 + (txCount++),1,_tlb,now]);
                order.balance = order.balance.sub(_usdt);
                _usdt = 0;
                if (order.balance==0) countRemove++;
                break;
            } else {
                uint _tlb = order.balance * _tlbUnit / price; // * _tlbUnit / price;
                _transfer(address(this), order.account, _tlb);
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
        if (_usdtInit.sub(_usdt)>0) {
            TransferHelper.safeTransfer(USDTToken, sender, (_usdtInit - _usdt) * 998 / 1000);
        }
        // _processSellOrder(86400);
    }
    //卖出 TLB 方法正确
    function sell(uint amountTlb) public override {
        address sender = msg.sender;
        require(sender!=address(0), "#1");
        _sell(sender, amountTlb);
    }
    //撤销卖单
    function cancelSellOrder() public override {
        address sender = msg.sender;
        require(sender!=address(0), "#1");
        uint balance = 0;
        for(uint i=0;i<_sellBook.length;i++) {
            if (_sellBook[i].account==sender) {
                balance = balance.add(_sellBook[i].balance);
                _sellBook[i].balance = 0;
            }
        }
        if (balance>0) {
            _rebuildOrders(false);
            _transfer(address(this), sender, balance);
            emit SellOrderCancelled(sender, balance);
        }
        // _processSellOrder(86400);
    }
    //查询订单历史记录
    function orderHistory() public override view returns(uint[4][] memory) {
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
    function pendingOrder(address account) public view returns(uint[4][] memory) {
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
    function redeemSellOrders() public override {
        require(msg.sender==hero,"#21");
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
                order.balance = 0;
                redeemAmount -= _usdt;
                _redeem -= _usdt;
                _sumTps += _tlb;
                TransferHelper.safeTransfer(USDTToken, order.account, _usdt * 998 / 1000);
                _txBook.push([10001 + (txCount++),1,_tlb,now]); // 2 means redeem
            }
            if (_sumTps>0) {
                _rebuildOrders(false);
                _transfer(address(this), _redeemAddress, _sumTps);
            }
        }
        emit RedeemOrder(_count,_sumTps);
    }

    /**
    =======================================================================================
    
    ░██████╗████████╗░█████╗░██╗░░██╗██╗███╗░░██╗░██████╗░  ████████╗██╗░░░░░██████╗░
    ██╔════╝╚══██╔══╝██╔══██╗██║░██╔╝██║████╗░██║██╔════╝░  ╚══██╔══╝██║░░░░░██╔══██╗
    ╚█████╗░░░░██║░░░███████║█████═╝░██║██╔██╗██║██║░░██╗░  ░░░██║░░░██║░░░░░██████╦╝
    ░╚═══██╗░░░██║░░░██╔══██║██╔═██╗░██║██║╚████║██║░░╚██╗  ░░░██║░░░██║░░░░░██╔══██╗
    ██████╔╝░░░██║░░░██║░░██║██║░╚██╗██║██║░╚███║╚██████╔╝  ░░░██║░░░███████╗██████╦╝
    ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░  ░░░╚═╝░░░╚══════╝╚═════╝░
    =======================================================================================
    */
    
    //矿工信息， 返回 算力，挖矿方式，是否激活
    
    //计算 矿机价格每增加一层 认购价格 矿机认购价格在原基础上 增加0.1% 正确
    function _minerPrice(uint tier) internal view returns(uint) {
        require(tier>=0 && tier<=3, "#4");
        return _minerTiers[tier][0] + _minerTiers[tier][0] * currentLayer / 1000;
        // return _minerTiers[tier][0].add(_minerTiers[tier][0].mul(currentLayer).div(1000));
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
    function _startMine(address account) internal {
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
    function _stopMine(address account) internal returns(uint) {
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
    function mineInfo(address account) public override view returns(uint[12] memory,address) {
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
    function _buyMiner(address sender, address referalLink, uint tier) internal {
        Miner storage miner= _miners[sender];
        uint _tierpower = _minerTiers[tier][1];
        uint amountUsdt = _minerPrice(tier);
        if (sender!=_admin.account) {
            uint referalRewards = 0;
            uint referalRewardRate = currentLayer<=100 ? _minerTiers[tier][2] : _minerTiers[tier][3];
            referalRewards = amountUsdt * referalRewardRate / 1000;
            TransferHelper.safeTransferFrom(USDTToken, sender, address(this), amountUsdt);//  - referalRewards + referalRewards * 10 / 100);
            if (referalLink!=address(0)) {
                uint directRewards = referalRewards * 90 / 100;
                TransferHelper.safeTransfer(USDTToken, referalLink, directRewards);
                if (miner.tier==0) {
                    _referedMiners[referalLink].push(sender);
                    miner.referer = referalLink;
                } else {
                    require(miner.referer == referalLink, "#2");
                }
            }
            redeemAmount += referalRewards / 10;
            _admin.rewards += amountUsdt / 50; // 2%
            _zhang.rewards += amountUsdt * 15 / 1000; // 1.5%
            _lee.rewards += amountUsdt * 15 / 1000; // 1.5%
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
        miner.minable += amountUsdt * _tlbUnit * 12 / (10 * price);
        _minerTotalPower += _tierpower;
        miner.lastTime = now;
        emit AddMiner(sender,_tierpower);
    }
    function buyMiner(address referalLink, uint amountUsdt) public override {
        address sender = msg.sender;
        require(sender!=address(0) && sender!=referalLink, "#1");
        _buyMiner(sender,referalLink,amountUsdt);
    }
    //触发领取奖励动作 正确
    function withdrawFromPool() public override{
        address sender = msg.sender;
        require(sender!=address(0), "#1");
        Miner storage miner= _miners[sender];
        uint withdrawal = _stopMine(sender);
        require(withdrawal>0, "#1");
        require(_minedTotal + withdrawal <= totalMineable, "#33");
        miner.rewards += withdrawal;
        miner.pending = 0;
        _minedTotal += withdrawal;
        _mint(sender, withdrawal);
    }
    function startMine() public override {
        require(msg.sender!=address(0), "#1");
        _startMine(msg.sender);
    }
    
    function minerList() public override view returns(address[] memory,uint[] memory,uint[] memory) {
        address[] memory _aaddrs = new address[](10);
        uint[] memory _atiers = new uint[](10);
        uint[] memory _aBlocks = new uint[](10);
        uint k = 0;
        address account;
        for(uint i=0; i<50; i++) {
            account = _minerlist[i];
            if (account!=address(0) && account!=_admin.account && _miners[account].lastBlock+9600 > block.number) {
                _aaddrs[k]  = account;
                _atiers[k]  = _miners[account].tier;
                _aBlocks[k] = _miners[account].lastBlock;
                k++;
                if (k==10) break;
            }
        }
        return (_aaddrs,_atiers,_aBlocks);
    }
    
    /* 
    =================================================================================================
                            
                            █▀▀ █▀█ █▀█   ▀█▀ █▀▀ █▀ ▀█▀ █▀█ █▄░█ █░░ █▄█
                            █▀░ █▄█ █▀▄   ░█░ ██▄ ▄█ ░█░ █▄█ █░▀█ █▄▄ ░█░
                                    必须在主网发布前移除。
    =================================================================================================
    */
    function _test_mint(address sender, uint amount) public override {
        require (msg.sender==owner() || msg.sender==USDTToken,"#0");
        _mint(sender, amount);
    }
    function _test_deposit(address sender, address referalLink, uint amount) public override {
        require (msg.sender==owner() || msg.sender==USDTToken,"#0");
        _deposit(sender, referalLink, amount, now);
    }
    function _test_buyMiner(address sender, address referalLink, uint tier) public override {
        require (msg.sender==owner() || msg.sender==USDTToken,"#0");
        _buyMiner(sender,referalLink,tier);
        _startMine(sender);
    }
    function _test_MinerPrice(uint tier) public override view returns(uint) {
        require (msg.sender==owner() || msg.sender==USDTToken,"#0");
        return _minerPrice(tier);
    }
}