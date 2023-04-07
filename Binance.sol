// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "./Beth.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*This smart contract simulate Binance,
users can deposits tokens here and can get staking rewards for their Beth (Binance Eth),
as long as they have their Beth on Binance (this is same with real Binance)
*/
contract Binance {
    /* balances of users for each token in format:
    balancesOfUsers[user address][token contract address] */
    mapping (address => mapping(address => uint256)) balancesOfUsers;
    //address of beth token contract
    address beth;
    address eth;

    //here comes the staking vars
    //at which timestamp the user started staking
    mapping (address => uint256) stakedFromTS;
    mapping (address => uint256) stakedAmount;
    uint256 interestRate = 5;

    constructor() {
        beth = address(new Beth());
        /*since there isnt contract address for Eth token (cause its native token)
        the burn address will behave as Eth token address */
        eth = 0x000000000000000000000000000000000000dEaD;
    }

    //deposit Eth into your Eth Binance balance
    function depositEth() public payable {
        balancesOfUsers[msg.sender][eth] += msg.value;
    }

    //deposit ERC20 token into your token Binance balance
    function depositERC20(address token, uint256 amount) public {
        ERC20(token).transferFrom(msg.sender, address(this), amount);
        balancesOfUsers[msg.sender][token] += amount;
        if (token == beth) claimReward();
    }

    /* buy Beth for Eth
    1 Beth costs 1 Eth from your Binance balance */
    function buyBeth(uint256 amount) public {
        Beth(beth).mint(address(this), amount);
        balancesOfUsers[msg.sender][beth] += amount;
        balancesOfUsers[msg.sender][eth] -= amount;
        claimReward();
    }

    //withdraw Eth from your Binance balance to your address
    function withdrawEth(uint256 amount) public payable {
        balancesOfUsers[msg.sender][eth] -= amount;
        payable(msg.sender).transfer(amount);
    }

    //withdraw token from your Binance balance to your address
    function withdrawERC20(address token, uint256 amount) public {
        balancesOfUsers[msg.sender][token] -= amount;
        ERC20(token).transfer(msg.sender, amount);
        if (token == beth) claimReward();
    }

    //get token balance on Binance of user
    function getBalance(address user, address token) public view returns(uint256) {
        return balancesOfUsers[user][token];
    }

    //get address of Beth token contract
    function getBethAddress() public view returns(address) {
        return beth;
    }

    //update staking vars
    function updateStaking() private {
        if (balancesOfUsers[msg.sender][beth] == 0) {
            stakedFromTS[msg.sender] = 0;
        }
        else {
            stakedFromTS[msg.sender] = block.timestamp;
        }
        stakedAmount[msg.sender] = balancesOfUsers[msg.sender][beth];
    }

    //claim staking rewards and restart staking
    function claimReward() public {
        uint256 reward = countReward();
        Beth(beth).mint(address(this), reward);
        balancesOfUsers[msg.sender][beth] += reward;
        updateStaking();
    }

    function countReward() public view returns(uint256) {
        uint256 secondsInYear = 31536000;
        uint256 secondsStaked = 0;
        if (stakedFromTS[msg.sender] > 0) secondsStaked = block.timestamp - stakedFromTS[msg.sender];
        uint256 reward = (stakedAmount[msg.sender] * interestRate * secondsStaked) / (100 * secondsInYear);
        return reward;
    }

    //used only for testing for not losing testnet Eth for which is bought Beth
    /*
    function withdrawContract() public {
        address me = msg.sender;
        payable(me).transfer(address(this).balance);
    }
    */
}
