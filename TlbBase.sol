// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract TlbBase {
    address hero = ;
    // heco mainnet 
    // address USDTToken = ;
    address USDTToken = ;
    uint8   USDTPrecision = 18;
    uint    _usdtUnit = uint(10) ** USDTPrecision;
    uint    _tlbUnit = uint(10) ** 4;
    
    
    //管理员
    struct Admin {
        address account;
        uint rewards;
        uint totalRewards;
        uint lastWithdrawTime;
    }
    Admin _admin;
    Admin _zhang;
    Admin _lee;
    
    
    address _contractTlb;
    
    function contractTlb() public view returns(address) {
        return _contractTlb;
    }
    
    function setContractTlb(address _address) public {
        _contractTlb = _address;
    }
    
    function onlyContract() public view {
        require(msg.sender==_contractTlb, 'TlbBase: caller is not the tlb');
    }
}