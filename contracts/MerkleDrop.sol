pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MerkleProof.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract TokenVault {
    address public owner;
    address public token;

    constructor(address _owner, address _token) public {
        owner = _owner;
        token = _token;
    }
     /**
     * @dev transfers token to 'whom' address with 'amount'.
     */
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
    
    /**
     *  airdropCreator - token airdropCreator
     * 'tokenAddress '  - token's contract address
     *  'amount' - amount of tokens to be airdropped
     *  'ipfsHash' - ipfsHash of the csv file
     *  'rootHash' -  merkle root hash
     *  'airdropDate' - airdrop creation date
     *  'airdropExpirationDate'- token's airdrop Exipration Date
     */
    struct MerkleAirDrop {
        address airdropCreator; 
        address tokenAddress; 
        string ipfsHash; 
        bytes32 rootHash; 
        uint256 amount; 
        uint256 airdropDate; 
        uint256 airdropExpirationDate;
       
    }
    
    //Events
    event AirDropSubmitted(
        address indexed _airdropCreator,
        address indexed _token,
        uint256 _amount,
        uint256 _airdropDate,
        uint256 _airdropExpirationDate
    );

    event Claimed(address indexed account, uint256 amount, uint256 timestamp);

    //Mapping
    mapping(address => MerkleAirDrop) internal airdroppedtokens;
    mapping(address => mapping(uint256 => bool)) internal claimedMap;
    mapping(bytes32 => address) internal vaultAddress;
    
}

contract MerkleDrop is MerkleDropStorage,SafeMath,Ownable {
    using MerkleProof for bytes32[];
    
    address public tokenAddress;
    
    uint256 public feeInToken;
    
    uint256 public feeInEth;
    
    address public walletAddress;
    
    constructor(address _token,uint256 _feeToken,uint256 _feeEth,address _walletAddress)public{
        tokenAddress = _token;
        feeInToken = _feeToken;
        feeInEth = _feeEth;
        walletAddress = _walletAddress;
    }
    
    //To perform safe transfer of token
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
    
    /**
     * @dev creates token airdrop.
     * 
     * @param
     * ' _token '  - token's contract address
     *  ' _amount' - amount of tokens to be airdropped
     *  '_ipfsHash' - ipfsHash of the csv file
     *  '_root' -  merkle root hash
     *  '_airdropExpirationDate'- token's airdrop Exipration Date
     *  '_paymentInToken' - pay in tokens
     */
    function createAirDrop(
        address _token, 
        uint256 _amount, 
        string memory _ipfsHash,
        bytes32 _root, 
        uint256 _airdropExpirationDate,
        bool _paymentInToken
    ) external payable returns (bool) {
        TokenVault vault = new TokenVault(address(this), _token);
        if(_paymentInToken){
            
            IERC20(tokenAddress).transferFrom(msg.sender,walletAddress,feeInToken);
         }
        else{
            (bool success,) = walletAddress.call{value:feeInEth}(new bytes(0));
             require(success,"ERR_TRANSFER_FAILED");
        }
        safeTransferFrom(_token, msg.sender, address(vault), _amount);
        MerkleAirDrop memory merkledrop = MerkleAirDrop(msg.sender,_token, _ipfsHash, _root,_amount,now,_airdropExpirationDate);
        airdroppedtokens[address(vault)] = merkledrop;
        vaultAddress[_root] = address(vault);
        emit AirDropSubmitted(msg.sender,_token,_amount,now,_airdropExpirationDate);
        return true;
    }

     //To get the merkle root hash of the airdropped token
    function getRoot(address _vault) internal view returns (bytes32) {
        MerkleAirDrop memory merkledrop = airdroppedtokens[_vault];
        return merkledrop.rootHash;
    }
    //To get the vault address of airdrop token
    function getAirDropValutAddress(bytes32 root)external view returns (address) {
        return vaultAddress[root];
    }
    
    //To get the airdropCreator
    function getAirDropCreator(address _vault) internal view returns (address) {
        MerkleAirDrop memory merkledrop = airdroppedtokens[_vault];
        return merkledrop.airdropCreator;
    }
    //To determine whether airdrop has expired or not
    function airdropHasExpired(address _vault) internal view returns (bool) {
        MerkleAirDrop memory merkledrop = airdroppedtokens[_vault];
        return (now > merkledrop.airdropExpirationDate);
    }
    
    //To set token fee 
    function setTokenFee(uint256 _fee)external onlyOwner(){
        feeInToken = _fee;
    }
    
    //To set eth fee
    function setEthFee(uint256 _fee)external onlyOwner(){
        feeInEth = _fee;
    }
    
    //To set fee in token
    function setWalletAddress(address _walletAddress)external onlyOwner(){
        walletAddress = _walletAddress;
    }
    
     /**
     * @dev to claim the airdropped tokens.
     * 
     *  @param
     * ' _vault'  - vault Address
     *  ' _proof' - merkle proof
     *  'index' - address index
     *  '_amount' -  amount of token to bec claimed
     */
    function claim(
        address[] memory _vault,
        bytes32[][] memory _proof,
        uint256[] memory index,
        uint256[] memory amount
    ) external returns (bool) {
        address _userAddress = msg.sender;
        for (uint256 i = 0; i < _vault.length; i++) {
                require(!airdropHasExpired(_vault[i]),"ERR_AIRDROP_HAS_EXPIRED");
                require(!claimedMap[_vault[i]][index[i]],"ERR_AIRDROP_ALREADY_CLAIMED");
                bytes32 root = getRoot(_vault[i]);
                bytes32 node = keccak256(abi.encodePacked(index[i], _userAddress, amount[i]));
                bytes32[] memory proof = _proof[i];
                if (MerkleProof.verify(proof, root, node)){
                    TokenVault(_vault[i]).transferToken(msg.sender,amount[i]);
                    claimedMap[_vault[i]][index[i]] = true;
                    emit Claimed(msg.sender, amount[i], now);
                }
        }
        return true;
    }

     /**
     * @dev to send the airdropped tokens back to AirDropper.
     * 
     *  @param
     * ' _vault'  - vault Address
     */
    function sendTokenBackToAirDropper(address _vault) external returns (bool) {
        address _creator = getAirDropCreator(_vault);
        require(_creator == msg.sender, "ERR_NOT_AUTHORIZED");
        require(airdropHasExpired(_vault), "ERR_TOKEN_AIRDROP_HASNOT_EXPIRED");
        TokenVault(_vault).transferToken(_creator,IERC20(TokenVault(_vault).token()).balanceOf(_vault));
        return true;
    }
    
    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }  
}

