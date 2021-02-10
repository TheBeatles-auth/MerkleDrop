pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MerkleProof.sol";
import "./IERC20.sol";

contract TokenVault {
    address public owner;
    address public token;

    constructor(address _owner, address _token) public {
        owner = _owner;
        token = _token;
    }

    function transferToken(address _whom, uint256 _amount)
        public
        returns (bool)
    {
        require(msg.sender == owner, "caller should be owner");
        safeTransfer(_whom, _amount);
        return true;
    }

    function safeTransfer(address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))),"TransferHelper: TRANSFER_FAILED" );
    }
}

abstract contract MerkleDropStorage {
    struct MerkleAirDrop {
        address airdropCreator;
        address tokenAddress;
        string ipfsHash;
        bytes32 rootHash;
        uint256 amount;
        uint256 airdropDate; // The airdrop creation date
        uint256 airdropExpirationDate; // When airdrop expires
    }
    event AirDropSubmitted(
        address indexed _airdropCreator,
        address indexed _token,
        uint256 _amount,
        uint256 _airdropDate,
        uint256 _airdropExpirationDate
    );

    event Claimed(address indexed account, uint256 amount, uint256 timestamp);

    mapping(address => MerkleAirDrop) internal airdroppedtokens;
    mapping(address => mapping(uint256 => bool)) internal claimedMap;

    address[] public vaultAddress;
}

contract MerkleDrop is MerkleDropStorage {
    using MerkleProof for bytes32[];

    function safeTransferFrom(
        address _token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))),"TransferHelper: TRANSFER_FROM_FAILED");
    }

    function createAirDrop(
        address _token, // token contract address
        uint256 _amount, // amount of tokens to be air dropped
        string memory _ipfsHash, // token ipfsHash
        bytes32 _root, //merkle root hash
        uint256 _airdropExpirationDate // token's airdrop Exipration Date
    ) external returns (bool) {
        TokenVault vault = new TokenVault(address(this), _token);
        safeTransferFrom(_token, msg.sender, address(vault), _amount);
        MerkleAirDrop memory ma = MerkleAirDrop(msg.sender,_token, _ipfsHash, _root,_amount,now,_airdropExpirationDate  );
        airdroppedtokens[address(vault)] = ma;
        vaultAddress.push(address(vault));
        emit AirDropSubmitted(msg.sender,_token,_amount,now,_airdropExpirationDate);
        return true;
    }

    function getRoot(address _vault) internal view returns (bytes32) {
        MerkleAirDrop memory ma = airdroppedtokens[_vault];
        return ma.rootHash;
    }

    function getAirDropCreator(address _vault) internal view returns (address) {
        MerkleAirDrop memory ma = airdroppedtokens[_vault];
        return ma.airdropCreator;
    }

    function airdropHasExpired(address _vault) internal view returns (bool) {
        MerkleAirDrop memory ma = airdroppedtokens[_vault];
        return (now > ma.airdropExpirationDate);
    }

    function claim(
        address[] memory _vault,
        bytes32[][] memory proof,
        uint256[] memory index,
        uint256[] memory amount
    ) external returns (bool) {
        uint256 totalAmount = 0;
        (address[] memory _vaultAddress, uint256[] memory _amountOfTokens) =
            getTokenAirDropsList(msg.sender, _vault, proof, index, amount);
        for (uint256 i = 0; i < _vaultAddress.length; i++) {
            if (_vaultAddress[i] != address(0) && _amountOfTokens[i] != 0) {
                TokenVault(_vaultAddress[i]).transferToken(msg.sender,_amountOfTokens[i]);
                totalAmount += _amountOfTokens[i];
                claimedMap[vaultAddress[i]][index[i]] = true;
            }
        }
        emit Claimed(msg.sender, totalAmount, now);
        return true;
    }

    function getTokenAirDropsList(
        address _userAddress,
        address[] memory _vault,
        bytes32[][] memory _proof,
        uint256[] memory index,
        uint256[] memory amount
    ) internal view returns (address[] memory, uint256[] memory) {
        address[] memory vaultAddress = new address[](_vault.length);
        uint256[] memory tokenAmount = new uint256[](amount.length);
        for (uint256 i = 0; i < _vault.length; i++) {
            if (!airdropHasExpired(_vault[i])) {
                bytes32 root = getRoot(_vault[i]);
                bytes32 node = keccak256(abi.encodePacked(index[i], _userAddress, amount[i]));
                bytes32[] memory proof = _proof[i];
                if (MerkleProof.verify(proof, root, node) && (!claimedMap[_vault[i]][index[i]])){
                    tokenAmount[i] = amount[i];
                    vaultAddress[i] = _vault[i];
                }
            }
        }
        return (vaultAddress, tokenAmount);
    }

    function sendTokenBackToAirDropper(address _vault) external returns (bool) {
        address _creator = getAirDropCreator(_vault);
        require(_creator == msg.sender, "ERR_NOT_AUTHORIZED");
        require(airdropHasExpired(_vault), "ERR_TOKEN_AIRDROP_HASNOT_EXPIRED");
        TokenVault(_vault).transferToken(_creator,IERC20(TokenVault(_vault).token()).balanceOf(_vault));
        return true;
    }
}
