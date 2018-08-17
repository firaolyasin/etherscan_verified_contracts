pragma solidity ^0.4.15;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c &gt;= a);
    return c;
  }
}




/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address =&gt; uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}





/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address =&gt; mapping (address =&gt; uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value &lt;= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}




/**
 * @title Manageable
 * @dev Contract that allows to grant permissions to any address
 * @dev In real life we are no able to perform all actions with just one Ethereum address
 * @dev because risks are too high.
 * @dev Instead owner delegates rights to manage an contract to the different addresses and
 * @dev stay able to revoke permissions at any time.
 */
contract Manageable is Ownable {

  /* Storage */

  mapping (address =&gt; bool) managerEnabled;  // hard switch for a manager - on/off
  mapping (address =&gt; mapping (string =&gt; bool)) managerPermissions;  // detailed info about manager`s permissions


  /* Events */

  event ManagerEnabledEvent(address indexed manager);
  event ManagerDisabledEvent(address indexed manager);
  event ManagerPermissionGrantedEvent(address indexed manager, string permission);
  event ManagerPermissionRevokedEvent(address indexed manager, string permission);


  /* Configure contract */

  /**
   * @dev Function to add new manager
   * @param _manager address New manager
   */
  function enableManager(address _manager) onlyOwner onlyValidAddress(_manager) {
    require(managerEnabled[_manager] == false);

    managerEnabled[_manager] = true;
    ManagerEnabledEvent(_manager);
  }

  /**
   * @dev Function to remove existing manager
   * @param _manager address Existing manager
   */
  function disableManager(address _manager) onlyOwner onlyValidAddress(_manager) {
    require(managerEnabled[_manager] == true);

    managerEnabled[_manager] = false;
    ManagerDisabledEvent(_manager);
  }

  /**
   * @dev Function to grant new permission to the manager
   * @param _manager        address Existing manager
   * @param _permissionName string  Granted permission name
   */
  function grantManagerPermission(
    address _manager, string _permissionName
  )
    onlyOwner
    onlyValidAddress(_manager)
    onlyValidPermissionName(_permissionName)
  {
    require(managerPermissions[_manager][_permissionName] == false);

    managerPermissions[_manager][_permissionName] = true;
    ManagerPermissionGrantedEvent(_manager, _permissionName);
  }

  /**
   * @dev Function to revoke permission of the manager
   * @param _manager        address Existing manager
   * @param _permissionName string  Revoked permission name
   */
  function revokeManagerPermission(
    address _manager, string _permissionName
  )
    onlyOwner
    onlyValidAddress(_manager)
    onlyValidPermissionName(_permissionName)
  {
    require(managerPermissions[_manager][_permissionName] == true);

    managerPermissions[_manager][_permissionName] = false;
    ManagerPermissionRevokedEvent(_manager, _permissionName);
  }


  /* Getters */

  /**
   * @dev Function to check manager status
   * @param _manager address Manager`s address
   * @return True if manager is enabled
   */
  function isManagerEnabled(address _manager) constant onlyValidAddress(_manager) returns (bool) {
    return managerEnabled[_manager];
  }

  /**
   * @dev Function to check permissions of a manager
   * @param _manager        address Manager`s address
   * @param _permissionName string  Permission name
   * @return True if manager has been granted needed permission
   */
  function isPermissionGranted(
    address _manager, string _permissionName
  )
    constant
    onlyValidAddress(_manager)
    onlyValidPermissionName(_permissionName)
    returns (bool)
  {
    return managerPermissions[_manager][_permissionName];
  }

  /**
   * @dev Function to check if the manager can perform the action or not
   * @param _manager        address Manager`s address
   * @param _permissionName string  Permission name
   * @return True if manager is enabled and has been granted needed permission
   */
  function isManagerAllowed(
    address _manager, string _permissionName
  )
    constant
    onlyValidAddress(_manager)
    onlyValidPermissionName(_permissionName)
    returns (bool)
  {
    return (managerEnabled[_manager] &amp;&amp; managerPermissions[_manager][_permissionName]);
  }


  /* Helpers */

  /**
   * @dev Modifier to check manager address
   */
  modifier onlyValidAddress(address _manager) {
    require(_manager != address(0x0));
    _;
  }

  /**
   * @dev Modifier to check name of manager permission
   */
  modifier onlyValidPermissionName(string _permissionName) {
    require(bytes(_permissionName).length != 0);
    _;
  }


  /* Outcome */

  /**
   * @dev Modifier to use in derived contracts
   */
  modifier onlyAllowedManager(string _permissionName) {
    require(isManagerAllowed(msg.sender, _permissionName) == true);
    _;
  }
}




