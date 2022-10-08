// https://uniswap.org/docs/v2/smart-contracts/pair-erc-20/
// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol implementation
// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

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

contract luckydrop{
    struct Game{
        uint256 id;
        string key;
        string name;
        string team1;
        string team2;
        string result;
        uint256 startTime;
        uint256 endTime;
        uint status;
    }

    uint256 gameIdIndex;

    address adminAddress;

    constructor() {
        adminAddress  = msg.sender;
    }

    Game[] games;

    mapping (uint256 => mapping (string => mapping (address => uint256))) betData;

    mapping (uint256 => mapping (string => uint256)) statisticData;
    
    function bet(uint256 gameId, string memory team ) public onlyHuman payable  {
        // string memory team1 = "team1";
        require(gameId <= gameIdIndex && gameId >= 0, "gameId param is not valid");
        require( keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("team1"))
            ||   keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("team2"))
            ||  keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("equal")), "team param is not valid");
        uint256 amount = msg.value;
        address better = msg.sender;
        betData[gameId][team][better] = betData[gameId][team][better] + amount;
        statisticData[gameId][team] = statisticData[gameId][team] + amount;

    }

    function addGame(string memory team1, string memory team2, uint256 startTime, uint256 endTime) public onlyAdmin returns (uint256){
        gameIdIndex++;
        Game memory  g = Game(gameIdIndex, "","", team1, team2,"", startTime, endTime , 0);
        games.push(g);
        return gameIdIndex;
    }

    function setGameResult(uint256 gameId,  string memory result) public onlyAdmin{
        require(gameId <= gameIdIndex && gameId >= 0, "gameId param is not valid");
        Game memory g = games[gameId];
        g.result = result;
        if(keccak256(abi.encodePacked(result)) == keccak256(abi.encodePacked("team1")){
            
        }
    }

    function getGame(uint256 gameId) public view returns (uint256 , uint256, uint256 ){
        require(gameId <= gameIdIndex && gameId >= 0, "gameId param is not valid");
        return (statisticData[gameId]["team1"], statisticData[gameId]["team2"],  statisticData[gameId]["equal"]); 
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
    
}
