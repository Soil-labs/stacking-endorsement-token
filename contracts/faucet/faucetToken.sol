// SPDX-License-Identifier: BUSL 1.1

pragma solidity 0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FaucetToken is ERC20, Ownable {
    uint8 public tokenDecimals;
    address public faucet;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _faucet
    ) ERC20(_name, _symbol) {
        tokenDecimals = _decimals;
        faucet = _faucet;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function mintFaucet(address _to, uint256 _amount) external onlyFaucet {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }

    modifier onlyFaucet() {
        _checkFaucet();
        _;
    }

    function _checkFaucet() internal view {
        require(faucet == msg.sender, "!faucet");
    }

    function setFaucet(address _faucet) external onlyOwner {
        faucet = _faucet;
    }
}
