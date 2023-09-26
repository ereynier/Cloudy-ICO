// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployPresale} from "../../script/DeployPresale.s.sol";
import {Presale} from "../../src/Presale.sol";
import {Cloudy} from "../../src/CloudyToken.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract PresaleTest is Test {
    DeployPresale deployer;
    Presale presale;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address daiUsdPriceFeed;
    address ghoUsdPriceFeed;
    address weth;
    address wbtc;
    address dai;
    address gho;
    uint256 tokenPriceInUsd;
    uint256 totalSupply;
    uint256 unlockTimestamp;

    address public OWNER = makeAddr("owner");
    address public USER_1 = makeAddr("user1");
    address public USER_2 = makeAddr("user2");
    uint256 public constant TOKEN_AMOUNT = 1e18; // 1 token
    uint256 public constant STARTING_ERC20_BALANCE = 1000e18; // 10 tokens

    address[] public allowedTokens;
    address[] public priceFeeds;

    function setUp() public {
        deployer = new DeployPresale();
        (presale, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, daiUsdPriceFeed, ghoUsdPriceFeed, weth, wbtc, dai, gho,tokenPriceInUsd, totalSupply, unlockTimestamp, ) =
            config.activeNetworkConfig();
        // ERC20Mock(weth).mint(USER_1, STARTING_ERC20_BALANCE);
        // ERC20Mock(weth).mint(USER_2, STARTING_ERC20_BALANCE);
        // ERC20Mock(wbtc).mint(USER_1, STARTING_ERC20_BALANCE);
        // ERC20Mock(wbtc).mint(USER_2, STARTING_ERC20_BALANCE);
        // ERC20Mock(dai).mint(USER_1, STARTING_ERC20_BALANCE);
        // ERC20Mock(dai).mint(USER_2, STARTING_ERC20_BALANCE);
        // ERC20Mock(gho).mint(USER_1, STARTING_ERC20_BALANCE);
        // ERC20Mock(gho).mint(USER_2, STARTING_ERC20_BALANCE);
        deal(address(weth), USER_1, STARTING_ERC20_BALANCE);
        deal(address(weth), USER_2, STARTING_ERC20_BALANCE);
        deal(address(wbtc), USER_1, STARTING_ERC20_BALANCE);
        deal(address(wbtc), USER_2, STARTING_ERC20_BALANCE);
        deal(address(dai), USER_1, STARTING_ERC20_BALANCE);
        deal(address(dai), USER_2, STARTING_ERC20_BALANCE);
        deal(address(gho), USER_1, STARTING_ERC20_BALANCE);
        deal(address(gho), USER_2, STARTING_ERC20_BALANCE);

        allowedTokens.push(weth);
        allowedTokens.push(wbtc);
        allowedTokens.push(dai);
        allowedTokens.push(gho);
        priceFeeds.push(ethUsdPriceFeed);
        priceFeeds.push(btcUsdPriceFeed);
        priceFeeds.push(daiUsdPriceFeed);
        priceFeeds.push(ghoUsdPriceFeed);
    }

    /* ===== Constructor Tests ===== */

    function testConstructorRevertIfTokenAndPriceFeedLengthMismatch() public {
        address[] memory testPriceFeeds = new address[](3);
        priceFeeds[0] = ethUsdPriceFeed;
        priceFeeds[1] = btcUsdPriceFeed;
        priceFeeds[2] = daiUsdPriceFeed;
        vm.expectRevert(Presale.Presale__TokenAndPriceFeedLengthMismatch.selector);
        new Presale(block.timestamp + 100 days, 1e17, 1e7, allowedTokens, testPriceFeeds);
    } 

    function testConstructorRevertIfUnlockIsLessThanOneHour() public {
        vm.expectRevert(Presale.Presale__UnlockShouldBeInAtLeastOneHour.selector);
        new Presale(block.timestamp + 1 minutes, 1e17, 1e7, allowedTokens, priceFeeds);
    }

    function testConstructorRevertIfMaxSupplyIsZero() public {
        vm.expectRevert(Presale.Presale__MustBeMoreThanZero.selector);
        new Presale(block.timestamp + 100 days, 1e17, 0, allowedTokens, priceFeeds);
    }

    /* ======= buy Tests ======= */


    function testBuyRevertIfAfterUnlock() public {
        vm.warp(block.timestamp + 101 days);
        vm.startPrank(USER_1);
        vm.expectRevert(Presale.Presale__NotLocked.selector);
        presale.buy(weth, TOKEN_AMOUNT);
        vm.stopPrank();
    }

    function testBuyRevertIfNotAllowedToken() public {
        vm.startPrank(USER_1);
        vm.expectRevert(abi.encodeWithSelector(Presale.Presale__TokenNotAllowed.selector, address(this)));
        presale.buy(address(this), TOKEN_AMOUNT);
        vm.stopPrank();
    }

    function testBuyRevertIfTokenNotApproved() public {
        vm.startPrank(USER_1);
        vm.expectRevert();
        presale.buy(weth, TOKEN_AMOUNT);
        vm.stopPrank();
    }

    function testBuyRevertIfTokenAMountIsZero() public {
        vm.startPrank(USER_1);
        ERC20Mock(weth).approve(address(presale), STARTING_ERC20_BALANCE);
        vm.expectRevert(Presale.Presale__MustBeMoreThanZero.selector);
        presale.buy(weth, 0);
        vm.stopPrank();
    }

    function testBuyRevertIfMaxSupplyReached() public {
        vm.startPrank(USER_1);
        ERC20Mock(weth).approve(address(presale), STARTING_ERC20_BALANCE);
        uint256 precision = presale.getPrecision();
        vm.expectRevert(Presale.Presale__MaxSupplyReached.selector);
        presale.buy(weth, totalSupply * precision + 1);
        vm.stopPrank();
    }

    function testBuyRevertIfMaxSupplyReachedinTwoTimes() public {
        vm.startPrank(USER_1);
        ERC20Mock(wbtc).approve(address(presale), STARTING_ERC20_BALANCE);
        uint256 precision = presale.getPrecision();
        presale.buy(wbtc, (totalSupply * precision) / 2);
        vm.stopPrank();
        vm.startPrank(USER_2);
        ERC20Mock(wbtc).approve(address(presale), STARTING_ERC20_BALANCE);
        vm.expectRevert(Presale.Presale__MaxSupplyReached.selector);
        presale.buy(wbtc, (totalSupply * precision) / 2 + 1);
        vm.stopPrank();
    }

    function testBuy() public {
        vm.startPrank(USER_1);
        ERC20Mock(weth).approve(address(presale), STARTING_ERC20_BALANCE);
        presale.buy(weth, TOKEN_AMOUNT);
        vm.warp(block.timestamp + 101 days);
        presale.withdraw();
        vm.stopPrank();
        assertEq(presale.getToken().balanceOf(USER_1), TOKEN_AMOUNT);
    }

    function testBuyWithEveryToken() public {
        uint256 expectedBalance;
        uint256[] memory expectedERC20Balances = new uint256[](4);
        vm.startPrank(USER_1);
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            ERC20Mock(allowedTokens[i]).approve(address(presale), STARTING_ERC20_BALANCE);
            presale.buy(allowedTokens[i], TOKEN_AMOUNT);
            expectedBalance += TOKEN_AMOUNT; 
            expectedERC20Balances[i] = STARTING_ERC20_BALANCE - presale.calculateTokensPrice(allowedTokens[i], TOKEN_AMOUNT);
        }
        vm.warp(block.timestamp + 101 days);
        presale.withdraw();
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            assertEq(presale.getToken().balanceOf(USER_1), expectedBalance);
            assertEq(ERC20Mock(allowedTokens[i]).balanceOf(USER_1), expectedERC20Balances[i]);
        }
        vm.stopPrank();
    }


    /* ===== withdraw Tests ===== */

    function testWithdrawRevertIfNotAfterUnlock() public {
        vm.expectRevert();
        presale.withdraw();
    }

    function testWithdrawRevertIfBalanceIsZero() public {
        vm.warp(block.timestamp + 101 days);
        vm.startPrank(USER_1);
        vm.expectRevert(Presale.Presale__MustBeMoreThanZero.selector);
        presale.withdraw();
        vm.stopPrank();
    }

    function testWithdrawRevertIfWithdrawingTwoTimes() public {
        vm.startPrank(USER_1);
        ERC20Mock(weth).approve(address(presale), STARTING_ERC20_BALANCE);
        presale.buy(weth, TOKEN_AMOUNT);
        vm.warp(block.timestamp + 101 days);
        presale.withdraw();
        vm.expectRevert(Presale.Presale__MustBeMoreThanZero.selector);
        presale.withdraw();
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(USER_1);
        ERC20Mock(weth).approve(address(presale), STARTING_ERC20_BALANCE);
        presale.buy(weth, TOKEN_AMOUNT);
        vm.warp(block.timestamp + 101 days);
        assertEq(presale.getToken().balanceOf(address(presale)), totalSupply * presale.getPrecision());
        assertEq(presale.getToken().balanceOf(USER_1), 0);
        presale.withdraw();
        assertEq(presale.getToken().balanceOf(address(presale)), totalSupply * presale.getPrecision() - TOKEN_AMOUNT);
        assertEq(presale.getToken().balanceOf(USER_1), TOKEN_AMOUNT);
        vm.stopPrank();
    }

    /* ===== burnRemaining Tests ===== */

    function testBurnRemainingRevertIfNotAfterUnlock() public {
        vm.expectRevert();
        presale.burnRemaining();
    }

    function testBurnRemainingRevertIfBurnZero() public {
        //ERC20Mock(weth).mint(USER_1, 10000 ether);
        deal(address(weth), USER_1, 10000 ether);
        vm.startPrank(USER_1);
        ERC20Mock(weth).approve(address(presale), 10000 ether);
        presale.buy(weth, totalSupply * presale.getPrecision());
        vm.stopPrank();
        vm.warp(block.timestamp + 101 days);
        vm.expectRevert(Cloudy.Cloudy__MustBeMoreThanZero.selector);
        presale.burnRemaining();
    }

    function testBurnRemainingRevertIfBurnTwice() public {
        vm.startPrank(USER_1);
        ERC20Mock(weth).approve(address(presale), STARTING_ERC20_BALANCE);
        presale.buy(weth, TOKEN_AMOUNT);
        vm.stopPrank();
        vm.warp(block.timestamp + 101 days);
        assertEq(presale.getToken().balanceOf(address(presale)), totalSupply * presale.getPrecision());
        presale.burnRemaining();
        assertEq(presale.getToken().balanceOf(address(presale)), TOKEN_AMOUNT);
        vm.expectRevert(Cloudy.Cloudy__MustBeMoreThanZero.selector);
        presale.burnRemaining();
    }

    function testBurnRemainingWithEverything() public {
        vm.warp(block.timestamp + 101 days);
        assertEq(presale.getToken().balanceOf(address(presale)), totalSupply * presale.getPrecision());
        presale.burnRemaining();
        assertEq(presale.getToken().balanceOf(address(presale)), 0);
    }

    function testBurnRemainingWithTokenNotWithdrawn() public {
        vm.startPrank(USER_1);
        ERC20Mock(weth).approve(address(presale), STARTING_ERC20_BALANCE);
        presale.buy(weth, TOKEN_AMOUNT);
        vm.stopPrank();
        vm.warp(block.timestamp + 101 days);
        assertEq(presale.getToken().balanceOf(address(presale)), totalSupply * presale.getPrecision());
        presale.burnRemaining();
        assertEq(presale.getToken().balanceOf(address(presale)), TOKEN_AMOUNT);
    }

    function testBurnRemainingWithTokenWithdrawn() public {
        vm.startPrank(USER_1);
        ERC20Mock(weth).approve(address(presale), STARTING_ERC20_BALANCE);
        presale.buy(weth, TOKEN_AMOUNT);
        vm.stopPrank();
        vm.warp(block.timestamp + 101 days);
        assertEq(presale.getToken().balanceOf(address(presale)), totalSupply * presale.getPrecision());
        vm.prank(USER_1);
        presale.withdraw();
        assertEq(presale.getToken().balanceOf(address(presale)), totalSupply * presale.getPrecision() - TOKEN_AMOUNT);
        presale.burnRemaining();
        assertEq(presale.getToken().balanceOf(address(presale)), 0);
    }


    /* ===== withdrawAllTokens Tests ===== */

    function testWithdtrawAllTokensRevertIfNotOwner() public {
        vm.expectRevert();
        presale.withdrawAllTokens(OWNER);
    }

    function testWithdtrawAllTokensRevertIfNotAfterUnlock() public {
        vm.startPrank(OWNER);
        Presale testPresale = new Presale(block.timestamp + 100 days, 1e17, 1e7, allowedTokens, priceFeeds);
        vm.expectRevert(Presale.Presale__NotUnlocked.selector);
        testPresale.withdrawAllTokens(OWNER);
    }

    function testWithdrawAllTokenWithFirstToken() public {
        address tokenUsed = weth;
        vm.prank(OWNER);
        Presale testPresale = new Presale(block.timestamp + 100 days, 1e17, 1e7, allowedTokens, priceFeeds);
        vm.startPrank(USER_1);
        ERC20Mock(tokenUsed).approve(address(testPresale), STARTING_ERC20_BALANCE);
        testPresale.buy(tokenUsed, TOKEN_AMOUNT);
        vm.stopPrank();
        uint256 expectedBalance = testPresale.calculateTokensPrice(tokenUsed, TOKEN_AMOUNT);
        assertEq(ERC20Mock(tokenUsed).balanceOf(address(testPresale)), expectedBalance);
        vm.startPrank(OWNER);
        vm.warp(block.timestamp + 101 days);
        testPresale.withdrawAllTokens(OWNER);
        assertEq(ERC20Mock(tokenUsed).balanceOf(address(testPresale)), 0);
        assertEq(ERC20Mock(tokenUsed).balanceOf(OWNER), expectedBalance);
    }

    function testWithdrawAllTokenWithLastToken() public {
        address tokenUsed = gho;
        vm.prank(OWNER);
        Presale testPresale = new Presale(block.timestamp + 100 days, 1e17, 1e7, allowedTokens, priceFeeds);
        vm.startPrank(USER_1);
        ERC20Mock(tokenUsed).approve(address(testPresale), STARTING_ERC20_BALANCE);
        testPresale.buy(tokenUsed, TOKEN_AMOUNT);
        vm.stopPrank();
        uint256 expectedBalance = testPresale.calculateTokensPrice(tokenUsed, TOKEN_AMOUNT);
        assertEq(ERC20Mock(tokenUsed).balanceOf(address(testPresale)), expectedBalance);
        vm.startPrank(OWNER);
        vm.warp(block.timestamp + 101 days);
        testPresale.withdrawAllTokens(OWNER);
        assertEq(ERC20Mock(tokenUsed).balanceOf(address(testPresale)), 0);
        assertEq(ERC20Mock(tokenUsed).balanceOf(OWNER), expectedBalance);
    }

    function testWithdrawAllTokenWithTwoToken() public {
        address[] memory tokenUsed = new address[](2);
        tokenUsed[0] = weth;
        tokenUsed[1] = dai;
        uint256[] memory expectedBalances = new uint256[](2); 
        vm.prank(OWNER);
        Presale testPresale = new Presale(block.timestamp + 100 days, 1e17, 1e7, allowedTokens, priceFeeds);
        vm.startPrank(USER_1);
        for (uint256 i = 0; i < tokenUsed.length; i++) {
            ERC20Mock(tokenUsed[i]).approve(address(testPresale), STARTING_ERC20_BALANCE);
            testPresale.buy(tokenUsed[i], TOKEN_AMOUNT);
            expectedBalances[i] = testPresale.calculateTokensPrice(tokenUsed[i], TOKEN_AMOUNT);
        }
        vm.stopPrank();
        vm.startPrank(OWNER);
        vm.warp(block.timestamp + 101 days);
        assertEq(ERC20Mock(tokenUsed[0]).balanceOf(address(testPresale)), expectedBalances[0]);
        assertEq(ERC20Mock(tokenUsed[1]).balanceOf(address(testPresale)), expectedBalances[1]);
        testPresale.withdrawAllTokens(OWNER);
        assertEq(ERC20Mock(tokenUsed[0]).balanceOf(address(testPresale)), 0);
        assertEq(ERC20Mock(tokenUsed[0]).balanceOf(OWNER), expectedBalances[0]);
        assertEq(ERC20Mock(tokenUsed[1]).balanceOf(address(testPresale)), 0);
        assertEq(ERC20Mock(tokenUsed[1]).balanceOf(OWNER), expectedBalances[1]);
        vm.stopPrank();
    }

    /* ===== withdrawToken Tests ===== */

    function testWithdrawTokenRevertIfNotOwner() public {
        vm.expectRevert();
        presale.withdrawToken(weth, OWNER);
    }

    function testWithdrawTokenRevertIfNotAfterUnlock() public {
        vm.startPrank(OWNER);
        Presale testPresale = new Presale(block.timestamp + 100 days, 1e17, 1e7, allowedTokens, priceFeeds);
        vm.expectRevert(Presale.Presale__NotUnlocked.selector);
        testPresale.withdrawToken(weth, OWNER);
    }

    function testWithdrawTokenRevertIfTokenNotInAllowedTokens() public {
        vm.startPrank(OWNER);
        Presale testPresale = new Presale(block.timestamp + 100 days, 1e17, 1e7, allowedTokens, priceFeeds);
        vm.warp(block.timestamp + 101 days);
        vm.expectRevert(abi.encodeWithSelector(Presale.Presale__TokenNotAllowed.selector, address(this)));
        testPresale.withdrawToken(address(this), OWNER);
    }

    function testWithdrawTokenRevertIfTokenIsCloudy() public {
        vm.startPrank(OWNER);
        Presale testPresale = new Presale(block.timestamp + 100 days, 1e17, 1e7, allowedTokens, priceFeeds);
        vm.warp(block.timestamp + 101 days);
        address cloudyAddress = address(testPresale.getTokenAddress());
        vm.expectRevert(abi.encodeWithSelector(Presale.Presale__TokenNotAllowed.selector, cloudyAddress));
        testPresale.withdrawToken(cloudyAddress, OWNER);
    }

    function testWithdrawToken() public {
        address tokenUsed = wbtc;
        vm.prank(OWNER);
        Presale testPresale = new Presale(block.timestamp + 100 days, 1e17, 1e7, allowedTokens, priceFeeds);
        vm.startPrank(USER_1);
        ERC20Mock(tokenUsed).approve(address(testPresale), STARTING_ERC20_BALANCE);
        testPresale.buy(tokenUsed, TOKEN_AMOUNT);
        vm.stopPrank();
        uint256 expectedBalance = testPresale.calculateTokensPrice(tokenUsed, TOKEN_AMOUNT);
        assertEq(ERC20Mock(tokenUsed).balanceOf(address(testPresale)), expectedBalance);
        vm.startPrank(OWNER);
        vm.warp(block.timestamp + 101 days);
        testPresale.withdrawToken(tokenUsed, OWNER);
        assertEq(ERC20Mock(tokenUsed).balanceOf(address(testPresale)), 0);
        assertEq(ERC20Mock(tokenUsed).balanceOf(OWNER), expectedBalance);
    }

    /* ===== public & external view Tests ===== */

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = presale.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }

    function testCalculateTokensPrice() public {
        uint256 expectedWeth = 0.00005 ether; // 1 token = 10c, 1 WETH = 2000$ -> 1 token = 0.00005 WETH
        uint256 actualWeth = presale.calculateTokensPrice(weth, 1 ether);
        assertEq(expectedWeth, actualWeth);
    }
    
    function testGetTokenSold() public {
        assertEq(presale.getTokenSold(), 0);
        vm.startPrank(USER_1);
        ERC20Mock(weth).approve(address(presale), STARTING_ERC20_BALANCE);
        presale.buy(weth, TOKEN_AMOUNT);
        vm.stopPrank();
        assertEq(presale.getTokenSold(), TOKEN_AMOUNT);
    }

    function testGetAllowedTokens() public {
        assertEq(presale.getAllowedTokens(), allowedTokens);
    }

    /* ===== const getters Tests ===== */

    function testGetPrecision() public {
        assertEq(presale.getPrecision(), 1e18);
    }

    function testGetAdditionalFeedPrecision() public {
        assertEq(presale.getAdditionalFeedPrecision(), 1e10);
    }

    /* ===== immutable getters Tests ===== */

    function testGetUnlockTimestamp() public {
        assertEq(presale.getUnlockTimestamp(), unlockTimestamp);
    }

    function testGetTokenPriceInUsd() public {
        assertEq(presale.getTokenPriceInUsd(), tokenPriceInUsd);
    }

    function testGetMaxSupply() public {
        assertEq(presale.getMaxSupply(), totalSupply * presale.getPrecision());
    }

    function testGetOwner() public {
        vm.startPrank(OWNER);
        Presale testPresale = new Presale(block.timestamp + 100 days, 1e17, 1e7, allowedTokens, priceFeeds);
        assertEq(testPresale.getOwner(), OWNER);
    }

    function testGetTokenUsdPriceFeed() public {
        assertEq(presale.getTokenUsdPriceFeed(weth), ethUsdPriceFeed);
        assertEq(presale.getTokenUsdPriceFeed(wbtc), btcUsdPriceFeed);
        assertEq(presale.getTokenUsdPriceFeed(dai), daiUsdPriceFeed);
        assertEq(presale.getTokenUsdPriceFeed(gho), ghoUsdPriceFeed);
    }
}
