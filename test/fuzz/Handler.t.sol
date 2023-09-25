// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Presale} from "../../src/Presale.sol";
import {Cloudy} from "../../src/CloudyToken.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

contract Handler is Test {
    Presale private presale;
    HelperConfig private config;

    address weth;
    address wbtc;
    address dai;
    address gho;
    address[] public allowedToken;

    constructor(Presale _presale, HelperConfig _config) {
        presale = _presale;
        config = _config;

        (,,,, weth, wbtc, dai, gho,,,,) = config.activeNetworkConfig();
        allowedToken.push(weth);
        allowedToken.push(wbtc);
        allowedToken.push(dai);
        allowedToken.push(gho);
    }

    function buy(address token, uint256 buyAmount) external {
        buyAmount = bound(buyAmount, 0, presale.getMaxSupply() - presale.getTokenSold());
        if (buyAmount == 0) {
            return;
        }
        if (block.timestamp >= presale.getUnlockTimestamp()) {
            return;
        }
        token = _getAllowedTokenFromSeed(uint256(uint160(token)));

        ERC20Mock tokenMock = ERC20Mock(token);

        tokenMock.mint(address(this), presale.calculateTokensPrice(token, buyAmount));
        tokenMock.approve(address(presale), presale.calculateTokensPrice(token, buyAmount));
        presale.buy(token, buyAmount);

    }

    function withdraw() external {
        if (block.timestamp < presale.getUnlockTimestamp()) {
            return;
        }

        presale.withdraw();

    }

    function burnRemaining() external {
        if (block.timestamp < presale.getUnlockTimestamp()) {
            return;
        }

        presale.burnRemaining();

    }

    function withdrawToken(address token, address to) external {
        if (address(msg.sender) != address(presale.getOwner())) {
            return;
        }
        if (block.timestamp < presale.getUnlockTimestamp()) {
            return;
        }
        token = _getAllowedTokenFromSeed(uint256(uint160(token)));

        presale.withdrawToken(token, to);

    }

    /* ===== Helper Functions ===== */

    // function updateCollateralPrice(uint96 newPrice, address token) public {
    //     newPrice = uint96(bound(newPrice, 1, type(uint96).max));
    //     int256 newPriceInt = int256(uint(newPrice));
    //     token = _getAllowedTokenFromSeed(uint256(uint160(token)));
    //     MockV3Aggregator tokenUsdPriceFeed = MockV3Aggregator(presale.getTokenUsdPriceFeed(address(token)));
    //     tokenUsdPriceFeed.updateAnswer(newPriceInt);
    // }

    // function updateTimestamp() public {
    //     vm.warp(block.timestamp + 22000);
    // }

    function _getAllowedTokenFromSeed(uint256 collateralSeed) private view returns (address) {
        uint256 randomSeed = collateralSeed % allowedToken.length;
        return allowedToken[randomSeed];
    }
}
