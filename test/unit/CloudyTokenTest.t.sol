// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Cloudy} from "../../src/CloudyToken.sol";

contract CloudyTest is Test {
    Cloudy cloudy;
    address public OWNER = makeAddr("owner");
    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 1e7;

    function setUp() public {
        vm.prank(OWNER);
        cloudy = new Cloudy(INITIAL_SUPPLY);
    }

    function testMintRevertIfNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        cloudy.mint(USER, 100);
        vm.stopPrank();
    }

    function testBurnRevertIfNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        cloudy.burn(50);
        vm.stopPrank();
    }
}
