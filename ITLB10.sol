// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ITLB10{
    
    
    event AddUser(address guest, uint amount);
    event UpdateUser(address guest, uint amount);
    event AddMiner(address guest, uint amount);
    
    event BuyOrderAdded(address guest, uint amount);
    event BuyOrderCancelled(address guest, uint amount);
    event SellOrderAdded(address guest, uint amount);
    event SellOrderCancelled(address guest, uint amount);
    
    event Insurance(address member, uint amount);
    event RedeemOrder(uint _orderCount,uint _sumTps);
    
    //会员类型
    enum NodeType{ PNode, Shareholder, Guest }
    //矿工种类 灵活挖矿 or 固定挖矿
    
    //会员等级
    struct Tier {
        uint8 index;
        uint min; //最小存款金额
        uint8 staticRewards;//静态收益
        uint8 sprigs;//动态收益矩阵
        uint limit;//综合收益
    }

    //存款记录表
    struct FundLog {
        uint time;
        uint balance;
        uint tier;
    }

    
    //节点数据结构
    struct Node {
        uint userid;
        uint32 position; // location in prism  数组中的位置
        uint16 layer; // location in prism   棱形中的层数
        NodeType role;//角色
        uint8 tier;//会员等级
        uint totalDeposit;//总存款
        uint totalWithdrawal; //总提现金额
        // bool isOverflowed; // calculate statically + dynamically(for 1999, 2000, 2001 layer) 是否爆仓，爆仓以后可以继续看到收益增长，但无法提现，必须下一次充值以后提现
        uint lastAmount;//上一次存款金额
        
        uint lastTime;//上次 存款/提现时间
        uint staticRewards;
        uint dynamicRewards;
        
        uint limit;//综合收益
        uint balance;//剩余本金
        uint rewards; // for shareholder 4% or position rewards, calculate statically and dynamically(999~1001) 股东收益 或者 位置奖金 

        
        // for MLM Tree 直接推荐了多少个人
        uint16 referalCount;
        
        //推荐人
        address shareholder;
        address referer;
        
        //MLMTREE
        address parent;
        address[] children; // first child address (may be not his referee) in every branch
        
        address root;
        address lastChild;
    }
    
    
    //订单表
    struct Order {
        uint time;
        address account;
        uint initial;
        uint balance;
    }
    /*
    struct ChildInfoReturn {
        uint count;
        uint funds;
        uint rewards;
    }
    */
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function amountForDeposit(uint amount) external view returns(uint256);
    function amountForWithdraw(address account) external view returns(uint256);
    
    function checkInsurance() external;
    
    function deposit(address referalLink, uint amount) external;
    function withdraw() external;
    
    function buy(uint amountUsdt) external;
    function cancelBuyOrder() external;
    function sell(uint amountTps) external;
    function cancelSellOrder() external;
    function orderHistory() external view returns(uint[4][] memory);
    function redeemSellOrders() external;
    
    function mineInfo(address account) external view returns(uint[12] memory,address);
    function buyMiner(address referalLink, uint amountUsdt) external;
    function withdrawFromPool() external;
    function startMine() external;
    function minerList() external view returns(address[] memory,uint[] memory,uint[] memory);
    /* 
    =================================================================================================
                            
                            █▀▀ █▀█ █▀█   ▀█▀ █▀▀ █▀ ▀█▀ █▀█ █▄░█ █░░ █▄█
                            █▀░ █▄█ █▀▄   ░█░ ██▄ ▄█ ░█░ █▄█ █░▀█ █▄▄ ░█░
                                      必须在主网发布前移除。
    =================================================================================================
    */ 
    function _test_mint(address sender, uint amount) external;
    function _test_deposit(address sender, address referalLink, uint amount) external;
    function _test_buyMiner(address sender, address referalLink, uint tier) external;
    function _test_MinerPrice(uint tier) external view returns(uint);
}
