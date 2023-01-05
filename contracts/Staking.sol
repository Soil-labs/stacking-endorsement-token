// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IEquations {
    struct MaxRewards {
        NoOfEndorcements NE;
        QualityOfStakes QS;
        uint256 stakeAmount;
        uint256 qualityStaker;
    }

    struct NoOfEndorcements {
        uint256 mE;
        uint256 eN;
    }

    struct QualityOfStakes {
        uint256[] cr;
        uint256[] cd;
    }

    function rewardPerUser(uint256 maxRewards, MaxRewards[] memory MR, MaxRewards memory staker) external view returns (uint256);
    function numberOfEndorcements(uint256 mE, uint256 eN) external view returns (uint256);
    function qualityOfStakes(uint256[] memory cr, uint256[] memory cd) external view returns (uint256);
    function qualityOfStaker(uint256 weightage0, uint256 weightage1, NoOfEndorcements memory NE, QualityOfStakes memory QS) external view returns (uint256);
    function getMaxRewards(uint256 m, MaxRewards[] memory MR, uint256 _availRewards) external view returns (uint256);
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

        uint256 noOfUsersStaked;
        address[] usersStaked;
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

        UserPool storage userPoolData = userPool[_poolId];

        if(!poolEndorced){
            poolEndorced = true;
            userData.numberOfEndorcements++;

            userPoolData.usersStaked[userPoolData.noOfUsersStaked] = msg.sender;
            userPoolData.noOfUsersStaked++;
        }

        userData.pool[_poolId].amountStaked += _amount;

        userPoolData.totalStaked += _amount;

        staking().safeTransferFrom(msg.sender, address(this), _amount);
    }

    function _getNumberOfEndorcements(address _sender) internal view returns (uint256 NE_){
        uint256 userEndorcementCount = staker[_sender].numberOfEndorcements;
        NE_ = IEquations(equations).numberOfEndorcements(MAX_ENDORCEMENTS, userEndorcementCount);
    }

    function _getQualityOfStakes(address _sender) internal view returns (uint256 QS_) {
        Staker storage userData = staker[_sender];
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

    // TODO: create external versions of these 2 functions

    // function _getNumberOfEndorcements(address _sender) internal view returns (uint256 NE_){
    //     uint256 userEndorcementCount = staker[_sender].numberOfEndorcements;
    //     NE_ = IEquations(equations).numberOfEndorcements(MAX_ENDORCEMENTS, userEndorcementCount);
    // }

    // function _getQualityOfStakes(address _sender) internal view returns (uint256 QS_) {
    //     Staker storage userData = staker[_sender];
    //     uint256[] memory cr = new uint256[](totalPools);

    //     for(uint256 i = 0; i < totalPools; ++i){
    //         cr[i] = userData.pool[i].amountStaked;
    //     }

    //     uint256[] memory cd = new uint256[](totalPools);

    //     for(uint256 i = 0; i < totalPools; ++i){
    //         cd[i] = userPool[i].totalStaked;
    //     }

    //     QS_ = IEquations(equations).qualityOfStakes(cr, cd);
    // }

    function _getQualityOfStaker(uint256 _poolId, address _user) internal view returns (uint256 qualityOfStaker_) {
        IEquations.NoOfEndorcements memory NE;
        NE.mE = MAX_ENDORCEMENTS;
        NE.eN = staker[_user].numberOfEndorcements;

        IEquations.QualityOfStakes memory QS;

        Staker storage userData = staker[_user];

        uint256[] memory cr = new uint256[](totalPools);
        uint256[] memory cd = new uint256[](totalPools);

        for(uint256 j = 0; j < totalPools; ++j){
            cr[j] = userData.pool[j].amountStaked;
            cd[j] = userPool[j].totalStaked;

        }

        QS.cr = cr;
        QS.cd = cd;

        qualityOfStaker_ = IEquations(equations).qualityOfStaker(userPool[_poolId].weightage0, userPool[_poolId].weightage1, NE, QS);
    }

    function getQualityOfStaker(uint256 _poolId) public view returns (uint256 qualityOfStaker_) {
        IEquations.NoOfEndorcements memory NE;
        NE.mE = MAX_ENDORCEMENTS;
        NE.eN = staker[msg.sender].numberOfEndorcements;

        IEquations.QualityOfStakes memory QS;

        Staker storage userData = staker[msg.sender];

        uint256[] memory cr = new uint256[](totalPools);
        uint256[] memory cd = new uint256[](totalPools);

        for(uint256 j = 0; j < totalPools; ++j){
            cr[j] = userData.pool[j].amountStaked;
            cd[j] = userPool[j].totalStaked;

        }

        QS.cr = cr;
        QS.cd = cd;

        qualityOfStaker_ = IEquations(equations).qualityOfStaker(userPool[_poolId].weightage0, userPool[_poolId].weightage1, NE, QS);
    }

    function _getMaxRewards(uint256 _poolId) internal view returns (IEquations.MaxRewards[] memory MR_) {
        IEquations.MaxRewards[] memory MR;

        UserPool storage userPoolData = userPool[_poolId];
        uint256 noOfStakers = userPoolData.noOfUsersStaked;

        for(uint256 i = 0; i < noOfStakers; ++i){
            address user = userPoolData.usersStaked[i];
            MR[i] = getStakerStruct(_poolId, user);
        }

        MR_ = MR;
    }

    function getMaxRewards(uint256 _poolId, uint256 _availableRewards) public view returns (uint256 maxRewards_) {
        IEquations.MaxRewards[] memory MR;

        UserPool storage userPoolData = userPool[_poolId];
        uint256 noOfStakers = userPoolData.noOfUsersStaked;
        uint256 multiplier = userPoolData.multiplier;

        for(uint256 i = 0; i < noOfStakers; ++i){
            address user = userPoolData.usersStaked[i];
            
            MR[i] = getStakerStruct(_poolId, user);
        }

        maxRewards_ = IEquations(equations).getMaxRewards(multiplier, MR, _availableRewards);
    }

    function getStakerStruct(uint256 _poolId, address _user) internal view returns (IEquations.MaxRewards memory MR_){
        IEquations.MaxRewards memory MR;

        IEquations.NoOfEndorcements memory NE;
        NE.mE = MAX_ENDORCEMENTS;
        NE.eN = staker[_user].numberOfEndorcements;

        IEquations.QualityOfStakes memory QS;

        Staker storage userData = staker[_user];

        uint256[] memory cr = new uint256[](totalPools);
        uint256[] memory cd = new uint256[](totalPools);

        for(uint256 j = 0; j < totalPools; ++j){
            cr[j] = userData.pool[j].amountStaked;
            cd[j] = userPool[j].totalStaked;

        }

        QS.cr = cr;
        QS.cd = cd;
    
        uint256 stakeAmount = userData.pool[_poolId].amountStaked;

        uint256 qualityStaker = _getQualityOfStaker(_poolId, _user);

        MR.NE = NE;
        MR.QS = QS;
        MR.stakeAmount = stakeAmount;
        MR.qualityStaker = qualityStaker;

        MR_ = MR;
    }

    function getRewardPerUser(uint256 _poolId, uint256 _availableRewards) public view returns (uint256 rewards_) {
        uint256 maxRewards = getMaxRewards(_poolId, _availableRewards);

        IEquations.MaxRewards[] memory MR = _getMaxRewards(_poolId);

        IEquations.MaxRewards memory stakerValue = getStakerStruct(_poolId, msg.sender);

        rewards_ = IEquations(equations).rewardPerUser(maxRewards, MR, stakerValue);
    }

    function getRewardPerUser2(uint256 _poolId, uint256 _availableRewards) public view returns (uint256 rewards_) {
        uint256 maxRewards = getMaxRewards(_poolId, _availableRewards);

        IEquations.MaxRewards[] memory MR = _getMaxRewards(_poolId);

        IEquations.MaxRewards memory stakerValue;

        IEquations.NoOfEndorcements memory NE;
        NE.mE = MAX_ENDORCEMENTS;
        NE.eN = staker[msg.sender].numberOfEndorcements;

        IEquations.QualityOfStakes memory QS;

        Staker storage userData = staker[msg.sender];

        uint256[] memory cr = new uint256[](totalPools);
        uint256[] memory cd = new uint256[](totalPools);

        for(uint256 j = 0; j < totalPools; ++j){
            cr[j] = userData.pool[j].amountStaked;
            cd[j] = userPool[j].totalStaked;

        }

        QS.cr = cr;
        QS.cd = cd;
    
        uint256 stakeAmount = userData.pool[_poolId].amountStaked;

        uint256 qualityStaker = _getQualityOfStaker(_poolId, msg.sender);

        stakerValue.NE = NE;
        stakerValue.QS = QS;
        stakerValue.stakeAmount = stakeAmount;
        stakerValue.qualityStaker = qualityStaker;

        rewards_ = IEquations(equations).rewardPerUser(maxRewards, MR, stakerValue);
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