/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * @dev Based on zeppelin&#39;s Pausable, but integrated with Manageable
 * @dev Contract is in paused state by default and should be explicitly unlocked
 */
contract Pausable is Manageable {

  /**
   * Events
   */

  event PauseEvent();
  event UnpauseEvent();


  /**
   * Storage
   */

  bool paused = true;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenContractNotPaused() {
    require(paused == false);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenContractPaused {
    require(paused == true);
    _;
  }

  /**
   * @dev called by the manager to pause, triggers stopped state
   */
  function pauseContract() onlyAllowedManager(&#39;pause_contract&#39;) whenContractNotPaused {
    paused = true;
    PauseEvent();
  }

  /**
   * @dev called by the manager to unpause, returns to normal state
   */
  function unpauseContract() onlyAllowedManager(&#39;unpause_contract&#39;) whenContractPaused {
    paused = false;
    UnpauseEvent();
  }

  /**
   * @dev The getter for &quot;paused&quot; contract variable
   */
  function getPaused() constant returns (bool) {
    return paused;
  }
}




/**
 * @title NamedToken
 */
contract NamedToken {
  string public name;
  string public symbol;
  uint32 public decimals;

  function NamedToken(string _name, string _symbol, uint32 _decimals) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  /**
   * @dev Function to calculate hash of the token`s name.
   * @dev Function needed because we can not just return name of the token to another contract - strings have variable length
   * @return Hash of the token`s name
   */
  function getNameHash() constant returns (bytes32 result){
    return sha3(name);
  }

  /**
   * @dev Function to calculate hash of the token`s symbol.
   * @dev Function needed because we can not just return symbol of the token to another contract - strings have variable length
   * @return Hash of the token`s symbol
   */
  function getSymbolHash() constant returns (bytes32 result){
    return sha3(symbol);
  }
}




/**
 * @title AngelToken
 */
contract AngelToken is StandardToken, NamedToken, Pausable {

  /* Events */

  event MintEvent(address indexed account, uint value);
  event BurnEvent(address indexed account, uint value);
  event SpendingBlockedEvent(address indexed account);
  event SpendingUnblockedEvent(address indexed account);


  /* Storage */

  address public centralBankAddress;
  mapping (address =&gt; uint) spendingBlocksNumber;


  /* Constructor */

  function AngelToken() NamedToken(&#39;ANGEL&#39;, &#39;ANG&#39;, 8) {
    centralBankAddress = msg.sender;
  }


  /* Methods */

  function transfer(address _to, uint _value) returns (bool) {
    if (_to != centralBankAddress) {
      require(!paused);
    }
    require(spendingBlocksNumber[msg.sender] == 0);

    bool result = super.transfer(_to, _value);
    if (result == true &amp;&amp; _to == centralBankAddress) {
      AngelCentralBank(centralBankAddress).angelBurn(msg.sender, _value);
    }
    return result;
  }

  function approve(address _spender, uint _value) whenContractNotPaused returns (bool){
    return super.approve(_spender, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenContractNotPaused returns (bool){
    require(spendingBlocksNumber[_from] == 0);

    bool result = super.transferFrom(_from, _to, _value);
    if (result == true &amp;&amp; _to == centralBankAddress) {
      AngelCentralBank(centralBankAddress).angelBurn(_from, _value);
    }
    return result;
  }


  function mint(address _account, uint _value) onlyAllowedManager(&#39;mint_tokens&#39;) {
    balances[_account] = balances[_account].add(_value);
    totalSupply = totalSupply.add(_value);
    MintEvent(_account, _value);
    Transfer(0x0, _account, _value); // required for blockexplorers
  }

  function burn(uint _value) onlyAllowedManager(&#39;burn_tokens&#39;) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    BurnEvent(msg.sender, _value);
  }

  function blockSpending(address _account) onlyAllowedManager(&#39;block_spending&#39;) {
    spendingBlocksNumber[_account] = spendingBlocksNumber[_account].add(1);
    SpendingBlockedEvent(_account);
  }

  function unblockSpending(address _account) onlyAllowedManager(&#39;unblock_spending&#39;) {
    spendingBlocksNumber[_account] = spendingBlocksNumber[_account].sub(1);
    SpendingUnblockedEvent(_account);
  }
}






/**
 * @title AngelCentralBank
 *
 * @dev Crowdsale and escrow contract
 */
contract AngelCentralBank {

  /* Data structures */

  struct InvestmentRecord {
    uint tokensSoldBeforeWei;
    uint investedEthWei;
    uint purchasedTokensWei;
    uint refundedEthWei;
    uint returnedTokensWei;
  }


  /* Storage - config */

  uint public icoCap = 70000000 * (10 ** 18);

  uint public initialTokenPrice = 1 * (10 ** 18) / (10 ** 4); // means 0.0001 ETH for one token

  uint public landmarkSize = 1000000 * (10 ** 18);
  uint public landmarkPriceStepNumerator = 10;
  uint public landmarkPriceStepDenominator = 100;

  uint public firstRefundRoundRateNumerator = 80;
  uint public firstRefundRoundRateDenominator = 100;
  uint public secondRefundRoundRateNumerator = 40;
  uint public secondRefundRoundRateDenominator = 100;

  uint public initialFundsReleaseNumerator = 20; // part of investment
  uint public initialFundsReleaseDenominator = 100;
  uint public afterFirstRefundRoundFundsReleaseNumerator = 50; // part of remaining funds
  uint public afterFirstRefundRoundFundsReleaseDenominator = 100;

  uint public angelFoundationShareNumerator = 30;
  uint public angelFoundationShareDenominator = 100;

  /* Storage - state */

  address public angelAdminAddress;
  address public angelFoundationAddress = address(0x2b0556a6298eA3D35E90F1df32cc126b31F59770);
  uint public icoLaunchTimestamp = 1511784000;  // November 27th 12:00 GMT
  uint public icoFinishTimestamp = 1514376000;  // December 27th 12:00 GMT
  uint public firstRefundRoundFinishTimestamp = 1520424000;  // March 7th 2018 12:00 GMT
  uint public secondRefundRoundFinishTimestamp = 1524744000;  // April 26th 2018 12:00 GMT


  AngelToken public angelToken;

  mapping (address =&gt; InvestmentRecord[]) public investments; // investorAddress =&gt; list of investments
  mapping (address =&gt; bool) public investors;
  uint public totalInvestors = 0;
  uint public totalTokensSold = 0;

  bool angelTokenUnpaused = false;
  bool firstRefundRoundFundsWithdrawal = false;


  /* Events */

  event InvestmentEvent(address indexed investor, uint eth, uint angel);
  event RefundEvent(address indexed investor, uint eth, uint angel);


  /* Constructor and config */

  function AngelCentralBank() {
    angelAdminAddress = msg.sender;

    angelToken = new AngelToken();
    angelToken.enableManager(address(this));
    angelToken.grantManagerPermission(address(this), &#39;mint_tokens&#39;);
    angelToken.grantManagerPermission(address(this), &#39;burn_tokens&#39;);
    angelToken.grantManagerPermission(address(this), &#39;unpause_contract&#39;);
    angelToken.transferOwnership(angelFoundationAddress);
  }

  /* Investments */

  /**
   * @dev Fallback function receives ETH and sends tokens back
   */
  function () payable {
    angelRaise();
  }

  /**
   * @dev Process new ETH investment and sends tokens back
   */
  function angelRaise() internal {
    require(msg.value &gt;= 0);
    require(now &gt;= icoLaunchTimestamp &amp;&amp; now &lt; icoFinishTimestamp);

    // calculate amount of tokens for received ETH
    uint _purchasedTokensWei = 0;
    uint _notProcessedEthWei = 0;
    (_purchasedTokensWei, _notProcessedEthWei) = calculatePurchasedTokens(totalTokensSold, msg.value);

    // create record for the investment
    uint _newRecordIndex = investments[msg.sender].length;
    investments[msg.sender].length += 1;
    investments[msg.sender][_newRecordIndex].tokensSoldBeforeWei = totalTokensSold;
    investments[msg.sender][_newRecordIndex].investedEthWei = msg.value;
    investments[msg.sender][_newRecordIndex].purchasedTokensWei = _purchasedTokensWei;
    investments[msg.sender][_newRecordIndex].refundedEthWei = 0;
    investments[msg.sender][_newRecordIndex].returnedTokensWei = 0;

    // calculate stats
    if (investors[msg.sender] == false) {
      totalInvestors += 1;
    }
    investors[msg.sender] = true;
    totalTokensSold += _purchasedTokensWei;

    // transfer tokens and ETH
    angelToken.mint(msg.sender, _purchasedTokensWei);
    angelToken.mint(angelFoundationAddress,
                    _purchasedTokensWei * angelFoundationShareNumerator / (angelFoundationShareDenominator - angelFoundationShareNumerator));
    angelFoundationAddress.transfer(msg.value * initialFundsReleaseNumerator / initialFundsReleaseDenominator);
    if (_notProcessedEthWei &gt; 0) {
      msg.sender.transfer(_notProcessedEthWei);
    }

    // finish ICO if cap reached
    if (totalTokensSold &gt;= icoCap) {
      icoFinishTimestamp = now;

      unpauseAngelToken();
    }

    // fire event
    InvestmentEvent(msg.sender, msg.value, _purchasedTokensWei);
  }

  /**
   * @dev Calculate amount of tokens for received ETH
   * @param _totalTokensSoldBefore uint Amount of tokens sold before this investment [token wei]
   * @param _investedEthWei        uint Investment amount [ETH wei]
   * @return Purchased amount of tokens [token wei]
   */
  function calculatePurchasedTokens(
    uint _totalTokensSoldBefore,
    uint _investedEthWei)
    constant returns (uint _purchasedTokensWei, uint _notProcessedEthWei)
  {
    _purchasedTokensWei = 0;
    _notProcessedEthWei = _investedEthWei;

    uint _landmarkPrice;
    uint _maxLandmarkTokensWei;
    uint _maxLandmarkEthWei;
    bool _isCapReached = false;
    do {
      // get landmark values
      _landmarkPrice = calculateLandmarkPrice(_totalTokensSoldBefore + _purchasedTokensWei);
      _maxLandmarkTokensWei = landmarkSize - ((_totalTokensSoldBefore + _purchasedTokensWei) % landmarkSize);
      if (_totalTokensSoldBefore + _purchasedTokensWei + _maxLandmarkTokensWei &gt;= icoCap) {
        _maxLandmarkTokensWei = icoCap - _totalTokensSoldBefore - _purchasedTokensWei;
        _isCapReached = true;
      }
      _maxLandmarkEthWei = _maxLandmarkTokensWei * _landmarkPrice / (10 ** 18);

      // check investment against landmark values
      if (_notProcessedEthWei &gt;= _maxLandmarkEthWei) {
        _purchasedTokensWei += _maxLandmarkTokensWei;
        _notProcessedEthWei -= _maxLandmarkEthWei;
      }
      else {
        _purchasedTokensWei += _notProcessedEthWei * (10 ** 18) / _landmarkPrice;
        _notProcessedEthWei = 0;
      }
    }
    while ((_notProcessedEthWei &gt; 0) &amp;&amp; (_isCapReached == false));

    assert(_purchasedTokensWei &gt; 0);

    return (_purchasedTokensWei, _notProcessedEthWei);
  }


  /* Refunds */

  function angelBurn(
    address _investor,
    uint _returnedTokensWei
  )
    returns (uint)
  {
    require(msg.sender == address(angelToken));
    require(now &gt;= icoLaunchTimestamp &amp;&amp; now &lt; secondRefundRoundFinishTimestamp);

    uint _notProcessedTokensWei = _returnedTokensWei;
    uint _refundedEthWei = 0;

    uint _allRecordsNumber = investments[_investor].length;
    uint _recordMaxReturnedTokensWei = 0;
    uint _recordTokensWeiToProcess = 0;
    uint _tokensSoldWei = 0;
    uint _recordRefundedEthWei = 0;
    uint _recordNotProcessedTokensWei = 0;
    for (uint _recordID = 0; _recordID &lt; _allRecordsNumber; _recordID += 1) {
      if (investments[_investor][_recordID].purchasedTokensWei &lt;= investments[_investor][_recordID].returnedTokensWei ||
          investments[_investor][_recordID].investedEthWei &lt;= investments[_investor][_recordID].refundedEthWei) {
        // tokens already refunded
        continue;
      }

      // calculate amount of tokens to refund with this record
      _recordMaxReturnedTokensWei = investments[_investor][_recordID].purchasedTokensWei -
                                    investments[_investor][_recordID].returnedTokensWei;
      _recordTokensWeiToProcess = (_notProcessedTokensWei &lt; _recordMaxReturnedTokensWei) ? _notProcessedTokensWei :
                                                                                           _recordMaxReturnedTokensWei;
      assert(_recordTokensWeiToProcess &gt; 0);

      // calculate amount of ETH to send back
      _tokensSoldWei = investments[_investor][_recordID].tokensSoldBeforeWei + investments[_investor][_recordID].returnedTokensWei;
      (_recordRefundedEthWei, _recordNotProcessedTokensWei) = calculateRefundedEth(_tokensSoldWei, _recordTokensWeiToProcess);
      if (_recordRefundedEthWei &gt; (investments[_investor][_recordID].investedEthWei - investments[_investor][_recordID].refundedEthWei)) {
        // this can happen due to rounding error
        _recordRefundedEthWei = (investments[_investor][_recordID].investedEthWei - investments[_investor][_recordID].refundedEthWei);
      }
      assert(_recordRefundedEthWei &gt; 0);
      assert(_recordNotProcessedTokensWei == 0);

      // persist changes to the storage
      _refundedEthWei += _recordRefundedEthWei;
      _notProcessedTokensWei -= _recordTokensWeiToProcess;

      investments[_investor][_recordID].refundedEthWei += _recordRefundedEthWei;
      investments[_investor][_recordID].returnedTokensWei += _recordTokensWeiToProcess;
      assert(investments[_investor][_recordID].refundedEthWei &lt;= investments[_investor][_recordID].investedEthWei);
      assert(investments[_investor][_recordID].returnedTokensWei &lt;= investments[_investor][_recordID].purchasedTokensWei);

      // stop if we already refunded all tokens
      if (_notProcessedTokensWei == 0) {
        break;
      }
    }

    // throw if we do not have tokens to refund
    require(_notProcessedTokensWei &lt; _returnedTokensWei);
    require(_refundedEthWei &gt; 0);

    // calculate refund discount
    uint _refundedEthWeiWithDiscount = calculateRefundedEthWithDiscount(_refundedEthWei);

    // transfer ETH and remaining tokens
    angelToken.burn(_returnedTokensWei - _notProcessedTokensWei);
    if (_notProcessedTokensWei &gt; 0) {
      angelToken.transfer(_investor, _notProcessedTokensWei);
    }
    _investor.transfer(_refundedEthWeiWithDiscount);

    // fire event
    RefundEvent(_investor, _refundedEthWeiWithDiscount, _returnedTokensWei - _notProcessedTokensWei);
  }

  /**
   * @dev Calculate discounted amount of ETH for refunded tokens
   * @param _refundedEthWei uint Calculated amount of ETH to refund [ETH wei]
   * @return Discounted amount of ETH for refunded [ETH wei]
   */
  function calculateRefundedEthWithDiscount(
    uint _refundedEthWei
  )
    constant returns (uint)
  {
    if (now &lt;= firstRefundRoundFinishTimestamp) {
      return (_refundedEthWei * firstRefundRoundRateNumerator / firstRefundRoundRateDenominator);
    }
    else {
      return (_refundedEthWei * secondRefundRoundRateNumerator / secondRefundRoundRateDenominator);
    }
  }

  /**
   * @dev Calculate amount of ETH for refunded tokens. Just abstract price ladder
   * @param _totalTokensSoldBefore     uint Amount of tokens that have been sold (starting point) [token wei]
   * @param _returnedTokensWei uint Amount of tokens to refund [token wei]
   * @return Refunded amount of ETH [ETH wei] (without discounts)
   */
  function calculateRefundedEth(
    uint _totalTokensSoldBefore,
    uint _returnedTokensWei
  )
    constant returns (uint _refundedEthWei, uint _notProcessedTokensWei)
  {
    _refundedEthWei = 0;
    uint _refundedTokensWei = 0;
    _notProcessedTokensWei = _returnedTokensWei;

    uint _landmarkPrice = 0;
    uint _maxLandmarkTokensWei = 0;
    uint _maxLandmarkEthWei = 0;
    bool _isCapReached = false;
    do {
      // get landmark values
      _landmarkPrice = calculateLandmarkPrice(_totalTokensSoldBefore + _refundedTokensWei);
      _maxLandmarkTokensWei = landmarkSize - ((_totalTokensSoldBefore + _refundedTokensWei) % landmarkSize);
      if (_totalTokensSoldBefore + _refundedTokensWei + _maxLandmarkTokensWei &gt;= icoCap) {
        _maxLandmarkTokensWei = icoCap - _totalTokensSoldBefore - _refundedTokensWei;
        _isCapReached = true;
      }
      _maxLandmarkEthWei = _maxLandmarkTokensWei * _landmarkPrice / (10 ** 18);

      // check investment against landmark values
      if (_notProcessedTokensWei &gt; _maxLandmarkTokensWei) {
        _refundedEthWei += _maxLandmarkEthWei;
        _refundedTokensWei += _maxLandmarkTokensWei;
        _notProcessedTokensWei -= _maxLandmarkTokensWei;
      }
      else {
        _refundedEthWei += _notProcessedTokensWei * _landmarkPrice / (10 ** 18);
        _refundedTokensWei += _notProcessedTokensWei;
        _notProcessedTokensWei = 0;
      }
    }
    while ((_notProcessedTokensWei &gt; 0) &amp;&amp; (_isCapReached == false));

    assert(_refundedEthWei &gt; 0);

    return (_refundedEthWei, _notProcessedTokensWei);
  }


  /* Calculation of the price */

  /**
   * @dev Calculate price for tokens
   * @param _totalTokensSoldBefore uint Amount of tokens sold before [token wei]
   * @return Calculated price
   */
  function calculateLandmarkPrice(uint _totalTokensSoldBefore) constant returns (uint) {
    return initialTokenPrice + initialTokenPrice * landmarkPriceStepNumerator / landmarkPriceStepDenominator * (_totalTokensSoldBefore / landmarkSize);
  }


  /* Lifecycle */

  function unpauseAngelToken() {
    require(now &gt;= icoFinishTimestamp);
    require(angelTokenUnpaused == false);

    angelTokenUnpaused = true;

    angelToken.unpauseContract();
  }

  function withdrawFoundationFunds() {
    require(msg.sender == angelFoundationAddress || msg.sender == angelAdminAddress);
    require(now &gt; firstRefundRoundFinishTimestamp);

    if (now &gt; firstRefundRoundFinishTimestamp &amp;&amp; now &lt;= secondRefundRoundFinishTimestamp) {
      require(firstRefundRoundFundsWithdrawal == false);

      firstRefundRoundFundsWithdrawal = true;
      angelFoundationAddress.transfer(this.balance * afterFirstRefundRoundFundsReleaseNumerator / afterFirstRefundRoundFundsReleaseDenominator);
    } else {
      angelFoundationAddress.transfer(this.balance);
    }
  }
}