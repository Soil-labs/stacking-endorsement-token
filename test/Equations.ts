import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("Equations", function () {
    const CR = [
        [
            500,
            300,
            1000,
            1050,
            200,
            400,
            600,
            800,
            1000
        ],
        [
            100,
            800,
            500,
            2000
        ],
        [
            200,
            200
        ]
    ];

    const CD = [
        [
            1000,
            2000,
            3000,
            4000,
            5000,
            6000,
            7000,
            8000,
            9000,
        ],
        [
            1000,
            2000,
            3000,
            4000
        ],
        [
            1000,
            2000
        ]
    ];

    const users = [
        {
            endorcementsMade: 9,
            cr: CR[0],
            cd: CD[0]
        },
        {
            endorcementsMade: 4,
            cr: CR[1],
            cd: CD[1]
        },
        {
            endorcementsMade: 2,
            cr: CR[2],
            cd: CD[2]
        }
    ];

    const WEIGHTAGE_0 = 3000;
    const WEIGHTAGE_1 = 7000;
    // value is out of 100 for penalty so, ie. 40 is 0.4 or 40%
    const PENALTY = 40;
    const MAX_ENDORCEMENTS = 10;

    // value is in basis points so i.e, 11000 will b 110% or 1.1 
    const MULTIPLIER = 11000


    async function setup(){
        const [owner, otherAccount] = await ethers.getSigners();

        const Equations = await ethers.getContractFactory("Equations");
        const equations = await Equations.deploy(true);

        return { equations, owner, otherAccount};
    }

    describe("Deployment", function() {
        it("Should set the right deployed status", async function () {
        const { equations } = await loadFixture(setup);

        expect(await equations.deployedStatus()).to.equal(true);
        });
    });

    describe("Number of Endorcements", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);


            const endorcementsMade = users[0].endorcementsMade;

            const numOfEndorcements = await equations.numberOfEndorcements(PENALTY, MAX_ENDORCEMENTS, endorcementsMade);
            expect(numOfEndorcements).to.equals(0);
        });
    });

    describe("Quality of Stakes", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);

            const qualityOfStakes = await equations.qualityOfStakes(users[0].cr, users[0].cd);
            expect(qualityOfStakes).to.equals(1832);
        });
    });

    describe("Quality of Staker", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);

            const qualityOfStakes = {
                cr: users[0].cr, 
                cd: users[0].cd,
            }
            const numberOfEndorcements = {
                v: PENALTY,
                mE: MAX_ENDORCEMENTS,
                eN: users[0].endorcementsMade
            }

            const qualityOfStakers = await equations.qualityOfStaker(WEIGHTAGE_0, WEIGHTAGE_1, numberOfEndorcements, qualityOfStakes);
            
            // simulate actual transaction values for the functions involved
            let numOfEndorcementsVal: BigNumber = await equations.numberOfEndorcements(PENALTY, MAX_ENDORCEMENTS, users[0].endorcementsMade);
            let qualityOfStakesVal: BigNumber = await equations.qualityOfStakes(users[0].cr, users[0].cd);
            let qualityOfStakersVal = ((numOfEndorcementsVal.mul(WEIGHTAGE_0)).add(qualityOfStakesVal.mul(WEIGHTAGE_1))).div(10000);
            
            expect(qualityOfStakers).to.equals(qualityOfStakersVal);
        });
    });

    describe("MaxRewards", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);

            const user1NE = {
                v: PENALTY,
                mE: MAX_ENDORCEMENTS,
                eN: users[0].endorcementsMade
            };

            const user1QS = {
                cr: users[0].cr,
                cd: users[0].cd
            }

            const user2NE = {
                v: PENALTY,
                mE: MAX_ENDORCEMENTS,
                eN: users[1].endorcementsMade
            };

            const user2QS = {
                cr: users[1].cr,
                cd: users[1].cd
            }

            const user3NE = {
                v: PENALTY,
                mE: MAX_ENDORCEMENTS,
                eN: users[2].endorcementsMade
            };

            const user3QS = {
                cr: users[2].cr,
                cd: users[2].cd
            }


            const maxRewardsStruct = [
                {
                    NE: user1NE,
                    QS: user1QS,
                    stakeAmount: users[0].cr[0]
                },
                {
                    NE: user2NE,
                    QS: user2QS,
                    stakeAmount: users[1].cr[0]
                },
                {
                    NE: user3NE,
                    QS: user3QS,
                    stakeAmount: users[2].cr[0]
                },
            ]
            

            const maxRewards = await equations.getMaxRewards(MULTIPLIER, maxRewardsStruct, WEIGHTAGE_0, WEIGHTAGE_1);
            console.log("max rewards", maxRewards.toString());
        });
    });

    describe("Rewards per user", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);

            const user1NE = {
                v: PENALTY,
                mE: MAX_ENDORCEMENTS,
                eN: users[0].endorcementsMade
            };

            const user1QS = {
                cr: users[0].cr,
                cd: users[0].cd
            }

            const user2NE = {
                v: PENALTY,
                mE: MAX_ENDORCEMENTS,
                eN: users[1].endorcementsMade
            };

            const user2QS = {
                cr: users[1].cr,
                cd: users[1].cd
            }

            const user3NE = {
                v: PENALTY,
                mE: MAX_ENDORCEMENTS,
                eN: users[2].endorcementsMade
            };

            const user3QS = {
                cr: users[2].cr,
                cd: users[2].cd
            }


            const maxRewardsStruct = [
                {
                    NE: user1NE,
                    QS: user1QS,
                    stakeAmount: users[0].cr[0]
                },
                {
                    NE: user2NE,
                    QS: user2QS,
                    stakeAmount: users[1].cr[0]
                },
                {
                    NE: user3NE,
                    QS: user3QS,
                    stakeAmount: users[2].cr[0]
                },
            ]
            
            const stakerValues = {
                NE: user1NE,
                QS: user1QS,
                stakeAmount: users[0].cr[0]
            }

            const rewardsPerUser = await equations.rewardPerUser(MULTIPLIER, maxRewardsStruct, WEIGHTAGE_0, WEIGHTAGE_1, stakerValues);
            console.log("rewardsPerUser", rewardsPerUser.toString());
        });
    });
});