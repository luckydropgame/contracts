// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/math/SafeMath.sol"; 

interface IBEP40 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint256);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract luckydrop{
    struct Game{
        uint256 id;
        string key;
        string teamName1;
        string teamName2;
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
    
    function bet(uint256 gameId, string memory team ) public onlyHuman checkTeam(team) checkGameId(gameId)  payable  {
        require(msg.value != 0, "Error, msg.value must be higher that 0");
        require(games[gameId].status == 1, "can not bet now");
        uint256 amount = msg.value;
        address better = msg.sender;
        betData[gameId][team][better] = betData[gameId][team][better] + amount;
        games[gameId].statisticData[team] = games[gameId].statisticData[team]  + amount;

    }

    function addGame(string memory key, string memory teamName1, string memory teamName2, uint256 startTime, uint256 endTime) public onlyAdmin returns (uint256){
        gameIdIndex++;
        Game storage  g = games[gameIdIndex];
        g.id = gameIdIndex;
        g.key = key;
        g.result = "";
        g.teamName1 = teamName1;
        g.teamName2 = teamName2;
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

    function setGameResult(uint256 gameId,  string memory winTeam) public onlyAdmin checkTeam(winTeam) checkGameId(gameId) returns (uint256){
        require(games[gameId].status == 1, "game is not open");

        Game storage g = games[gameId];
        g.result = winTeam;
        g.status = 2;
        
        return g.status;
    }

    function claimGameResult(uint256 gameId) public onlyHuman checkGameId(gameId) payable{
        require(games[gameId].status == 2, "game result is not set");
        require(!claimFlag[msg.sender][gameId] , "claim already");

        Game storage g = games[gameId];
        
        string storage team = g.result ;

        require(betData[gameId][team][msg.sender] > 0 , "you have nothing to claim");
   
        uint256 total = g.statisticData["team1"] + g.statisticData["team2"] + g.statisticData["equal"];
        uint256 userRewaldTotal = SafeMath.div(SafeMath.mul(total, 9), 10);
        uint256 userAmount = betData[gameId][team][msg.sender]; 
        uint256 percent =  SafeMath.div(userAmount * 100000, g.statisticData[team]);
        uint256 reward = SafeMath.mul(percent, userRewaldTotal);
        uint256 real = SafeMath.div(reward, 100000);

        claimFlag[msg.sender][gameId] = true;

        adminAddress.transfer(real);
            
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
        uint256 percent =  SafeMath.div(userAmount * 100000, g.statisticData[team]);
        uint256 reward = SafeMath.mul(percent, userRewaldTotal);
        uint256 real = SafeMath.div(reward, 100000);

        return (userAmount, real, claimFlag[msg.sender][gameId]);
    }


    function getGameInfo(uint256 gameId) public view checkGameId(gameId) returns (uint256 , uint256, uint256, string memory, string memory, string memory){
        Game storage g = games[gameId];
        return (g.statisticData["team1"], g.statisticData["team2"], g.statisticData["equal"], g.teamName1 , g.teamName2 , g.key); 
    }


    function getUserGameInfo(uint256 gameId ) public view checkGameId(gameId) returns (uint256 , uint256, uint256 ){
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

    modifier checkTeam(string memory team){
        require( keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("team1"))
            ||   keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("team2"))
            ||   keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked("equal")), "team param is not valid");
        _;
    }

    modifier checkGameId(uint256 gameId){
        require(gameId <= gameIdIndex && gameId >= 0, "gameId param is not valid");
        _;
    }

    //200000000000000
    
}
