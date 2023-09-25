// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Test} from "forge-std/Test.sol";
import {Presale} from "../../src/Presale.sol";
import {Cloudy} from "../../src/CloudyToken.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Handler} from "./Handler.t.sol";

contract ActorManager is CommonBase, StdCheats, StdUtils {
    Handler[] public handlers;

    constructor(Handler[] memory _handlers) {
        handlers = _handlers;
    }

    function buy(uint256 handlerIndex, address token, uint256 buyAmount) external {
        handlerIndex = bound(handlerIndex, 0, handlers.length - 1);
        handlers[handlerIndex].buy(token, buyAmount);
    }

    function withdraw(uint256 handlerIndex) external {
        handlerIndex = bound(handlerIndex, 0, handlers.length - 1);
        handlers[handlerIndex].withdraw();
    }

    function burnRemaining(uint256 handlerIndex) external {
        handlerIndex = bound(handlerIndex, 0, handlers.length - 1);
        handlers[handlerIndex].burnRemaining();
    }

    function withdrawToken(uint256 handlerIndex, address token, address to) external {
        handlerIndex = bound(handlerIndex, 0, handlers.length - 1);
        handlers[handlerIndex].withdrawToken(token, to);
    }

    /* ===== Helper Functions ===== */

    // function updateCollateralPrice(uint256 handlerIndex, uint96 newPrice, address token) public {
    //     handlerIndex = bound(handlerIndex, 0, handlers.length - 1);
    //     handlers[handlerIndex].updateCollateralPrice(newPrice, token);
    // }

    // function updateTimestamp(uint256 handlerIndex) public {
    //     handlerIndex = bound(handlerIndex, 0, handlers.length - 1);
    //     handlers[handlerIndex].updateTimestamp();
    // }
}
