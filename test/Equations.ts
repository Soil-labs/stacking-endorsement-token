import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { parseEther } from "ethers/lib/utils";

describe("Equations", function () {

    // How much the staker i stacked on the user j
    const CR = [
        [
            500, // user0 - staker 0
            300, // user1 - staker 0
            1000, // user2 - staker 0
            1050,
            200,
            400,
            600,
            800,
            1000
        ],
        [
            100,  // user0 - staker 1
            800,
            500,
            2000
        ],
        [
            200,  // user0 - staker 2
            200,
        ]
    ];

    // Blue -> we might ned to know who made the endorcments to this user

    // How much staked on this user j in total
    const CD = [
        [
            1000, // user 0
            2000, // user 0
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

    const WEIGHTAGE_0 = 3000; // w_0 // we multiple everything by 1000
    const WEIGHTAGE_1 = 7000; // w_1

    // value is out of 100 for penalty so, ie. 40 is 0.4 or 40%
    const PENALTY = 40;
    const MAX_ENDORCEMENTS = 10;

    // value is in basis points so i.e, 11000 will b 110% or 1.1 
    const MULTIPLIER = 11000


    async function setup(){
        const [owner, otherAccount] = await ethers.getSigners();

        const Equations = await ethers.getContractFactory("Equations");
        const equations = await Equations.deploy();

        return { equations, owner, otherAccount};
    }

    describe("Number of Endorcements", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);


            const endorcementsMade = users[0].endorcementsMade;

            const numOfEndorcements = await equations.numberOfEndorcements(MAX_ENDORCEMENTS, endorcementsMade);
            expect(numOfEndorcements).to.equals(90);


            const endorcementsMade_2 = users[1].endorcementsMade;

            const numOfEndorcements_2 = await equations.numberOfEndorcements(MAX_ENDORCEMENTS, endorcementsMade_2);
            expect(numOfEndorcements_2).to.equals(40);

            
        });
    });

    describe("Quality of Stakes", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);

            const qualityOfStakes = await equations.qualityOfStakes(users[2].cr, users[2].cd);
            expect(qualityOfStakes).to.equals(15);
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
                mE: MAX_ENDORCEMENTS,
                eN: users[0].endorcementsMade
            }

            const qualityOfStakers = await equations.qualityOfStaker(WEIGHTAGE_0, WEIGHTAGE_1, numberOfEndorcements, qualityOfStakes);

            expect(qualityOfStakers).to.equal(39);
            
            let numOfEndorcementsVal: BigNumber = await equations.numberOfEndorcements(MAX_ENDORCEMENTS, users[0].endorcementsMade);
            let qualityOfStakesVal: BigNumber = await equations.qualityOfStakes(users[0].cr, users[0].cd);
            let qualityOfStakersVal = ((numOfEndorcementsVal.mul(WEIGHTAGE_0)).add(qualityOfStakesVal.mul(WEIGHTAGE_1))).div(10000);
            
            expect(qualityOfStakers).to.equals(qualityOfStakersVal);
        });
    });

    describe("MaxRewards", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);

            const user1NE = {
                mE: MAX_ENDORCEMENTS,
                eN: users[0].endorcementsMade
            };

            const user1QS = {
                cr: users[0].cr,
                cd: users[0].cd
            }

            const user2NE = {
                mE: MAX_ENDORCEMENTS,
                eN: users[1].endorcementsMade
            };

            const user2QS = {
                cr: users[1].cr,
                cd: users[1].cd
            }

            const user3NE = {
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
                    stakeAmount: users[0].cr[0],
                    qualityStaker:-1
                },
                {
                    NE: user2NE,
                    QS: user2QS,
                    stakeAmount: users[1].cr[0],
                    qualityStaker:-1
                },
                {
                    NE: user3NE,
                    QS: user3QS,
                    stakeAmount: users[2].cr[0],
                    qualityStaker:-1
                },
            ]

            let qualityStaker_now;

            for (let i=0;i<maxRewardsStruct.length;i++){
                qualityStaker_now = await equations.qualityOfStaker(WEIGHTAGE_0, WEIGHTAGE_1, maxRewardsStruct[i].NE, maxRewardsStruct[i].QS);
                maxRewardsStruct[i].qualityStaker = Number(qualityStaker_now);
            }

            const maxRewards = await equations.getMaxRewards(MULTIPLIER, maxRewardsStruct, parseEther('1'));
            expect(maxRewards).to.equals(284);

            // Use only the stake and the quality of the getMaxRewards
            // multiple them, and get back result 
        });
    });

    describe("Rewards per user", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);

            const user1NE = {
                mE: MAX_ENDORCEMENTS,
                eN: users[0].endorcementsMade
            };

            const user1QS = {
                cr: users[0].cr,
                cd: users[0].cd
            }

            const user2NE = {
                mE: MAX_ENDORCEMENTS,
                eN: users[1].endorcementsMade
            };

            const user2QS = {
                cr: users[1].cr,
                cd: users[1].cd
            }

            const user3NE = {
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
                    stakeAmount: users[0].cr[0],
                    qualityStaker: -1,
                },
                {
                    NE: user2NE,
                    QS: user2QS,
                    stakeAmount: users[1].cr[0],
                    qualityStaker: -1,
                },
                {
                    NE: user3NE,
                    QS: user3QS,
                    stakeAmount: users[2].cr[0],
                    qualityStaker: -1,
                },
            ]

            let stakerTest = 2;
            
            const stakerValues = maxRewardsStruct[stakerTest];


            let qualityStaker_now;

            for (let i=0;i<maxRewardsStruct.length;i++){
                qualityStaker_now = await equations.qualityOfStaker(WEIGHTAGE_0, WEIGHTAGE_1, maxRewardsStruct[i].NE, maxRewardsStruct[i].QS);
                maxRewardsStruct[i].qualityStaker = Number(qualityStaker_now);
            }

            const maxRewards = await equations.getMaxRewards(MULTIPLIER, maxRewardsStruct, parseEther('1'));
            expect(maxRewards).to.equals(284);

            const rewardsForUser = await equations.rewardPerUser(maxRewards, maxRewardsStruct, stakerValues);
            expect(rewardsForUser).to.equals(34);
        });
    });
});

// break down the functions to 1 describe