pragma solidity ^0.6.0;

import "./Math.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract MerkleDropStorage is Ownable{
    
    using Math for uint256;
     
    struct TokenAirdrop{
        mapping(address => uint256) addressAndAmount;
        uint airdropDate; // The airdrop creation date
        uint airdropExpirationDate; // When airdrop expires
        uint totalWalletAddress;
    }
    
    mapping (address => TokenAirdrop) public airdroppedTokens;
    
    mapping (address => mapping(address => bool))internal tokenToWalletExists;
    
    uint airDropCount = 0;
    address[] airdropTokenAddresses;
    
    event AirDropSubmitted(
        address indexed _airDroper,
        uint256 indexed _airdropdate,
        uint256 indexed _airdropExpirationDate
    ); 
}

contract Airdrop is Ownable,MerkleDropStorage{
  
    function airdropTokens(address _tokenAddress, address[] memory _walletAddress,uint256[] memory _amountOfTokens,uint256 _airdropExpiration)external {
        
        require(_tokenAddress != address(0),"ERR_TOKEN_ADDRESS_TO_BE_DROPPED_CANNOT_BE_ZERO");
        
        require(_walletAddress.length == _amountOfTokens.length,"ERR_NO_OF_WALLET_ADDRESS_AND_TOKENS_MISMATCH");
        
        uint256 totalTokenAmount = getTotalTokenTrasferAmount(_amountOfTokens);
        
        require(IERC20(_tokenAddress).balanceOf(msg.sender) >= totalTokenAmount,"ERR_TRASFER_BALANCE_EXCEEDS");
         
        airdroppedTokens[_tokenAddress] = TokenAirdrop(now,now.add(_airdropExpiration),_walletAddress.length);
        TokenAirdrop storage ta = airdroppedTokens[_tokenAddress];
        for(uint256 i = 0; i< _walletAddress.length; i++){
            
            require(_walletAddress[i] != address(0),"ERR_WALLET_ADDRESS_CANNOT_BE_ZERO");
            ta.addressAndAmount[_walletAddress[i]] = _amountOfTokens[i];
            tokenToWalletExists[_tokenAddress][_walletAddress[i]] = true;
         }
        airdropTokenAddresses.push(_tokenAddress);
        airDropCount++;
        IERC20(_tokenAddress).transferFrom(msg.sender,address(this),totalTokenAmount);
        emit AirDropSubmitted(msg.sender,now,_airdropExpiration);
     }
    
    function getTotalTokenTrasferAmount(uint256[]memory _amtoftokens)internal pure returns(uint256){
        
        uint256 total;
        for(uint256 i = 0; i <_amtoftokens.length;i++){
           total = total.add(_amtoftokens[i]); 
        }
        return total;
    }
    
     function getTokenAirDropsAvailableToUser()public view returns(address[]memory,uint256[]memory){
        TokenAirdrop storage ta ; 
        address _walletAddress = msg.sender;
        uint256 no_of_tokens = getUserTokenCount(_walletAddress);
        address[] memory tokenAddress = new address[](no_of_tokens);
        uint256[] memory tokenAmount = new uint256[](no_of_tokens);
        
        for(uint256 i = 0; i< airdropTokenAddresses.length;i++)
        {
               ta = airdroppedTokens[airdropTokenAddresses[i]];
               tokenAmount[i] = (ta.addressAndAmount[_walletAddress]);
               tokenAddress[i] = (airdropTokenAddresses[i]) ;
        }
        return(tokenAddress,tokenAmount);
     }
     
     function getUserTokenCount(address _walletAddress)internal view returns(uint256){
       uint256 count = 0;
          for(uint256 i = 0; i< airDropCount;i++)
         {
              if(walletExists(airdropTokenAddresses[i],_walletAddress))
               {
                    if(!airdropHasExpired(airdropTokenAddresses[i]))
                    {
                        ++count;
                    }
               }
         }
         return(count);
     }
     
     function airdropHasExpired(address _tokenAddress) public view returns (bool){
        TokenAirdrop storage ta = airdroppedTokens[_tokenAddress];
        return (now > ta.airdropExpirationDate);
    }
    
    function walletExists(address _tokenAddress,address _walletAddress)internal view returns(bool){
        return tokenToWalletExists[_tokenAddress][_walletAddress];
    }
    
    function claim(address _user)external{
        (address[]memory _tokenAddress,uint256[]memory _amountOfTokens)=getTokenAirDropsAvailableToUser();
        for(uint256 i = 0;i<_tokenAddress.length;i++){
            IERC20(_tokenAddress[i]).transferFrom(address(this),_user,_amountOfTokens[i]);
        }
     }
}
