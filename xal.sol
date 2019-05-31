/**
 * This smart contract code is Copyright 2019 Auxledger Network. For more information see https://auxledger.org
 *
 */

pragma solidity ^0.4.25;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract  ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address addr_) external constant returns (uint256 bal);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address from_, address to_, uint256 _value) public returns (bool);
    function approve(address spender_, uint256 value_) public returns (bool);
    function allowance(address _owner, address _spender) public view returns  (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 */
contract XALToken is ERC20 {

    using SafeMath for uint256;

    struct Lockup {
        uint256 value_;
        uint256 releaseTime;
    }


    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal totalSupply_;

    
    mapping(address => uint256) private balanceof_;
    mapping(address => mapping(address => uint256)) private allowance_;
    mapping(address => Lockup) LockupInfo;
    mapping(address => bool) internal lockedAddress;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Unlock(address indexed holder, uint256 value);
    event Lock(address indexed holder, uint256 value);
    event Burn(address indexed owner, uint256 value);

    modifier onlyOwner {
      require(msg.sender == owner) ;
      _;
    }

    constructor() public{
        owner = msg.sender;
        name = "XAL Token";
        symbol = "XAL";
        totalSupply_ = 100000000;
        decimals = 18;
        balanceof_[msg.sender] = totalSupply_;
    }
   
  /**
  * @dev totalSupply provides the total token minted till date.
  * @return An uint256 specyfing the total suppy tokens.
  */ 
    function totalSupply() public view returns (uint256){
        return totalSupply_;    
    }
    

  /**
  * @dev Gets the balance of the specified address.
  * @param addr_ The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
    function balanceOf(address addr_) external constant returns(uint256 bal){
       return balanceof_[addr_];        
    }
    

/**
  * @dev transfer token for a specified address
  * @param to_ The address to transfer to.
  * @param value_ The amount to be transferred.
  */
  
    function transfer(address to_, uint256 value_) public returns (bool){
        require(value_ <= balanceof_[msg.sender]);
        require(to_ != address(0));
        // SafeMath.sub will throw if there is not enough balance.

        balanceof_[msg.sender] = balanceof_[msg.sender].sub(value_);
        balanceof_[to_] = balanceof_[to_].add(value_);
        emit Transfer(msg.sender, to_, value_);
        return true;
        
    }

  /**
   * @dev Transfer tokens from one address to another
   * @param from_ address The address which you want to send tokens from
   * @param to_ address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
    function transferFrom(address from_, address to_, uint256 _value) public returns (bool) {
        require(to_ != address(0));
        require(_value <= balanceof_[from_]);
        require(_value <= allowance_[from_][msg.sender]);

        balanceof_[from_] = balanceof_[from_].sub(_value);
        balanceof_[to_] = balanceof_[to_].add(_value);
        allowance_[from_][msg.sender] = allowance_[from_][msg.sender].sub(_value);
        emit Transfer(from_, to_, _value);
        return true;
    }

   /**
   * @dev approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param spender_ The address which will spend the funds.
   * @param value_ The amount of tokens to be spent.
    */   
    function approve(address spender_, uint256 value_) public returns (bool){        
        require(spender_ != address(0));

        bool status = false;

        if(balanceof_[msg.sender] >= value_){
            allowance_[msg.sender][spender_] = value_;
            emit Approval(msg.sender, spender_, value_);
            status = true;
        }

        return status;
    }
    

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender) public view returns  (uint256 remaining) {
        return allowance_[_owner][_spender];
        
    }
    

  /**
   * @dev Function to lock particular amount of token to and address from certain time period.
   * @param _holder address whose token is to be locked
   * @param value_ uint256 the amount which need to be locked.
   * @param releaseTime uint256 time period in Epoch till which funds will be locked.
   * @return bool specyfing wether operation executed sucessfully.
   */
    function lockXal(address _holder,uint256 value_, uint256 releaseTime) public onlyOwner returns (bool) {

        require (lockedAddress[_holder] == false);
        require(releaseTime > now);
        require(value_ > 0);
        require(balanceof_[_holder] > value_);
        
        balanceof_[_holder] = balanceof_[_holder].sub(value_);
        LockupInfo[_holder] = Lockup(value_, releaseTime); 
        
        lockedAddress[_holder] = true;

        emit Lock(_holder, value_);

        return true;
      
    }
    
  /**
   * @dev Function to release token that was locked to the holder address.
   * @param _holder address funds need to be released.
   * @return bool specyfing wether operation executed sucessfully.
   */
    function unlockXal(address _holder) public onlyOwner returns (bool){

        require (lockedAddress[_holder] == true);
        
        uint256 releaseTime =  LockupInfo[_holder].releaseTime;
    
        require (releaseTime < now);
         
        balanceof_[_holder] = balanceof_[_holder].add(LockupInfo[_holder].value_);
        
        delete LockupInfo[_holder];
        lockedAddress[_holder] = false;

        emit Unlock(_holder, LockupInfo[_holder].value_);


        return true;
    }
    

/**
*    @dev Function to provide the locking information
*    @param _lockedAddress is the locked address whose loking information is to be find out
*    @return bool : if funds of particular address was locked
*    @return uint256 is the locked token
*    @return uint256 is the release time of tokens locked in particular address
*/
    function getLockInfo(address _lockedAddress) public view returns (bool, uint256, uint256){
        return (lockedAddress[_lockedAddress],LockupInfo[_lockedAddress].value_, LockupInfo[_lockedAddress].releaseTime);
    }
    

/**
*    @dev Function provide current timestamp
*    @return uint256 is the current epoch timestamp
*/ 
    function currentTime() public view returns(uint256) {
         return now;
    }


/**
*    @dev Function burns the token
*    @param _value uint256 is the total token to be burnt
*    @return bool specyfing if operation executed sucessfully
*/ 
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(_value <= balanceof_[msg.sender]);
        address burner = msg.sender;
        balanceof_[burner] = balanceof_[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        return true;
    }    

}