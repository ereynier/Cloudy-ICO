// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Cloudy is ERC20Burnable, Ownable {

    error Cloudy__MustBeMoreThanZero();
    error Cloudy__BurnAmountExceedsBalance();
    error Cloudy__NotZeroAddress();

    constructor(uint256 _maxSupply) ERC20("Cloudy", "CDY") {
        _mint(msg.sender, _maxSupply * 10 ** decimals());
    }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert Cloudy__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert Cloudy__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert Cloudy__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert Cloudy__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return (true);
    }
    
}
