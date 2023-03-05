// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IEquations {
    struct NoOfEndorcements {
        uint256 mE;
        uint256 eN;
    }

    struct QualityOfStakes {
        uint256[] cr;
        uint256[] cd;
    }

    struct MaxRewards {
        NoOfEndorcements NE;
        QualityOfStakes QS;
        uint256 stakeAmount;
        uint256 qualityStaker;
    }

    function rewardPerUser(uint256 maxRewards, MaxRewards[] memory MR, MaxRewards memory staker) external view returns (uint256);
    function numberOfEndorcements(uint256 mE, uint256 eN) external view returns (uint256);
    function qualityOfStakes(uint256[] memory cr, uint256[] memory cd) external view returns (uint256);
    function qualityOfStaker(uint256 weightage0, uint256 weightage1, NoOfEndorcements memory NE, QualityOfStakes memory QS) external view returns (uint256);
    function getMaxRewards(uint256 m, MaxRewards[] memory MR, uint256 _availRewards) external view returns (uint256);
}

interface IEscrow {
    function transferFunds(address _staker, uint256 _amount) external;
}

contract Staking is Ownable {
    using SafeERC20 for IERC20;

    address public stakingToken;
    address public equations;
    uint256 public MAX_ENDORCEMENTS = 10;
    uint256 public totalPools;
    uint256 public immutable penalty = 5000; // in basis points so 5000 = 50%

    struct UserPool {
        bool jobStatus;
        uint256 availableRewards;

        uint256 totalStaked; // CD
        uint256 weightage0;
        uint256 weightage1;
        uint256 multiplier;

        uint256 noOfUsersStaked;
        mapping(uint256 => address) usersStaked;

        address user;
        address escrow;
    }

    struct Pool {
        bool endorced;
        address poolUser;
        uint256 amountStaked; // CR
        bool claimed;
    }

    struct Staker {
        mapping(uint256 => Pool) pool;
        uint256 numberOfEndorcements;
        uint[] poolsStaked;
    }

    mapping(address => Staker) public staker;
    mapping(uint256 => UserPool) public userPool;

    constructor(
        address _token,
        address _equations
    ) {
        stakingToken = _token;
        equations = _equations;
    }

    // EXTERNAL FUNCTIONS

    function createPool(
        uint256 _weightage0,
        uint256 _weightage1,
        uint256 _multiplier,
        address _user,
        address _escrow
    ) external onlyOwner {
        uint256 currentPoolId = totalPools;

        userPool[currentPoolId].weightage0 = _weightage0;
        userPool[currentPoolId].weightage1 = _weightage1;
        userPool[currentPoolId].multiplier = _multiplier;
        userPool[currentPoolId].user = _user;
        userPool[currentPoolId].escrow = _escrow;
        userPool[currentPoolId].availableRewards = 1 ether; // currently hardcoded

        totalPools++;
    }

    function stakeOnPool(
        uint256 _poolId,
        uint256 _amount
    ) external {
        require(_staking().balanceOf(msg.sender) > _amount, "!amount");

        Staker storage userData = staker[msg.sender];
        bool poolEndorced = userData.pool[_poolId].endorced;

        UserPool storage userPoolData = userPool[_poolId];

        if(!poolEndorced){
            poolEndorced = true;
            userData.numberOfEndorcements++;
            userData.poolsStaked.push(_poolId);

            userPoolData.usersStaked[userPoolData.noOfUsersStaked] = msg.sender;

            userData.pool[_poolId].poolUser = userPoolData.user;

            userPoolData.noOfUsersStaked++;
        }

        userData.pool[_poolId].amountStaked += _amount;

        userPoolData.totalStaked += _amount;

        _staking().safeTransferFrom(msg.sender, address(this), _amount);
    }

    function updateJobStatus(uint256 _poolId, bool _status) external onlyOwner {
        UserPool storage userPoolData = userPool[_poolId];

        userPoolData.jobStatus = _status;
    }

    function unstakeFromPool(uint256 _poolId, uint256 _amount) external {
        Staker storage userData = staker[msg.sender];

        uint256 stakedAmount = userData.pool[_poolId].amountStaked;

        userData.pool[_poolId].amountStaked -= _amount;
        
        require(_amount <= stakedAmount, "!stakedAmount");

        uint256 penalizedAmount = (_amount * penalty) / 10_000; // calculated with basis points

        _staking().safeTransfer(msg.sender, _amount - penalizedAmount);
    }

    // TODO: staker total reward to be claimed
    function claimRewardsFromPool(
        uint256 _poolId
    ) external {
        UserPool storage userPoolData = userPool[_poolId];

        bool jobStatus = userPoolData.jobStatus;

        uint256 availableRewards = userPoolData.availableRewards;

        require(jobStatus == true, "!Completed");

        uint256 rewards = getRewardPerUser(_poolId, availableRewards, msg.sender);

        address escrow = userPoolData.escrow;

        require(escrow != address(0), "!Escrow");
        require(rewards >= 0, "!Reward");

        IEscrow(escrow).transferFunds(msg.sender, rewards);
    }

    function getPoolData(
        uint256 _poolId
    ) external view returns (
        uint256 totalStaked_,
        uint256 weightage0_,
        uint256 weigthage1_,
        uint256 multiplier_,
        uint256 noOfUsersStaked_,
        address user_,
        address[] memory usersStaked_
    ){
        UserPool storage pool = userPool[_poolId];

        totalStaked_ = pool.totalStaked;
        weightage0_ = pool.weightage0;
        weigthage1_ = pool.weightage1;
        multiplier_ = pool.multiplier;
        noOfUsersStaked_ = pool.noOfUsersStaked;
        user_ = pool.user;

        address[] memory staked = new address[](pool.noOfUsersStaked);

        for(uint256 i = 0; i < pool.noOfUsersStaked; ++i){
            staked[i] = pool.usersStaked[i];
        }

        usersStaked_ = staked;
    }

    function getStakerData(
        address _staker
    ) external view returns (
        uint256 numberOfEndorcements_,
        Pool[] memory pools,
        uint256[] memory poolIds
    ){
        Staker storage stakerData = staker[_staker];

        numberOfEndorcements_ = stakerData.numberOfEndorcements;

        poolIds = stakerData.poolsStaked;

        Pool[] memory myPools = new Pool[](stakerData.poolsStaked.length);

        for(uint i = 0; i < stakerData.poolsStaked.length; ++i){
            myPools[i] = (stakerData.pool[stakerData.poolsStaked[i]]);
        }

        pools = myPools;
    }

    function getNumberOfEndorcements(
        address _staker
    ) external view returns (
        uint256 NE_
    ){
        NE_ = _getNumberOfEndorcements(_staker);
    }

    function getQualityOfStakes(
        address _sender
    ) external view returns (
        uint256 QS_
    ){
        Staker storage userData = staker[_sender];
        uint256[] memory cr = new uint256[](userData.poolsStaked.length);

        for(uint256 i = 0; i < userData.poolsStaked.length; ++i){
            cr[i] = userData.pool[i].amountStaked;
        }

        uint256[] memory cd = new uint256[](userData.poolsStaked.length);

        for(uint256 i = 0; i < userData.poolsStaked.length; ++i){
            cd[i] = userPool[i].totalStaked;
        }

        QS_ = IEquations(equations).qualityOfStakes(cr, cd);
    }

    // PUBLIC FUNCTIONS

    function getQualityOfStaker(
        uint256 _poolId,
        address _user
    ) public view returns (
        uint256 qualityOfStaker_
    ){
        qualityOfStaker_ = _getQualityOfStaker(_poolId, _user);
    }

    function getMaxRewards(
        uint256 _poolId,
        uint256 _availableRewards
    ) public view returns (
        uint256 maxRewards_
    ) {
        IEquations.MaxRewards[] memory MR;
        uint256 multiplier;
        (MR, multiplier) = _getMaxRewardsStruct(_poolId);

        maxRewards_ = IEquations(equations).getMaxRewards(multiplier, MR, _availableRewards);
    }

    function getRewardPerUser(
        uint256 _poolId,
        uint256 _availableRewards,
        address _staker
    ) public view returns (
        uint256 rewards_
    ){
        uint256 maxRewards = getMaxRewards(_poolId, _availableRewards);
        IEquations.MaxRewards[] memory MR;
        (MR,) = _getMaxRewardsStruct(_poolId);
        IEquations.MaxRewards memory stakerValue = _getStakerStruct(_poolId, _staker);
        rewards_ = IEquations(equations).rewardPerUser(maxRewards, MR, stakerValue);
    }

    // INTERNAL FUNCTIONS

    function _staking() internal view returns (IERC20){
        return IERC20(stakingToken);
    }

    function _getNumberOfEndorcements(address _staker) internal view returns (uint256 NE_){
        uint256 userEndorcementCount = staker[_staker].numberOfEndorcements;
        NE_ = IEquations(equations).numberOfEndorcements(MAX_ENDORCEMENTS, userEndorcementCount);
    }

    function _getQualityOfStaker(
        uint256 _poolId,
        address _user
    ) internal view returns (
        uint256 qualityOfStaker_
    ){
        IEquations.NoOfEndorcements memory NE;
        NE.mE = MAX_ENDORCEMENTS;
        NE.eN = staker[_user].numberOfEndorcements;

        IEquations.QualityOfStakes memory QS;

        Staker storage userData = staker[_user];

        uint256[] memory cr = new uint256[](userData.poolsStaked.length);
        uint256[] memory cd = new uint256[](userData.poolsStaked.length);

        for(uint256 j = 0; j < userData.poolsStaked.length; ++j){
            cr[j] = userData.pool[j].amountStaked;
            cd[j] = userPool[j].totalStaked;

        }

        QS.cr = cr;
        QS.cd = cd;

        qualityOfStaker_ = IEquations(equations).qualityOfStaker(userPool[_poolId].weightage0, userPool[_poolId].weightage1, NE, QS);
    }

    function _getMaxRewardsStruct(
        uint256 _poolId
    ) internal view returns (
        IEquations.MaxRewards[] memory MR_,
        uint256 multiplier_
    ){
        UserPool storage userPoolData = userPool[_poolId];
        uint256 noOfStakers = userPoolData.noOfUsersStaked;

        IEquations.MaxRewards[] memory MR = new IEquations.MaxRewards[](noOfStakers);

        for(uint256 i = 0; i < noOfStakers; ++i){
            address user = userPoolData.usersStaked[i];
            MR[i] = _getStakerStruct(_poolId, user);
        }

        MR_ = MR;
        multiplier_ = userPoolData.multiplier;
    }

    function _getStakerStruct(
        uint256 _poolId,
        address _user
    ) internal view returns (
        IEquations.MaxRewards memory MR_
    ){
        IEquations.MaxRewards memory MR;

        IEquations.NoOfEndorcements memory NE;
        NE.mE = MAX_ENDORCEMENTS;
        NE.eN = staker[_user].numberOfEndorcements;

        IEquations.QualityOfStakes memory QS;

        Staker storage userData = staker[_user];

        uint256[] memory cr = new uint256[](userData.poolsStaked.length);
        uint256[] memory cd = new uint256[](userData.poolsStaked.length);

        for(uint256 j = 0; j < userData.poolsStaked.length; ++j){
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
}