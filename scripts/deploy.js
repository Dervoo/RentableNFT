const hre = require("hardhat")
const { verify } = require("../utils/verify.js")

async function main() {
    const ERC4907 = await hre.ethers.getContractFactory("RentableNFT")
    const eRC4907 = await ERC4907.deploy("bro", "BRO")
    await eRC4907.deployed()
    console.log("ERC4907 deployed to:", eRC4907.address)

    verify(eRC4907.address, ["bro", "BRO"])
    console.log("Done")
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
