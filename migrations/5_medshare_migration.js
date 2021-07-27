const StringsAndBytes = artifacts.require("StringsAndBytes");
const MedShare = artifacts.require("MedShare");

module.exports = function (deployer, network, accounts) {    
    /* await deployer.deploy(MedShareToken);
    //access information about your deployed contract instance
    const instance = await MedShareToken.deployed(); */
    
    deployer.deploy(StringsAndBytes);
    deployer.link(StringsAndBytes, MedShare);
    deployer.deploy(MedShare);
    
    /* if (network == "development") {
    } else {            
    } */
    
    // Deploy A, then deploy B, passing in A's newly deployed address
    /* deployer.deploy(A).then(function () {
        return deployer.deploy(B, A.address);
    }); */
};

