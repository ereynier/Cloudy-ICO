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
import {ActorManager} from "./ActorManager.s.sol";

contract MultiHandlerInvariantsTest is StdInvariant, Test {
    Presale public presale;
    HelperConfig public config;
    DeployPresale deployer;
    Cloudy cloudy;

    ActorManager manager;
    Handler[] public handlers;

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
        (
            ethUsdPriceFeed,
            btcUsdPriceFeed,
            daiUsdPriceFeed,
            ghoUsdPriceFeed,
            weth,
            wbtc,
            dai,
            gho,
            tokenPriceInUsd,
            totalSupply,
            unlockTimestamp,
        ) = config.activeNetworkConfig();
        cloudy = presale.getToken();

        for (uint256 i = 0; i < 3; i++) {
            handlers.push(new Handler(presale, config));
            vm.deal(address(handlers[i]), 100 ether);
        }

        manager = new ActorManager(handlers);
        targetContract(address(manager));
    }

    function invariant_UsersBalancesShouldAlwaysBeLessOrEqualToMaxSupply() public {
        uint256 userSupply = 0;
        // for each handler count supply
        for (uint256 i = 0; i < handlers.length; i++) {
            userSupply += cloudy.balanceOf(address(handlers[i])) + presale.getBalance(address(handlers[i]));
        }
        assertGe(presale.getMaxSupply(), userSupply);
        assertEq(presale.getTokenSold(), userSupply);
        console.log("User Supply ", userSupply);
        console.log("Token sold ", presale.getTokenSold());
    }
}
