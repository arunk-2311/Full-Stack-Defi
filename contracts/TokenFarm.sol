//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    //mapping token address to staker's address->amount

    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;

    address[] public allowedTokens;
    address[] public stakers;

    IERC20 public DappToken;

    // stake Tokens - DONE!
    // unstake Tokens - DONE!
    // issue Tokens - DONE!
    // add Allowed Tokens - DONE!
    // getEthValue - DONE!

    constructor(address DappTokenAddress) public {
        DappToken = IERC20(DappTokenAddress);
    }

    function setPriceFeed(address _token, address _priceFeed) public onlyOwner {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAddress = tokenPriceFeedMapping[_token];

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());

        return (uint256(price), decimals);
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        //price of the token * stakingBalance[_token][_user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);

        return (stakingBalance[_token][_user] * price) / (10**decimals);
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;

        require(
            uniqueTokensStaked[_user] > 0,
            "You have'nt staked anything bitch!"
        );

        for (
            uint256 allowedTokenIndex;
            allowedTokenIndex < allowedTokens.length;
            allowedTokenIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokenIndex]
                );
        }
    }

    function issueTokens() public onlyOwner {
        for (
            uint256 stakerIndex = 0;
            stakerIndex < stakers.length;
            stakerIndex++
        ) {
            address recipient = stakers[stakerIndex];
            //send them total reward based on the total assets locked
            uint256 userTotalValue = getUserTotalValue(recipient);
            DappToken.transfer(msg.sender, userTotalValue);
        }
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "enter some amount to stake!");
        require(tokenisAllowed(_token), "This token is not allowed");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function removeStakers(address _user) public {
        for (
            uint256 stakerIndex = 0;
            stakerIndex < stakers.length;
            ++stakerIndex
        ) {
            if (stakers[stakerIndex] == _user) {
                removeStakersByindex(stakerIndex);
                break;
            }
        }
    }

    function removeStakersByindex(uint256 stakerIndex) public {
        stakers[stakerIndex] = stakers[stakers.length - 1];
        stakers.pop();
    }

    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(
            balance > 0,
            "You don't have anything staked,don't be a clown!"
        );
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
        removeStakers(msg.sender);
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        //if he has not staked that token before
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenisAllowed(address _token) public returns (bool) {
        for (
            uint256 tokenAllowedIndex = 0;
            tokenAllowedIndex < allowedTokens.length;
            tokenAllowedIndex++
        ) {
            if (allowedTokens[tokenAllowedIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}
