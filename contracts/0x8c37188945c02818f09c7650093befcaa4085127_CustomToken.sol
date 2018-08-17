pragma solidity ^0.4.19;

contract BaseToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address =&gt; uint256) public balanceOf;
    mapping (address =&gt; mapping (address =&gt; uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] &gt;= _value);
        require(balanceOf[_to] + _value &gt; balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value &lt;= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract AirdropToken is BaseToken {
    uint256 public airAmount;
    uint256 public airBegintime;
    uint256 public airEndtime;
    address public airSender;
    uint32 public airLimitCount;

    mapping (address =&gt; uint32) public airCountOf;

    event Airdrop(address indexed from, uint32 indexed count, uint256 tokenValue);

    function airdrop() public payable {
        require(now &gt;= airBegintime &amp;&amp; now &lt;= airEndtime);
        require(msg.value == 0);
        if (airLimitCount &gt; 0 &amp;&amp; airCountOf[msg.sender] &gt;= airLimitCount) {
            revert();
        }
        _transfer(airSender, msg.sender, airAmount);
        airCountOf[msg.sender] += 1;
        Airdrop(msg.sender, airCountOf[msg.sender], airAmount);
    }
}

contract ICOToken is BaseToken {
    // 1 ether = icoRatio token
    uint256 public icoRatio;
    uint256 public icoBegintime;
    uint256 public icoEndtime;
    address public icoSender;
    address public icoHolder;

    event ICO(address indexed from, uint256 indexed value, uint256 tokenValue);
    event Withdraw(address indexed from, address indexed holder, uint256 value);

    function ico() public payable {
        require(now &gt;= icoBegintime &amp;&amp; now &lt;= icoEndtime);
        uint256 tokenValue = (msg.value * icoRatio * 10 ** uint256(decimals)) / (1 ether / 1 wei);
        if (tokenValue == 0 || balanceOf[icoSender] &lt; tokenValue) {
            revert();
        }
        _transfer(icoSender, msg.sender, tokenValue);
        ICO(msg.sender, msg.value, tokenValue);
    }

    function withdraw() public {
        uint256 balance = this.balance;
        icoHolder.transfer(balance);
        Withdraw(msg.sender, icoHolder, balance);
    }
}

contract CustomToken is BaseToken, AirdropToken, ICOToken {
    function CustomToken() public {
        totalSupply = 12000000000000000000000000000;
        name = &#39;Fantasy&#39;;
        symbol = &#39;FT&#39;;
        decimals = 18;
        balanceOf[0xa06ea172c01d7551d66f0df294eabd8d6c5822be] = totalSupply;
        Transfer(address(0), 0xa06ea172c01d7551d66f0df294eabd8d6c5822be, totalSupply);

        airAmount = 5000000000000000000000;
        airBegintime = 1520312400;
        airEndtime = 1609390800;
        airSender = 0xa06ea172c01d7551d66f0df294eabd8d6c5822be;
        airLimitCount = 1;

        icoRatio = 200000;
        icoBegintime = 1520312400;
        icoEndtime = 1924923600;
        icoSender = 0xa06ea172c01d7551d66f0df294eabd8d6c5822be;
        icoHolder = 0xa06ea172c01d7551d66f0df294eabd8d6c5822be;
    }

    function() public payable {
        if (msg.value == 0) {
            airdrop();
        } else {
            ico();
        }
    }
}