// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IEquations {
    struct StakerValue {
        NoOfEndorcements NE;
        QualityOfStakes QS;
        uint256 stakeAmount;
    }

    struct MaxRewards {
        NoOfEndorcements NE;
        QualityOfStakes QS;
        uint256 stakeAmount;
    }

    struct NoOfEndorcements {
        uint256 v;
        uint256 mE;
        uint256 eN;
    }

    struct QualityOfStakes {
        uint256[] cr;
        uint256[] cd;
    }
    function rewardPerUser(uint256 m, MaxRewards[] memory MR, uint256 weightage0, uint256 weightage1, StakerValue memory staker) external view returns (uint256);
}

contract Staking is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public stakingToken;
    address public equations;

    struct Pool {
        uint256 amountDeposited;
        mapping(address => uint256) stakerDepositedAmount;
    }

    mapping(uint256 => Pool) pool;

    constructor(address _token, address _equations){
        stakingToken = _token;
        equations = _equations;
    }

    function staking() internal view returns (IERC20){
        return IERC20(stakingToken);
    }
    function stakeOnPool(uint256 _pool, uint256 _amount) public nonReentrant{
        require(staking().balanceOf(msg.sender) > _amount, "!amount");

        staking().safeTransferFrom(msg.sender, address(this), _amount);

        Pool storage selectedPool = pool[_pool];

        selectedPool.amountDeposited += _amount;
        selectedPool.stakerDepositedAmount[msg.sender] += _amount;
    }

    function withdrawStakeOnPool(uint256 _pool, uint256 _amount) public nonReentrant {
        Pool storage selectedPool = pool[_pool];
        uint256 balance = selectedPool.stakerDepositedAmount[msg.sender];

        require(balance > _amount, "!balance");

        selectedPool.amountDeposited -= _amount;
        selectedPool.stakerDepositedAmount[msg.sender] -= _amount;

        staking().safeTransfer(msg.sender, _amount);

        // TODO get all of the users in a particular pool
        // uint256 rewards = IEquations(equations).rewardPerUser(m, MR, weightage0, weightage1, staker);

        // TODO then reward tokens are transffered from where?
    }


}