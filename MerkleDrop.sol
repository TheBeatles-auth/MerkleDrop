pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract TokenVault {
    address internal owner ;
    address internal token ;
    
    constructor(address _owner,address _token)public {
        owner = _owner; 
        token = _token;
    }  
 }
 
 abstract contract MerkleDropStorage{
   
     struct MerkleAirDrop{
         address tokenAddress;
         string ipfsHash;
         bytes roohHash;
         uint amount;
         uint airdropDate; // The airdrop creation date
         uint airdropExpirationDate; // When airdrop expires
     }
      event AirDropSubmitted(
       address indexed _token,
       uint256  _amount,
       uint256  _airdropDate,
       uint256 _airdropExpirationDate
     );
     
    mapping(address => MerkleAirDrop)internal airdroppedtokens;
   
 }
   contract MerkleDrop  is MerkleDropStorage {
       using SafeERC20 for IERC20;
       
       function createAirDrop(
        address _token,      // token contract address
        uint256 _amount,     // amount of tokens to be air dropped
        string memory _ipfsHash,      // token ipfsHash
        bytes memory _root,          //merkle root hash
        uint256 _airdropExpirationDate  // token's airdrop Exipration Date
            
    ) external payable returns(bool) {
        
        TokenVault valut = new TokenVault(address(this),_token);
        IERC20(_token).safeTransferFrom( msg.sender,address(this), _amount);
        MerkleAirDrop memory ma = MerkleAirDrop(_token,_ipfsHash,_root,_amount,now,_airdropExpirationDate);
        airdroppedtokens[_token] = ma;
        emit AirDropSubmitted(_token,_amount,now,_airdropExpirationDate);
        return true;
    }
    
    function getRoot(address _token) external  view returns(bytes memory) {
       MerkleAirDrop memory ma = airdroppedtokens[_token];
       return ma.roohHash;
     
   }
    function airdropHasExpired(address _tokenAddress) public view returns (bool){
        MerkleAirDrop memory ma = airdroppedtokens[_tokenAddress];
        return (now > ma.airdropExpirationDate);
    }
  }
