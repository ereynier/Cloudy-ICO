// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address daiUsdPriceFeed;
        address ghoUsdPriceFeed;
        address weth;
        address wbtc;
        address dai;
        address gho;
        uint256 tokenPriceInUsd;
        uint256 totalSupply;
        uint256 unlockTimestamp;
        uint256 deployerKey;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 30000e8;
    int256 public constant DAI_USD_PRICE = 11e7;
    int256 public constant GHO_USD_PRICE = 99e6;
    uint256 public DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            daiUsdPriceFeed: 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19,
            ghoUsdPriceFeed: 0x635A86F9fdD16Ff09A0701C305D3a845F1758b8E,
            weth: 0xD0dF82dE051244f04BfF3A8bB1f62E1cD39eED92,
            wbtc: 0xf864F011C5A97fD8Da79baEd78ba77b47112935a,
            dai: 0x53844F9577C2334e541Aec7Df7174ECe5dF1fCf0,
            gho: 0x5d00fab5f2F97C4D682C1053cDCAA59c2c37900D,
            tokenPriceInUsd: 1e17,
            totalSupply: 1e7,
            unlockTimestamp: block.timestamp + 100 days,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ERC20Mock wethMock = new ERC20Mock();
        wethMock.mint(msg.sender, 1000e8);
        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
        ERC20Mock wbtcMock = new ERC20Mock();
        wbtcMock.mint(msg.sender, 1000e8);
        MockV3Aggregator daiUsdPriceFeed = new MockV3Aggregator(DECIMALS, DAI_USD_PRICE);
        ERC20Mock daiMock = new ERC20Mock();
        daiMock.mint(msg.sender, 1000e8);
        MockV3Aggregator ghoUsdPriceFeed = new MockV3Aggregator(DECIMALS, GHO_USD_PRICE);
        ERC20Mock ghoMock = new ERC20Mock();
        ghoMock.mint(msg.sender, 1000e8);
        vm.stopBroadcast();

        return NetworkConfig({
            wethUsdPriceFeed: address(ethUsdPriceFeed),
            wbtcUsdPriceFeed: address(btcUsdPriceFeed),
            daiUsdPriceFeed: address(daiUsdPriceFeed),
            ghoUsdPriceFeed: address(ghoUsdPriceFeed),
            weth: address(wethMock),
            wbtc: address(wbtcMock),
            dai: address(daiMock),
            gho: address(ghoMock),
            tokenPriceInUsd: 1e17,
            totalSupply: 1e7,
            unlockTimestamp: block.timestamp + 100 days,
            deployerKey: DEFAULT_ANVIL_KEY
        });
    }
}
