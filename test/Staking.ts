import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { Equations, Staking, Trust } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { token } from "../typechain-types/@openzeppelin/contracts";

describe("Equations", function () {

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

    const stakersMock = [
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

    let poolMock: any = [
        [], // user 0
        [], // user 1
        [], // user 2
        [], // user 3
        [], // user 4
        [], // user 5
        [], // user 6
        [], // user 7
        [], // user 8
    ];

    const WEIGHTAGE_0 = 3000; // w_0 // we multiple everything by 1000
    const WEIGHTAGE_1 = 7000; // w_1

    // value is in basis points so i.e, 11000 will b 110% or 1.1 
    const MULTIPLIER = 11000

    let staking: Staking, equations: Equations, trustToken: Trust, stakers: SignerWithAddress[], users: SignerWithAddress[];

    const INITIAL_MINT = parseEther("1");
    const TOTAL_DEPOSITS = 45000;

    async function setup(){
        const [owner, staker1, staker2, staker3, staker4, user1, user2, user3, user4, user5, user6, user7, user8, user9] = await ethers.getSigners();

        const Token = await ethers.getContractFactory("Trust");
        const trust = await Token.deploy("Trust", "TRST", 18);

        const Equations = await ethers.getContractFactory("Equations");
        const equationsContract = await Equations.deploy();

        const Staking = await ethers.getContractFactory("Staking");
        const stakingContract = await Staking.deploy(trust.address, equationsContract.address);

        await trust.connect(owner).mint(staker1.address, INITIAL_MINT);
        await trust.connect(owner).mint(staker2.address, INITIAL_MINT);
        await trust.connect(owner).mint(staker3.address, INITIAL_MINT);
        await trust.connect(owner).mint(staker4.address, INITIAL_MINT);

        stakers = [
            staker1,
            staker2, 
            staker3,
            staker4
        ];

        users = [
            user1,
            user2,
            user3,
            user4,
            user5,
            user6, 
            user7,
            user8,
            user9
        ];

        poolMock[0] = 
            [
                staker1.address,
                staker2.address,
                staker3.address,
                staker4.address,
            ];

        poolMock[1] = 
            [
                staker1.address,
                staker2.address,
                staker3.address,
                staker4.address,
            ];

        poolMock[2] = 
            [
                staker1.address,
                staker2.address,
                staker4.address,
            ];

        poolMock[3] = 
            [
                staker1.address,
                staker2.address,
                staker4.address,
            ];

        poolMock[4] = 
            [
                staker1.address,
                staker4.address,
            ];

        poolMock[5] = 
            [
                staker1.address,
                staker4.address,
            ];

        poolMock[6] = 
            [
                staker1.address,
                staker4.address,
            ];

        poolMock[7] = 
            [
                staker1.address,
                staker4.address,
            ];

        poolMock[8] = 
            [
                staker1.address,
                staker4.address,
            ];


        for(let i = 0; i < 4; i++){
            expect(await trust.balanceOf(stakers[i].address)).to.eq(INITIAL_MINT);
        };

        trustToken = trust;
        equations = equationsContract;
        staking = stakingContract;
    }

    describe("Create pools", function() {
        it("9 Pools should be created", async function () {
            await loadFixture(setup);

            for(let i = 0; i < CD[0].length; i++){
                await staking.createPool(WEIGHTAGE_0, WEIGHTAGE_1, MULTIPLIER, users[i].address);
            }

            expect(await staking.totalPools()).to.eq(9);

            for(let i = 0; i < CD[0].length; i++){
                const pool = await staking.userPool(i);
                expect(pool.weightage0).to.eq(WEIGHTAGE_0);
                expect(pool.weightage1).to.eq(WEIGHTAGE_1);
                expect(pool.multiplier).to.eq(MULTIPLIER);
                expect(pool.user).to.eq(users[i].address)
            };

        });
    });

    describe("Staking and pool", function() {
        it("Should be using the right token", async function () {
            expect(await staking.stakingToken()).to.eq(trustToken.address);
        });

        it("Staking the right amount of tokens on specific pools", async function () {
            for(let i = 0; i < 4; i++){
                for(let j = 0; j < stakersMock[i].cr.length; j++){
                    await trustToken.connect(stakers[i]).approve(staking.address, stakersMock[i].cr[j]);
                    await staking.connect(stakers[i]).stakeOnPool(j, stakersMock[i].cr[j]);
                }
            };
        });

        it("Total amount staked in each pool is correct", async function () {
            for(let i = 0; i < CD[0].length; i++){
                const pool = await staking.userPool(i);
                expect(pool.totalStaked).to.eq(CD[0][i])
            };
        });

        it("Stakers staked amount is correct in each pool", async function () {
            for(let i = 0; i < 4; i++){
                for(let j = 0; j < stakersMock[i].cr.length; j++){
                    const staker = await staking.getStakerData(stakers[i].address);
                    expect(staker.pools[j].amountStaked).eq(stakersMock[i].cr[j])
                }
            };
        });

        it("Number of stakers on each pool is correct", async function () {
            for(let i = 0; i < CD[0].length; i++){
                const [,,,,,, usersStaked] = await staking.getPoolData(i);
                assert.sameMembers(usersStaked, poolMock[i]);
            };
        });

        it("Pool user is correct", async function () {
            for(let i = 0; i < CD[0].length; i++){
                const [,,,,, user,] = await staking.getPoolData(i);
                expect(user).to.eq(users[i].address);
            };
        });
    });

    describe("Equations should return accurate values", function() {
        it("Number of endorcements should be accurate per simulation", async function () {
            const numberOfEndorcements = await staking.getNumberOfEndorcements(stakers[0].address);
            expect(numberOfEndorcements).to.equals(90);
        });

        it("Quality of stakes should be accurate per simulation", async function () {
            const qualityOfStakes = await staking.getQualityOfStakes(stakers[2].address);
            expect(qualityOfStakes).to.equals(15);
        });

        it("Quality of staker should be accurate per simulation", async function () {
            const qualityOfStaker = await staking.getQualityOfStaker(0, stakers[0].address);
            expect(qualityOfStaker).to.equals(39);
        });

        it("Max Rewards should be accurate per simulation", async function () {
            const qualityOfStaker = await staking.getMaxRewards(0, parseEther('1'));
            expect(qualityOfStaker).to.equals(443);
        });

        it("Rewards for staker 2 should be accurate per simulation", async function () {
            const rewards = await staking.getRewardPerUser(0, parseEther('1'), stakers[2].address);
            expect(rewards).to.equals(31);
        });

        it("Claim rewards from the pool", async function () {
            const currBal = await trustToken.balanceOf(staking.address);
            expect(currBal).to.eq(TOTAL_DEPOSITS)

            const rewards = await staking.getRewardPerUser(0, parseEther('1'), stakers[2].address);
            expect(rewards).to.equals(31);

            await staking.connect(stakers[2]).claimRewardsFromPool(0, stakers[2].address);
            
            expect(await trustToken.balanceOf(staking.address)).to.eq(currBal.sub(rewards));        
        });
    });


});