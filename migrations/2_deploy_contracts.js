var MerkleDrop = artifacts.require("MerkleDrop.sol");
var TokenBasic = artifacts.require("TokenBasic.sol");
var TokenBasic1 = artifacts.require("TokenBasic.sol");

module.exports = async function(deployer)
{
	 await deployer.deploy(TokenBasic);
	 await deployer.deploy(TokenBasic1);
	 await deployer.deploy(MerkleDrop);
};	