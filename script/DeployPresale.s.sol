// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Presale} from "../src/Presale.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployPresale is Script {
    address[] public tokenAddress;
    address[] public tokenPriceFeedAddress;

    function run() external returns (Presale, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (
            address wethUsdPriceFeed,
            address wbtcUsdPriceFeed,
            address daiUsdPriceFeed,
            address ghoUsdPriceFeed,
            address weth,
            address wbtc,
            address dai,
            address gho,
            uint256 tokenPriceInUsd,
            uint256 totalSupply,
            uint256 unlockTimestamp,
            uint256 deployerKey
        ) = config.activeNetworkConfig();

        tokenAddress = [weth, wbtc, dai, gho];
        tokenPriceFeedAddress = [wethUsdPriceFeed, wbtcUsdPriceFeed, daiUsdPriceFeed, ghoUsdPriceFeed];

        vm.startBroadcast(deployerKey);
        Presale presale = new Presale(
            unlockTimestamp,
            tokenPriceInUsd,
            totalSupply,
            tokenAddress,
            tokenPriceFeedAddress
        );
        vm.stopBroadcast();

        return (presale, config);
    }
}
