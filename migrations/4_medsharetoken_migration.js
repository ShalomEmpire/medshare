const MedShareToken = artifacts.require("MedShareToken");

module.exports = async function (deployer, network, accounts) {    
    await deployer.deploy(MedShareToken);
    //access information about your deployed contract instance
    const instance = await MedShareToken.deployed();
};

