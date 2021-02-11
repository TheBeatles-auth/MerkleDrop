const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");

const truffleAssert = require("truffle-assertions");
const { assert, expect } = require("chai");
const MerkleDrop = artifacts.require("MerkleDrop");
const TokenBasic = artifacts.require("Tokenbasic");
const TokenBasic1 = artifacts.require("Tokenbasic");

require("chai").use(require("chai-bignumber")(BN)).should();

contract("MerkleDrop", () => {
  it("Should deploy smart contract properly", async () => {
    const token = await TokenBasic.deployed();
    const token1 = await TokenBasic1.deployed();
    const merkle = await MerkleDrop.deployed();

    assert(token.address !== "");
    assert(merkle.address !== "");
  });
  beforeEach(async function () {
    merkle = await MerkleDrop.new();
    token = await TokenBasic.new();
    await token.approve(merkle.address, 200);
    token1 = await TokenBasic1.new();
    await token1.approve(merkle.address, 200);
    accounts = await web3.eth.getAccounts();
  });

  describe("[Testcase 1: To create AirDrop]", () => {
    it("Create AirDrop", async () => {
      await merkle.createAirDrop(
        token.address,
        160,
        "0xhash",
        "0xd44fec381892e6c49b756000d0ea0745eb3eceb4e380095d41ea5755e3bcf97a",
        1612960888,
        {
          from: accounts[0],
        }
      );
    });
  });

  describe("[Testcase 2: To claim air drop tokens]", () => {
    it("Claim AirDrop", async () => {
      await merkle.createAirDrop(
        token.address,
        160,
        "0xhash",
        "0xd44fec381892e6c49b756000d0ea0745eb3eceb4e380095d41ea5755e3bcf97a",
        1614297578,
        {
          from: accounts[0],
        }
      );
      await merkle.createAirDrop(
        token1.address,
        160,
        "0xhash",
        "0x5f726e8b1ef32651e49545967f8b01a458b58e85e7d66b52e299c735c7d43b85",
        1614297578,
        {
          from: accounts[0],
        }
      );
      var vaultAddress = [
        await merkle.getAirDropValutAddress("0xd44fec381892e6c49b756000d0ea0745eb3eceb4e380095d41ea5755e3bcf97a"),
        await merkle.getAirDropValutAddress("0x5f726e8b1ef32651e49545967f8b01a458b58e85e7d66b52e299c735c7d43b85"),
      ];
      var proof = [
        ["0x2a7335270534e59e7706f81b43e93be7137d9609329d150b02332ba4f2bd7aea"],
        [
          "0x05be6624b7ab704d6c2721daf97766e6e0f06310b1c096d4b7151e6dff2e60e6",
          "0x2a7335270534e59e7706f81b43e93be7137d9609329d150b02332ba4f2bd7aea",
        ],
      ];
      var amount = ["50", "50"];
      var index = ["1", "1"];
      assert.isTrue(
        await merkle.claim.call(vaultAddress, proof, index, amount, {
          from: accounts[2],
        })
      );
    });
  });

  describe("[Testcase 3: To try to claim expired airDrop tokens]", () => {
    it("Claim AirDrop", async () => {
      await merkle.createAirDrop(
        token.address,
        160,
        "0xhash",
        "0xd44fec381892e6c49b756000d0ea0745eb3eceb4e380095d41ea5755e3bcf97a",
        1612960888,
        {
          from: accounts[0],
        }
      );
      await merkle.createAirDrop(
        token1.address,
        160,
        "0xhash",
        "0x5f726e8b1ef32651e49545967f8b01a458b58e85e7d66b52e299c735c7d43b85",
        1612960888,
        {
          from: accounts[0],
        }
      );
      var vaultAddress = [
        await merkle.getAirDropValutAddress("0xd44fec381892e6c49b756000d0ea0745eb3eceb4e380095d41ea5755e3bcf97a"),
        await merkle.getAirDropValutAddress("0x5f726e8b1ef32651e49545967f8b01a458b58e85e7d66b52e299c735c7d43b85")
      ];
      var proof = [
        ["0x2a7335270534e59e7706f81b43e93be7137d9609329d150b02332ba4f2bd7aea"],
        [
          "0x05be6624b7ab704d6c2721daf97766e6e0f06310b1c096d4b7151e6dff2e60e6",
          "0x2a7335270534e59e7706f81b43e93be7137d9609329d150b02332ba4f2bd7aea",
        ],
      ];
      var amount = ["50", "50"];
      var index = ["1", "1"];
      try{
        await merkle.claim(vaultAddress, proof, index, amount, {
          from: accounts[2],
        });
      }
      catch(error){

      }
    });
  });

  describe("[Testcase 4: To send back expired airDrops to the AirDropper]", () => {
    it("Send token to AirDropper", async () => {
      await merkle.createAirDrop(
        token1.address,
        160,
        "0xhash",
        "0x5f726e8b1ef32651e49545967f8b01a458b58e85e7d66b52e299c735c7d43b85",
        1612944105,
        {
          from: accounts[0],
        }
      );
      var vaultAddress = await merkle.getAirDropValutAddress("0x5f726e8b1ef32651e49545967f8b01a458b58e85e7d66b52e299c735c7d43b85");
      await merkle.sendTokenBackToAirDropper(vaultAddress, {
        from: accounts[0],
      });
    });
  });

  describe("[Testcase 5: To send back non-expired airDrops to the AirDropperr]", () => {
    it("Send token to AirDropper", async () => {
      await merkle.createAirDrop(
        token.address,
        160,
        "0xhash",
        "0xd44fec381892e6c49b756000d0ea0745eb3eceb4e380095d41ea5755e3bcf97a",
        1614297578,
        {
          from: accounts[0],
        }
      );
      var vaultAddress = await merkle.getAirDropValutAddress("0xd44fec381892e6c49b756000d0ea0745eb3eceb4e380095d41ea5755e3bcf97a");
      try {
        await merkle.sendTokenBackToAirDropper(vaultAddress, {
          from: accounts[0],
        });
      } catch (error) {}
      var actual = await token.balanceOf(await merkle.getAirDropValutAddress("0xd44fec381892e6c49b756000d0ea0745eb3eceb4e380095d41ea5755e3bcf97a"));
      var expected = "160";
      assert.equal(actual, expected);
    });
  });

  describe("[Testcase 6: To try to send back airDrops who is not the AirDropper]", () => {
    it("Send token to AirDropper", async () => {
      await merkle.createAirDrop(
        token1.address,
        160,
        "0xhash",
        "0x5f726e8b1ef32651e49545967f8b01a458b58e85e7d66b52e299c735c7d43b85",
        1612965471,
        {
          from: accounts[0],
        }
      );
      var vaultAddress = await merkle.getAirDropValutAddress("0xd44fec381892e6c49b756000d0ea0745eb3eceb4e380095d41ea5755e3bcf97a");
      try {
        await merkle.sendTokenBackToAirDropper(vaultAddress, {
          from: accounts[3],
        });
      } catch (error) {}
    });
  });
});
