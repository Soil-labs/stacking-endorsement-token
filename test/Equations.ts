import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { parseEther } from "ethers/lib/utils";

describe("Equations", function () {

    // How much the staker i stacked on the user j
    const CR = [
        [   // staker 0
            500,  // user0 - staker 0
            300,  // user1 - staker 0
            1000, // user2 - staker 0
            1050, // user3 - staker 0
            200,  // user4 - staker 0
            400,  // user5 - staker 0
            600,  // user6 - staker 0
            800,  // user7 - staker 0
            1000  // user8 - staker 0
        ],
        [   // staker 1
            100,  // user0 - staker 1
            800,  // user1 - staker 1
            500,  // user2 - staker 1
            2000  // user3 - staker 1
        ],
        [   // staker 2
            200,  // user0 - staker 2
            200,  // user1 - staker 2
        ],
        [   // staker 3
            200,  // user0 - staker 3 
            700,  // user1 - staker 3
            1500, // user2 - staker 3
            950,  // user3 - staker 3
            4800, // user4 - staker 3
            5600, // user5 - staker 3
            6400, // user6 - staker 3
            7200, // user7 - staker 3
            8000, // user8 - staker 3
        ]
    ];

    // Blue -> we might ned to know who made the endorcments to this user

    // How much staked on this user j in total
    const CD = [
        [
            1000, // user 0
            2000, // user 1
            3000, // user 2
            4000, // user 3
            5000, // user 4
            6000, // user 5
            7000, // user 6
            8000, // user 7
            9000, // user 8
        ],
        [
            1000, // user 0
            2000, // user 1
            3000, // user 2
            4000, // user 3
        ],
        [
            1000, // user 0
            2000, // user 1
        ],
        [
            1000, // user 0
            2000, // user 1
            3000, // user 2
            4000, // user 3
            5000, // user 4
            6000, // user 5
            7000, // user 6
            8000, // user 7
            9000, // user 8
        ],
    ];

    const stakers = [
        {   // staker 0
            endorcementsMade: 9,
            cr: CR[0],
            cd: CD[0]
        },
        {   // staker 1
            endorcementsMade: 4,
            cr: CR[1],
            cd: CD[1]
        },
        {   // staker 2
            endorcementsMade: 2,
            cr: CR[2],
            cd: CD[2]
        },
        {   // staker 3
            endorcementsMade: 9,
            cr: CR[3],
            cd: CD[3]
        },
    ];

    const WEIGHTAGE_0 = 3000; // w_0 // we multiple everything by 1000
    const WEIGHTAGE_1 = 7000; // w_1

    // value is out of 100 for penalty so, ie. 40 is 0.4 or 40%
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


            const endorcementsMade = stakers[0].endorcementsMade;

            const numOfEndorcements = await equations.numberOfEndorcements(MAX_ENDORCEMENTS, endorcementsMade);
            expect(numOfEndorcements).to.equals(90);


            const endorcementsMade_2 = stakers[1].endorcementsMade;

            const numOfEndorcements_2 = await equations.numberOfEndorcements(MAX_ENDORCEMENTS, endorcementsMade_2);
            expect(numOfEndorcements_2).to.equals(40);

            
        });
    });

    describe("Quality of Stakes", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);

            const qualityOfStakes = await equations.qualityOfStakes(stakers[2].cr, stakers[2].cd);
            expect(qualityOfStakes).to.equals(15);
        });
    });

    describe("Quality of Staker", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);

            const qualityOfStakes = {
                cr: stakers[0].cr, 
                cd: stakers[0].cd,
            }
            
            const numberOfEndorcements = {
                mE: MAX_ENDORCEMENTS,
                eN: stakers[0].endorcementsMade
            }

            const qualityOfStakers = await equations.qualityOfStaker(WEIGHTAGE_0, WEIGHTAGE_1, numberOfEndorcements, qualityOfStakes);

            expect(qualityOfStakers).to.equal(39);
            
            let numOfEndorcementsVal: BigNumber = await equations.numberOfEndorcements(MAX_ENDORCEMENTS, stakers[0].endorcementsMade);
            let qualityOfStakesVal: BigNumber = await equations.qualityOfStakes(stakers[0].cr, stakers[0].cd);
            let qualityOfStakersVal = ((numOfEndorcementsVal.mul(WEIGHTAGE_0)).add(qualityOfStakesVal.mul(WEIGHTAGE_1))).div(10000);
            
            expect(qualityOfStakers).to.equals(qualityOfStakersVal);
        });
    });

    describe("MaxRewards", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);

            const user1NE = {
                mE: MAX_ENDORCEMENTS,
                eN: stakers[0].endorcementsMade
            };

            const user1QS = {
                cr: stakers[0].cr,
                cd: stakers[0].cd
            }

            const user2NE = {
                mE: MAX_ENDORCEMENTS,
                eN: stakers[1].endorcementsMade
            };

            const user2QS = {
                cr: stakers[1].cr,
                cd: stakers[1].cd
            }

            const user3NE = {
                mE: MAX_ENDORCEMENTS,
                eN: stakers[2].endorcementsMade
            };

            const user3QS = {
                cr: stakers[2].cr,
                cd: stakers[2].cd
            };

            const user4NE = {
                mE: MAX_ENDORCEMENTS,
                eN: stakers[3].endorcementsMade
            };

            const user4QS = {
                cr: stakers[3].cr,
                cd: stakers[3].cd
            };

            const maxRewardsStruct = [
                {
                    NE: user1NE,
                    QS: user1QS,
                    stakeAmount: stakers[0].cr[0],
                    qualityStaker:-1
                },
                {
                    NE: user2NE,
                    QS: user2QS,
                    stakeAmount: stakers[1].cr[0],
                    qualityStaker:-1
                },
                {
                    NE: user3NE,
                    QS: user3QS,
                    stakeAmount: stakers[2].cr[0],
                    qualityStaker:-1
                },
                {
                    NE: user4NE,
                    QS: user4QS,
                    stakeAmount: stakers[3].cr[0],
                    qualityStaker:-1
                },
            ]

            let qualityStaker_now;

            for (let i=0;i<maxRewardsStruct.length;i++){
                qualityStaker_now = await equations.qualityOfStaker(WEIGHTAGE_0, WEIGHTAGE_1, maxRewardsStruct[i].NE, maxRewardsStruct[i].QS);
                maxRewardsStruct[i].qualityStaker = Number(qualityStaker_now);
            }

            const maxRewards = await equations.getMaxRewards(MULTIPLIER, maxRewardsStruct, parseEther('1'));
            expect(maxRewards).to.equals(443);

            // Use only the stake and the quality of the getMaxRewards
            // multiple them, and get back result 
        });
    });

    describe("Rewards per user", function() {
        it("Value return should be accurate", async function () {
            const { equations } = await loadFixture(setup);

            const user1NE = {
                mE: MAX_ENDORCEMENTS,
                eN: stakers[0].endorcementsMade
            };

            const user1QS = {
                cr: stakers[0].cr,
                cd: stakers[0].cd
            }

            const user2NE = {
                mE: MAX_ENDORCEMENTS,
                eN: stakers[1].endorcementsMade
            };

            const user2QS = {
                cr: stakers[1].cr,
                cd: stakers[1].cd
            }

            const user3NE = {
                mE: MAX_ENDORCEMENTS,
                eN: stakers[2].endorcementsMade
            };

            const user3QS = {
                cr: stakers[2].cr,
                cd: stakers[2].cd
            };

            const user4NE = {
                mE: MAX_ENDORCEMENTS,
                eN: stakers[3].endorcementsMade
            };

            const user4QS = {
                cr: stakers[3].cr,
                cd: stakers[3].cd
            };

            const maxRewardsStruct = [
                {
                    NE: user1NE,
                    QS: user1QS,
                    stakeAmount: stakers[0].cr[0],
                    qualityStaker: -1,
                },
                {
                    NE: user2NE,
                    QS: user2QS,
                    stakeAmount: stakers[1].cr[0],
                    qualityStaker: -1,
                },
                {
                    NE: user3NE,
                    QS: user3QS,
                    stakeAmount: stakers[2].cr[0],
                    qualityStaker: -1,
                },
                {
                    NE: user4NE,
                    QS: user4QS,
                    stakeAmount: stakers[3].cr[0],
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
            expect(maxRewards).to.equals(443);

            const rewardsForUser = await equations.rewardPerUser(maxRewards, maxRewardsStruct, stakerValues);
            expect(rewardsForUser).to.equals(31);
        });
    });
});