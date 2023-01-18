// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Trust is ERC20, Ownable {
    uint8 tokenDecimals;
    address public faucet;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        // Intentionally left blank
        tokenDecimals = _decimals;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }
}
