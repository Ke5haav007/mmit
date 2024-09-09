const { expect, use } = require("chai");
const { ethers, upgrades} = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Staking", function () {
  let owner,user1,user2,user3,user4,user5,user6,user7,user8;
  let mmitToken ,mmitTokenFactory
  let prediction, predictionFacory

    beforeEach(async function () {
      [owner,user1,user2,user3,user4,user5,user6,user7,user8] = await ethers.getSigners();

      mmitTokenFactory = await ethers.getContractFactory("MyToken");
      mmitToken = await mmitTokenFactory.deploy(owner.address);

      predictionFacory = await ethers.getContractFactory("SimplePredictionMarket");
      prediction = await upgrades.deployProxy(
        predictionFacory,
        [mmitToken.target],
        { kind: "uups" }
    );
    });

     
    it("User Deposit", async function () {

      await mmitToken.mint(user1.address,ethers.parseEther("100"));
      await mmitToken.connect(user1).approve(prediction.target,ethers.parseEther("100"));      
      
      // await prediction.connect(user1)
    });


   
  

  });