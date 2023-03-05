// SPDX-License-Identifier: BUSL 1.1

pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStandardToken {
    function mintFaucet(address _to, uint256 _amount) external;
}

contract TokenFaucet is Ownable {

    // State variable to keep track amount of ETHER to dispense
    uint public amountAllowed = 1000000000000000000;

    // Mapping to keep track of requested rokens
    // Address and blocktime + 1 day is saved in TimeLock
    mapping(address => uint) public lockTime;
    IERC20 public token;

    constructor(address _token){
        token = IERC20(_token);
    }

    // Function to set the amount allowable to be claimed. Only the owner can call this function
    function setAmountallowed(uint newAmountAllowed) external onlyOwner {
        amountAllowed = newAmountAllowed;
    }

    // Function to send tokens from faucet to an address
    function requestTokens(address _requestor) public {

        // Perform a few checks to make sure function can execute
        require(block.timestamp > lockTime[msg.sender], "lock time has not expired. Please try again later");

        IStandardToken(address(token)).mintFaucet(_requestor, amountAllowed);

        // Updates locktime 1 day from now
        lockTime[msg.sender] = block.timestamp + 1 days;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));

        token.transfer(owner(), balance);
    }

}