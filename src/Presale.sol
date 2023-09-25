// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

/* ========== Imports ========== */

import {Cloudy} from "./CloudyToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "./libraries/OracleLib.sol";

/* ========== Interfaces, libraries, contracts ========== */

contract Presale is Ownable, ReentrancyGuard {
    /* ============ Errors ============ */

    error Presale__TokenAndPriceFeedLengthMismatch();
    error Presale__TokenNotAllowed(address tokenAddress);
    error Presale__NotUnlocked();
    error Presale__NotLocked();
    error Presale__TransferFailed(address tokenAddress, uint256 amount);
    error Presale__MustBeMoreThanZero();
    error Presale__UnlockShouldBeInAtLeastOneHour();
    error Presale__MaxSupplyReached();

    /* ============ Types ============ */

    using OracleLib for AggregatorV3Interface;

    /* ============ State Variables ============ */

    Cloudy private immutable cloudy;
    uint256 private immutable unlockTimestamp;
    uint256 private immutable tokenPriceInUsd;
    uint256 private immutable totalSupply;

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;

    mapping(address token => address priceFeed) priceFeeds;
    address[] allowedTokens;

    mapping(address user => uint256 tokens) private _balances;
    uint256 private _tokenSold;

    /* ============ Events ============ */

    event tokenBought(address indexed buyer, uint256 amountReceived);
    event tokenWithdrawn(address indexed buyer, uint256 amountWithdrawn);
    event tokenBurned(uint256 amountBurned);

    /* ========== Modifiers ========== */

    modifier onlyAfterUnlock() {
        if (block.timestamp < unlockTimestamp) {
            revert Presale__NotUnlocked();
        }
        _;
    }

    modifier onlyBeforeUnlock() {
        if (block.timestamp >= unlockTimestamp) {
            revert Presale__NotLocked();
        }
        _;
    }

    modifier onlyAllowedToken(address tokenAddress) {
        if (priceFeeds[tokenAddress] == address(0)) {
            revert Presale__TokenNotAllowed(tokenAddress);
        }
        if (tokenAddress == address(cloudy)) {
            revert Presale__TokenNotAllowed(tokenAddress);
        }
        _;
    }

    modifier moreTanZero(uint256 amount) {
        if (amount <= 0) {
            revert Presale__MustBeMoreThanZero();
        }
        _;
    }

    /* ========== FUNCTIONS ========== */

    /* ========== constructor ========== */
    constructor(
        uint256 _unlockTimestamp,
        uint256 _tokenPriceInUsdInWei,
        uint256 _maxSupply,
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert Presale__TokenAndPriceFeedLengthMismatch();
        }
        if (_unlockTimestamp <= block.timestamp + 1 hours) {
            revert Presale__UnlockShouldBeInAtLeastOneHour();
        }
        if (_maxSupply <= 0) {
            revert Presale__MustBeMoreThanZero();
        }
        cloudy = new Cloudy(_maxSupply);
        totalSupply = _maxSupply * PRECISION;
        unlockTimestamp = _unlockTimestamp;
        tokenPriceInUsd = _tokenPriceInUsdInWei;
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            allowedTokens.push(tokenAddresses[i]);
        }
    }

    /* ========== Receive ========== */
    /* ========== Fallback ========== */
    /* ========== External functions ========== */
    function buy(address tokenAddress, uint buyAmount)
        external
        nonReentrant
        onlyBeforeUnlock
        onlyAllowedToken(tokenAddress)
        moreTanZero(buyAmount)
    {
        if (_tokenSold + buyAmount > totalSupply) {
            revert Presale__MaxSupplyReached();
        }
        uint256 tokenAmount = _calculateTokensPrice(tokenAddress, buyAmount);

        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        if (!success) {
            revert Presale__TransferFailed(tokenAddress, tokenAmount);
        }
        _balances[msg.sender] += buyAmount;
        _tokenSold += buyAmount;
        emit tokenBought(msg.sender, buyAmount);
    }

    function withdraw() external onlyAfterUnlock nonReentrant {
        if (_balances[msg.sender] == 0) {
            revert Presale__MustBeMoreThanZero();
        }
        uint256 amount = _balances[msg.sender];
        _balances[msg.sender] = 0;
        bool success = cloudy.transfer(msg.sender, amount);
        if (!success) {
            revert Presale__TransferFailed(address(cloudy), amount);
        }
        emit tokenWithdrawn(msg.sender, amount);
    }

    function burnRemaining() external onlyAfterUnlock nonReentrant {
        uint256 amount = totalSupply - _tokenSold;
        _tokenSold = totalSupply;
        cloudy.burn(amount);
        emit tokenBurned(amount);
    }


    function withdrawAllTokens(address _to) external onlyOwner onlyAfterUnlock {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (IERC20(allowedTokens[i]).balanceOf(address(this)) != 0) {
                withdrawToken(allowedTokens[i], _to);
            }
        }
    }

    /* ========== Public functions ========== */

    function withdrawToken(address tokenAddress, address _to) public onlyOwner onlyAfterUnlock onlyAllowedToken(tokenAddress) {
        IERC20 token = IERC20(tokenAddress);
        bool success = token.transfer(_to, token.balanceOf(address(this)));
        if (!success) {
            revert Presale__TransferFailed(tokenAddress, token.balanceOf(address(this)));
        }
    }

    /* ========== Internal functions ========== */
    /* ========== Private functions ========== */
    /* ========== Internal & private view / pure functions ========== */

    function _getTokenAmountFromUsd(address token, uint256 usdAmountInWei) private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeeds[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return (usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    function _calculateTokensPrice(address tokenAddress, uint256 buyAmount)
        private
        view
        onlyAllowedToken(tokenAddress)
        returns (uint256)
    {
        uint256 buyAmountInUsd = (buyAmount * tokenPriceInUsd) / PRECISION; // ex: 2e18 * 1e18 / 1e18 = 2e18
        uint256 tokenAmount = _getTokenAmountFromUsd(tokenAddress, buyAmountInUsd);
        return tokenAmount;
    }

    /* ========== External & public view / pure functions ========== */

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) external view returns (uint256) {
        return (_getTokenAmountFromUsd(token, usdAmountInWei));
    }

    function calculateTokensPrice(address tokenAddress, uint256 buyAmount) external view returns (uint256) {
        return _calculateTokensPrice(tokenAddress, buyAmount);
    }

    function getTokenSold() external view returns (uint256) {
        return _tokenSold;
    }

    function getAllowedTokens() external view returns (address[] memory) {
        return allowedTokens;
    }

    function getBalance(address user) external view returns (uint256) {
        return _balances[user];
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    function getTokenAddress() external view returns (address) {
        return address(cloudy);
    }

    function getToken() external view returns (Cloudy) {
        return cloudy;
    }

    function getUnlockTimestamp() external view returns (uint256) {
        return unlockTimestamp;
    }

    function getTokenPriceInUsd() external view returns (uint256) {
        return tokenPriceInUsd;
    }

    function getMaxSupply() external view returns (uint256) {
        return totalSupply;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function getTokenUsdPriceFeed(address token) external view returns (address) {
        return priceFeeds[token];
    }
}
