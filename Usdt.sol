// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./lib/HRC20.sol";
import "./ITlbMlm.sol";
import "./lib/TransferHelper.sol";

contract USDT is HRC20("Fake USDT", "USDT", 18, 10 ** 12 * (10 ** 18)) {
	address tokenTPS;
	address admin = 0xbb0B8ffdf2c81407948f8Be3BF881080a45DB227;
	address pnode = 0x82bC5Cd564EA21642910796aE7Ec675772AE642F;
	
	address[] sh = [
		0x8eECD63101878DAF5879495f85ca7067a5e63969,
		0x50F390FE885bf0A68c49054367C1b763EAfE59D1,
		0x146a522C1985B72d9b04a1E73Df579823376e39A,
		0xa300f601a4A479Ed74c0204b90331597128387d3,
		0xe5a308Be4D5ecd55d590f7b7Fb490038aa53b2b7,
		0xd27Da575AC9f178aaa1D9D113b7e2895865B39F2,
		0x231a713dC82d39aC050dc50F379eC0c431945256,
		0x79938398F8C55B483977856b123350c8e1d71109,
		0x04577360A1093199e46D5E5404DC20325A337e87
	];
	address[] g = [
		0x7d219C82EfB45347c265F19571D54de3E01F8620,
        0x708F6bEa5d7d9DF9E5E531647CA6FE0c95c432D5,
        0x067A3D53fE3390A60C5b13E2d4207f429bF7799E,
        0x2742d710dbfA64507F3Bd447d5A7FB9e23D1228C,
        0xd786D4A18e6FA2aD7522fBd1894CAab3061166c3,
        0x354D4d2740D23E039B86e653De4aE47411024133,
        0x345F9D5415CaA5E38713a902C311Cd2d7Aa2871D,
        0xa55207B45a2B6599872931204dAf6bAF34a098d3,
        0x9Fe211CC1868C0D532cDF052Fe1FB1C6540bff66,
        0xE0bED4790331e46Cc0A3D2b7C7a18D4706258819,
        0xB5D82dBcc63C7c598F9D9e0842d02B32e00b8bAf,
        0x3F7993C001cdBFaDf88bC9e3821eBAe55126dA6C,
        0xe5aD1beec18235a1f8201f280c971a29BbE466fe,
        0xf0CF4aF25b568FeE923B03daA9C9cA910C38E198,
        0xb9E5c9fFd910C49624D29D089081917F0eBd7A85,
        0x4954313bE39dE310CaccF01031394d104571Dd96,
        0x3E79A63802eCD258b091caFE2133dBe45CDae125,
        0xCE554bC610286fD2bA41776eD723E0A09E7892aE,
        0xE3531804d1f3ec2035a28B08deF11dB7948D8ea0,
        0x09c65eeAD225366402bE3a4f822aBED2a96F8532,
        0x8b93cD8836035CDe7DBCfAd79A8E2c8455467694,
        0x812957Aae15c722217066B2a47a5458990171454,
        0x3EB065a8939EA62ad5d68f7eF3c04649A080c062,
        0x0903311320635D38D4Ed8319902843FF3Cb04df2,
        0xD6c006D4a9DB98Bc75A3475FEE95CEe65dde00b1,
        0x50cd9fEFe486681bf62137aa6cc2B4D3351Db57D,
        0x1A0C823c5658B52606b1f3ae63BA7Bb937F8a188,
        0xbA031ACe5b5f26165905Feb1B1902e9a9f3cDbF9,
        0x4DC76B0Bc9Dd7C8F9Ac0b6035D2286832F6CD1Ef,
        0xcbdAD5dfB11A1C5fd38A29e1F0cC3D15dFEEDAbd,
        0x6C3C971184fe26d12D5D5F8a5b4682aC8631E375,
        0xD5EF18505476DF1566DAEE1370Dab14d4aa91bf4,
        0xd0c6FB22850bc60A05933e70280fCbDD41248870,
        0x42E373942625B1a8681968C29F5dB94352619Ce5,
        0x73A82AF9Bee7F4bb3D40A9740BF075AEcaEaD1aa,
        0x670207796a3b304301267fD113cd72f6531320Fa,
        0x68692d95b11cec11C03Cb1003Db23497ACc913e9,
        0x8284Ed3F2666A366Dd8144a344Ca20E593145DFA,
        0x55cfaad14d36dd1845B89FBEDF2eAB6272B23519,
        0x3F22A7EECd59d4E278BC1e89B71aE649529599e1,
        0x9EB42AeCC35a0ab3d078f2182F42349D9eb2ea85,
        0x01DF4Da4716F65a82fA77F05AD85604D20cBEEBA,
        0xd5227ef4366225ad7F5d9748497519E62872067d,
        0x9DB0F2cfac46015a9D91573E86DE3998D65c73a0,
        0xe91Fe9Ac86e70256c35c237cD8538D111Dfd5f42,
        0x15bcadCA00BA4f75c1c8C27a8a90Cb02758Fb65D,
        0xD82370d543b8b475cFca888307bEd13C167687A8,
        0xdBB7A45C1Bc70E290cBE7b607ac01E02a4BE387b,
        0x9F1EB67120923BB4e7De03989af861c654f37B63,
        0x7aDb35925EDA5918559fCe63Eb5CD8E0B6040863
	];
	
	function _address_init(address tps) public {
		tokenTPS = tps;
		uint amount = 1000000000000000000000000000;
		uint amountTlb = 5000000000;
		
		_mint(pnode, amount);
		ITlbMlm(tokenTPS)._test_mint(pnode, amountTlb);
		
		addAccount(pnode,admin);
		for(uint i=0; i<sh.length; i++) {
			_mint(sh[i], amount);
			ITlbMlm(tokenTPS)._test_mint(sh[i], amountTlb);
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
// 	function _address_m1() public {
// 	    addMiner(pnode,admin,0);
// 	    addBulkMiner(sh,pnode,1);
// 	}
// 	function _address_m2() public {
// 	    addMiner(g[0],sh[0],2);
// 	    addMiner(g[1],sh[0],3);
// 	}
	
	function addAccount(address account, address referal) public {
		uint amountUSDT = 1000 * 10 ** 18;
		_mint(account, amountUSDT);
		uint amountTlb = ITlbMlm(tokenTPS).amountForDeposit(amountUSDT);
		ITlbMlm(tokenTPS)._test_mint(account, amountTlb);
		_approve(account, tokenTPS, amountUSDT);
		ITlbMlm(tokenTPS)._test_deposit(account, referal, amountUSDT);
	}
	function addBulkAccount(address[] memory addrs, address referal) public {
		for(uint i=0; i<addrs.length; i++) addAccount(addrs[i], referal);
	}
	
// 	function addMiner(address account, address referal, uint minerTier) public {
// 		uint amount = ITlbMlm(tokenTPS)._test_MinerPrice(minerTier);
// 		_mint(account, amount);
// 		_approve(account, tokenTPS, amount);
// 		ITlbMlm(tokenTPS)._test_buyMiner(account, referal, minerTier);
// 	}
// 	function addBulkMiner(address[] memory addrs, address referal, uint minerTier) public {
// 		uint amount = ITlbMlm(tokenTPS)._test_MinerPrice(minerTier);
// 		for(uint i=0; i<addrs.length; i++) {
// 			_mint(addrs[i], amount);
// 			_approve(addrs[i], tokenTPS, amount);
// 			ITlbMlm(tokenTPS)._test_buyMiner(addrs[i], referal, minerTier);   
// 		}
// 	}
	
}