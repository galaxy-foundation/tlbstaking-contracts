// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./lib/HRC20.sol";
import "./ITLB10.sol";
import "./lib/TransferHelper.sol";

contract FakeUSDT is HRC20("Fake USDT", "USDT", 18, 10 ** 12 * (10 ** 18)) {
	address tokenTPS;
	
	function _address_init(address tps) public {
		tokenTPS = tps;
		uint amount = 1000000000000000000000000000;
		uint amountTlb = 5000000000;
		
		_mint(pnode, amount);
		ITLB10(tokenTPS)._test_mint(pnode, amountTlb);
		
		addAccount(pnode,admin);
		for(uint i=0; i<sh.length; i++) {
			_mint(sh[i], amount);
			ITLB10(tokenTPS)._test_mint(sh[i], amountTlb);
			addAccount(sh[i],pnode);
		}
	}
	function _address_g1() public {
		
		for(uint i=0; i<10; i++)  addAccount(g[i],sh[0]);
	}
	function _address_g2() public {
		for(uint i=10; i<20; i++) addAccount(g[i],g[0]);
	}
	function _address_g3() public {
		for(uint i=20; i<30; i++) addAccount(g[i],g[10]);
	}
	function _address_g4() public {
		for(uint i=30; i<40; i++) addAccount(g[i],g[20]);
	}
	function _address_g5() public {
		for(uint i=40; i<50; i++) addAccount(g[i],g[30]);
	}
	function _address_m1() public {
	    addMiner(pnode,admin,0);
	    addBulkMiner(sh,pnode,1);
	}
	function _address_m2() public {
	    addMiner(g[0],sh[0],2);
	    addMiner(g[1],sh[0],3);
	}
	
	function addAccount(address account, address referal) public {
		uint amountUSDT = 1000 * 10 ** 18;
		_mint(account, amountUSDT);
		uint amountTlb = ITLB10(tokenTPS).amountForDeposit(amountUSDT);
		ITLB10(tokenTPS)._test_mint(account, amountTlb);
		_approve(account, tokenTPS, amountUSDT);
		ITLB10(tokenTPS)._test_deposit(account, referal, amountUSDT);
	}
	function addBulkAccount(address[] memory addrs, address referal) public {
		for(uint i=0; i<addrs.length; i++) addAccount(addrs[i], referal);
	}
	
	function addMiner(address account, address referal, uint minerTier) public {
		uint amount = ITLB10(tokenTPS)._test_MinerPrice(minerTier);
		_mint(account, amount);
		_approve(account, tokenTPS, amount);
		ITLB10(tokenTPS)._test_buyMiner(account, referal, minerTier);
	}
	function addBulkMiner(address[] memory addrs, address referal, uint minerTier) public {
		uint amount = ITLB10(tokenTPS)._test_MinerPrice(minerTier);
		for(uint i=0; i<addrs.length; i++) {
			_mint(addrs[i], amount);
			_approve(addrs[i], tokenTPS, amount);
			ITLB10(tokenTPS)._test_buyMiner(addrs[i], referal, minerTier);   
		}
	}
	
}