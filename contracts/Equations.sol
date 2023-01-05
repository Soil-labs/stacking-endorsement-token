// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "hardhat/console.sol";

contract Equations {

    struct StakerValue {
        NoOfEndorcements NE;
        QualityOfStakes QS;
        uint256 stakeAmount;
        uint256 qualityStaker;
    }

    /// @notice Gets the reward per user
    /// @param maxRewards a struct of the params to get the value of quality amount for each user
    /// @param staker a struct of the params to get the value of the staker
    function rewardPerUser(uint256 maxRewards, MaxRewards[] memory MR, StakerValue memory staker) public pure returns (uint256 rewards_) { 
        require(MR.length != 0, "!length");

        uint256 L = MR.length;
        uint256 sumOfStakers_ = 0;

        for(uint256 i = 0; i < L; i++){
            sumOfStakers_ += (MR[i].stakeAmount * MR[i].qualityStaker) / 100;
        }

        rewards_ = (((staker.stakeAmount * staker.qualityStaker)/sumOfStakers_) * maxRewards ) / 100;
    }

    function _getPercent(
        uint256 _num,
        uint256 _denom,
        uint256 _precision
    ) internal pure returns (uint256 quotient) {
        // caution, check safe-to-multiply here
        uint256 num = _num * 10 ** (_precision + 1);
        // with rounding of last digit
        quotient = ((num / _denom) + 5) / 10;
    }

    struct MaxRewards {
        NoOfEndorcements NE;
        QualityOfStakes QS;
        uint256 stakeAmount;
        uint256 qualityStaker;
    }

    /// @notice Gets the sum of staker quality amount on a user
    /// @param m how much extra reward from the stake amount you want to give - approximately the upper limit of the maxRewards as long as the quality of the staker is high
    /// @param MR struct used to get the values relevant to find the sum of stakers and max rewards
    /// @notice the weightage should be entered in basis points and equals to 10_000
    function getMaxRewards(uint256 m, MaxRewards[] memory MR, uint256 _availRewards) public view returns (uint256 sumOfStakers_) {
        require(MR.length != 0, "!length");

        uint256 L = MR.length;
        sumOfStakers_ = 0;

        for(uint256 i = 0; i < L; i++){
            console.log("stakeAmount", MR[i].stakeAmount);
            sumOfStakers_ += (MR[i].stakeAmount * MR[i].qualityStaker) / 100;
        }

        sumOfStakers_ = (sumOfStakers_ * m) / 10_000;

        if(_availRewards < sumOfStakers_){
            sumOfStakers_ = _availRewards;
        }
    }

    /// @notice Gets the sum of staker quality amount on a user
    /// @param MR struct used to get the values relevant to find the sum of stakers and max rewards
    /// @param weightage0 weightage of the number of endorcements
    /// @param weightage1 weightage of the quality of stakes
    /// @notice the weightage should be entered in basis points and equals to 10_000
    function getSumOfStakers(MaxRewards[] memory MR, uint256 weightage0, uint256 weightage1) public pure returns (uint256 sumOfStakers_) {
        require(MR.length != 0, "!length");

        uint256 L = MR.length;
        sumOfStakers_ = 0;

        for(uint256 i = 0; i < L; i++){
            sumOfStakers_ += valueOfQualityAmount(weightage0, weightage1, MR[i].NE, MR[i].QS, MR[i].stakeAmount);
        }
    }

    /// @notice get the sum of quality of a user
    /// @param weightage0 weightage of the number of endorcements
    /// @param weightage1 weightage of the quality of stakes
    /// @notice the weightage should be entered in basis points and equals to 10_000
    /// @param NE a struct of the params for getting the number of endorcements
    /// @param QS a struct of the params for getting the quality of stakes
    /// @param stakeAmount amount staked by the user on this specific user
    /// @return value_ returns quality of stake against the stakeAmount
    function valueOfQualityAmount(uint256 weightage0, uint256 weightage1, NoOfEndorcements memory NE, QualityOfStakes memory QS, uint256 stakeAmount) public pure returns (uint256 value_) {
        value_ = qualityOfStaker(weightage0, weightage1, NE, QS) * stakeAmount;
    }

    struct NoOfEndorcements {
        uint256 mE;
        uint256 eN;
    }

    struct QualityOfStakes {
        uint256[] cr;
        uint256[] cd;
    }

    /// @notice gets the quality of a staker
    /// @param weightage0 weightage of the number of endorcements
    /// @param weightage1 weightage of the quality of stakes
    /// @notice the weightage should be entered in basis points and equals to 10_000
    /// @param NE a struct of the params for getting the number of endorcements
    /// @param QS a struct of the params for getting the quality of stakes
    /// @return quality_ returns the quality of a staker
    function qualityOfStaker(uint256 weightage0, uint256 weightage1, NoOfEndorcements memory NE, QualityOfStakes memory QS) public pure returns (uint256 quality_){
        quality_ = (((weightage0 * numberOfEndorcements(NE.mE, NE.eN))) + ((weightage1 * qualityOfStakes(QS.cr, QS.cd)))) / 10000; // We multiply with weightage1 -> which is *10000, so we need to take it down again 
    }
    
    /// @notice determine the quality of stake
    /// @param cr how much the user i brings to a protocol
    /// @param cd how much staked on this user
    /// @notice N the number of users that you staked
    /// @notice values are scaled up to add more precision and ensure sum can be divided by N
    /// @return quality_ the quality of stakes
    function qualityOfStakes(uint256[] memory cr, uint256[] memory cd) public pure returns (uint256 quality_) {
        require(cr.length == cd.length, "!length");
        uint256 N = cr.length;
        uint256 sum = 0;

        for(uint256 i = 0; i < N; i++){
            sum += (cr[i] * 1000)  / (cd[i] * 10);
        }

        quality_ = (sum / N);
    }

    /// @notice calculate the number of endorcement points
    /// @param mE max number of endorcements
    /// @param eN number of endorcements
    /// @notice scaled to be 100 instead of one since theres not decimals
    function numberOfEndorcements(uint256 mE, uint256 eN) public pure returns (uint256 number_) {
        require(eN < mE, "!eN");

        number_ = (eN*100*100)/(mE*100);
    }
}