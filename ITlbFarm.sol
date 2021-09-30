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


interface ITlbFarm{
    event AddMiner(address guest, uint amount);
    //矿工
    struct Miner {
        uint mineType;
        address referer;//推荐人
        uint tier;//算力
        uint lastBlock;//上一次激活挖矿时间
        uint rewards;// 总提现的TLB数量
        uint pending;
        uint minable;
        uint lastTime; // 最后购买矿机时间
        uint[] miners;
    }
    //矿工信息
    struct MinerInfo {
        address account; //地址
        uint tier;//算力
    }
    
    function _minerPrice(uint tier, uint currentLayer) external view returns(uint);
    function _startMine(address account) external;
    function _stopMine(address account) external returns(uint);
    function _mineInfo(address account) external view returns(uint[12] memory,address);
    function _mineInfo2(uint currentLayer) external view returns(uint[9] memory);
    function _buyMiner(address sender, address referalLink, uint tier, uint currentLayer) external returns(uint referalRewards);
    function _withdrawFromPool(address account) external returns(uint _minedTotal, uint _withdrawal);
    
    function _minerList(address _address) external view returns(address[] memory,uint[] memory,uint[] memory);
}