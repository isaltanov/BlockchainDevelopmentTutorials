pragma solidity ^0.4.11;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title premiumDisplay
 * @dev Учебный контракт курса по разработке Blockchain от MosCodingSchool
 * @author isaltanov
 * @notice [{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"previousOwner","type":"address"},{"indexed":true,"name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"}]
 */
contract premiumDisplay is Ownable {
    
    // используем "безопасную" математику для вычислений
    using SafeMath for uint256;
    
    // Level 1. Число, которое можно разместить в блокчейне бесплатно
    uint8 public freeNumber = 0;
    event freeNumberPublished(address sender, uint8 number);

    // Level 2. Число, которое можно разместить в блокчейне за эфир
    uint256 public premiumNumber = 0;
    uint256 constant public premiumNumberPrice = 1 finney;
    event premiumNumberPublished(address sender, uint256 number, uint256 price);

    // Level 3. Строка, которую можно разместить в блокчейне за эфир, а
    //  оплату перевести владельцу контракта
    string public payableDisplayText = "";
    uint256 constant public payableDisplayPrice = 2 finney;
    event payableDisplayPublished(address sender, string text, uint256 price);
    
    // Level 4. Строка, которую можно разместить на определенное время в блокчейне за эфир,
    // оплату перевести владельцу контракта 
    string public premiumDisplayText = "";
    uint256 constant public premiumDisplayPrice = 3 finney;
    uint256 constant public premiumDisplayDuration = 15 minutes;
    uint256 public premiumDisplayExpiredDatetime = 0;
    event premiumDisplayPublished(address sender, string text, uint256 price, uint256 tilldate );
    
    // Level 5. Строку из Level 4 можно разместить за USD, расчет оплаты осуществляется
    // исходя из этой стоимости и курса ETH/USD
    uint256 public ETHUSDCentsRate = 32056;
    uint256 constant public premiumDisplayUSDCentsPrice = 1000;
    event premiumDisplayUSDPublished(address sender, string text, uint256 usd_price, uint256 rate, uint256 tilldate );
    
    // Конструктор контракта
    function premiumDisplay() public { 
    }
    
    // Level 1. Устанавливаем число в блокчейне за бесплатно
    function setFreeNumber(uint8 _freeNumber) public {
        freeNumber = _freeNumber;
        
        freeNumberPublished(msg.sender, _freeNumber );
    }
    
    // Level 2. Устанавливаем число в блокчейне за эфир
    function setPremiumNumber(uint256 _premiumNumber) public payable {
        require(msg.value >= premiumNumberPrice );
        
        keepChange(msg.sender, msg.value, premiumNumberPrice );
        premiumNumber = _premiumNumber;
        
        premiumNumberPublished(msg.sender, _premiumNumber, premiumNumberPrice );
    }
    
    // Level 3. Устанавливаем строку в блокчейне за эфир и переводим оплату  
    // владельцу контракта
    function setPayableDisplay (string _payableDisplayText) public payable {
        require(msg.value >= payableDisplayPrice );
        
        keepChange(msg.sender, msg.value, payableDisplayPrice );
        owner.transfer(payableDisplayPrice );
        payableDisplayText = _payableDisplayText;
        
        payableDisplayPublished(msg.sender, _payableDisplayText, payableDisplayPrice );
    }
    
    // Level 4. Устанавливаем строку в блокчейне за эфир на определенное время и 
    // переводим оплату владельцу контракта
    function setPremiumDisplay(string _premiumDisplayText) public payable {
        require(msg.value >= premiumDisplayPrice );
        require(now >= premiumDisplayExpiredDatetime );
        
        keepChange(msg.sender, msg.value, premiumDisplayPrice );
        owner.transfer(premiumDisplayPrice );
        premiumDisplayText = _premiumDisplayText;
        premiumDisplayExpiredDatetime = now + premiumDisplayDuration;
        
        premiumDisplayPublished(msg.sender, premiumDisplayText, premiumDisplayPrice, premiumDisplayExpiredDatetime );
    }
    
    // Level 5. Устанвливаем строку в блокчейне за USD на определенное время и 
    // переводим оплату владельцу контракта
    function setPremiumDisplayForUSD(string _premiumDisplayText) public payable {

        uint256 weiFee = calcWeiFromUSDCents(premiumDisplayUSDCentsPrice, ETHUSDCentsRate );
        
        require(msg.value >= weiFee );
        require(now >= premiumDisplayExpiredDatetime );

        keepChange(msg.sender, msg.value, weiFee );
        owner.transfer(weiFee );
        
        premiumDisplayText = _premiumDisplayText;
        premiumDisplayExpiredDatetime = now + premiumDisplayDuration;
        
        premiumDisplayUSDPublished(msg.sender, premiumDisplayText, premiumDisplayUSDCentsPrice, ETHUSDCentsRate, premiumDisplayExpiredDatetime );
    
    }
    
    // Функция для Level 5 : обновляет курс ETH к USD cents
    function updateWeiUSDRate(uint256 _rate) onlyOwner {
        ETHUSDCentsRate = _rate;
    }
    
    function keepChange(address _sender, uint256 _amount, uint256 _price) internal {
        if(_amount > _price ) {
            _sender.transfer(_amount.sub(_price ) );
        }
    }
    
    function calcWeiFromUSDCents (uint256 _usdcents,  uint256 _rateEth) internal returns (uint256){
        return _usdcents.mul(10 ** 18).div(_rateEth );
    }
}

