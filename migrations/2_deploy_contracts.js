var MerkleDrop = artifacts.require("MerkleDrop.sol");
var TokenBasic = artifacts.require("TokenBasic.sol");
var TokenBasic1 = artifacts.require("TokenBasic.sol");
var Lock = artifacts.require("Lock.sol");

module.exports = async function(deployer)
{
	 await deployer.deploy(TokenBasic);
	 await deployer.deploy(TokenBasic1);
	 await deployer.deploy(Lock);
	 await deployer.deploy(MerkleDrop,Lock.address,web3.utils.toWei("0.05","ether"),web3.utils.toWei("0.05","ether"),'0x31de0c08f72fe94aadfa9adbfabb5b23238b9ce1');
};	
