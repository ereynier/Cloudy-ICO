// Invariants:
// Getter view should never revert

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test, console} from "forge-std/Test.sol";
import {Presale} from "../../src/Presale.sol";
import {Cloudy} from "../../src/CloudyToken.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployPresale} from "../../script/DeployPresale.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {

    Presale public presale;
    HelperConfig public config;
    DeployPresale deployer;
    Cloudy cloudy;

    Handler handler;

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

    function setUp() external {
        deployer = new DeployPresale();
        (presale, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, daiUsdPriceFeed, ghoUsdPriceFeed, weth, wbtc, dai, gho,tokenPriceInUsd, totalSupply, unlockTimestamp, ) =
            config.activeNetworkConfig();
        cloudy = presale.getToken();
        handler = new Handler(presale, config);
        vm.deal(address(handler), 100 ether);
        // give handler all tokens

        targetContract(address(handler));
    }

    function invariant_UserBalancesShouldAlwaysBeLessOrEqualToMaxSupply() public {
        uint256 userSupply;
        // for each handler count supply
        userSupply = cloudy.balanceOf(address(handler)) + presale.getBalance(address(handler));

        assertGe(presale.getMaxSupply(), userSupply);
        assertEq(presale.getTokenSold(), userSupply);
        console.log("User Supply ", userSupply);
        console.log("Token sold ", presale.getTokenSold());
    }

    function invariant_gettersShouldNotRevert() public view {
        // presale.getTokenAmountFromUsd(); // need token address + uint
        // presale.calculateTokensPrice(); // need token address + uint
        presale.getTokenSold();
        presale.getAllowedTokens();
        // presale.getBalance(); // need user
        presale.getPrecision();
        presale.getAdditionalFeedPrecision();
        presale.getTokenAddress();
        presale.getToken();
        presale.getUnlockTimestamp();
        presale.getTokenPriceInUsd();
        presale.getMaxSupply();
        presale.getOwner();
        // presale.getTokenUsdPriceFeed(); // need token address
    }

}