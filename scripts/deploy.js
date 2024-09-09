const {ethers, upgrades} = require('hardhat');
const hre = require("hardhat");
// const { time } = require("@nomicfoundation/hardhat-network-helpers");


async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main(){
//          const mmitTokenFactory = await ethers.getContractFactory("MyToken");
//          const mmitToken = await mmitTokenFactory.deploy("0x25E103D477025F9A8270328d84397B2cEE32D0BF",{
//                   gasPrice: ethers.parseUnits('10', 'gwei'), // Set a higher gas price
//                   gasLimit: 5000000 // Adjust the gas limit as needed
//                 });
//          await mmitToken.waitForDeployment(5);

//          const mmitTokenContractAddress = await mmitToken.getAddress();

//          console.log("mmitTokenContractAddress",mmitTokenContractAddress);
   
      //    const PredictionMarketFacroty = await ethers.getContractFactory("SimplePredictionMarket");
      //    const predictionMarket = await upgrades.deployProxy(
      //      PredictionMarketFacroty,
      //      ["0x9bb9885C392A4d3c81B8128d72C5106f84b54B20"],
      //      { kind: "uups" },{
      //       gasPrice: ethers.parseUnits('1', 'gwei'), // Set a higher gas price
      //       gasLimit: 5000000 // Adjust the gas limit as needed
      //      }
      //  );
      //  const predictionMarketAddress = await predictionMarket.getAddress();

      //  console.log("Contract deployed to:", predictionMarketAddress);

//        const implementationContractAddressStaking = await upgrades.erc1967.getImplementationAddress(
//          stakingContractAddress
//         );

//         console.log("implementationContractAddressStaking",implementationContractAddressStaking);

        await hre.run("verify:verify", {
         address:"0x31620935d3d5dab6aabd3171088897d7b605a9ba",
         constructorArguments: [],
     });


  
console.log("Verification Done")

// 0x9bb9885C392A4d3c81B8128d72C5106f84b54B20  - TestNetToken

// 0x9767c8E438Aa18f550208e6d1fDf5f43541cC2c8  - MainnetToken
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});


   