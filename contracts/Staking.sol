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
    function numberOfEndorcements(uint256 mE, uint256 eN) external view returns (uint256);
    function qualityOfStakes(uint256[] memory cr, uint256[] memory cd) external view returns (uint256);
}

contract Staking is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public stakingToken;
    address public equations;
    uint256 public MAX_ENDORCEMENTS = 10;
    uint256 public totalPools;

    struct UserPool {
        // uint256 amountDeposited;
        // mapping(address => uint256) stakerDepositedAmount;
        // // mapping(address => uint256) stakerQuality;
        // uint256 noOfStakers;
        // mapping(uint256 => address) stakers;
        uint256 totalStaked; // CD
        uint256 weightage0;
        uint256 weightage1;
        uint256 multiplier;
    }

    struct Pool {
        bool endorced;
        uint256 amountStaked; // CR
    }

    struct Staker {
        mapping(uint256 => Pool) pool;
        uint256 numberOfEndorcements;
    }

    mapping(address => Staker) staker;
    mapping(uint256 => UserPool) userPool;

    constructor(address _token, address _equations){
        stakingToken = _token;
        equations = _equations;
    }

    // TODO create only owner
    function createPool(uint256 _weightage0, uint256 _weightage1, uint256 _multiplier) public {
        uint256 currentPoolId = totalPools;

        userPool[currentPoolId].weightage0 = _weightage0;
        userPool[currentPoolId].weightage1 = _weightage1;
        userPool[currentPoolId].multiplier = _multiplier;

        totalPools++;
    }

    function staking() internal view returns (IERC20){
        return IERC20(stakingToken);
    }

    function stakeOnPool(uint256 _poolId, uint256 _amount) public nonReentrant{
        require(staking().balanceOf(msg.sender) > _amount, "!amount");

        Staker storage userData = staker[msg.sender];
        bool poolEndorced = userData.pool[_poolId].endorced;

        if(!poolEndorced){
            poolEndorced = true;
            userData.numberOfEndorcements++;
        }

        userData.pool[_poolId].amountStaked += _amount;

        UserPool storage userPoolData = userPool[_poolId];

        userPoolData.totalStaked += _amount;

        staking().safeTransferFrom(msg.sender, address(this), _amount);

        // Pool storage selectedPool = pool[_pool];

        // selectedPool.amountDeposited += _amount;
        // selectedPool.stakerDepositedAmount[msg.sender] += _amount;
    }

    function getNumberOfEndorcements() public view returns (uint256 NE_){
        uint256 userEndorcementCount = staker[msg.sender].numberOfEndorcements;
        NE_ = IEquations(equations).numberOfEndorcements(MAX_ENDORCEMENTS, userEndorcementCount);
    }

    function getQualityOfStakes() public view returns (uint256 QS_) {
        Staker storage userData = staker[msg.sender];
        uint256[] memory cr = new uint256[](totalPools);

        for(uint256 i = 0; i < totalPools; ++i){
            cr[i] = userData.pool[i].amountStaked;
        }

        uint256[] memory cd = new uint256[](totalPools);

        for(uint256 i = 0; i < totalPools; ++i){
            cd[i] = userPool[i].totalStaked;
        }

        QS_ = IEquations(equations).qualityOfStakes(cr, cd);
    }

    // function withdrawStakeOnPool(uint256 _pool, uint256 _amount) public nonReentrant {
    //     Pool storage selectedPool = pool[_pool];
    //     uint256 balance = selectedPool.stakerDepositedAmount[msg.sender];

    //     require(balance > _amount, "!balance");

    //     selectedPool.amountDeposited -= _amount;
    //     selectedPool.stakerDepositedAmount[msg.sender] -= _amount;

    //     staking().safeTransfer(msg.sender, _amount);

    //     // TODO get all of the users in a particular pool
    //     // uint256 rewards = IEquations(equations).rewardPerUser(m, MR, weightage0, weightage1, staker);

    //     // TODO then reward tokens are transffered from where?
    // }


}