// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Escrow is Ownable {
    address public staking;
    address public trustToken;
    using SafeERC20 for IERC20;

    constructor(
        address _staking,
        address _trust
    ){
        staking = _staking;
        trustToken = _trust;
    }

    function transferFunds(address _staker, uint256 _amount) external {
        require(msg.sender == staking, "!Staking");

        _trustToken().safeTransfer(_staker, _amount);
    }

    function _trustToken() internal view returns (IERC20){
        return IERC20(trustToken);
    }
}
