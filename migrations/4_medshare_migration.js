const StringsAndBytes = artifacts.require("StringsAndBytes");
const MedShareToken = artifacts.require("MedShareToken");
const MedShare = artifacts.require("MedShare");

module.exports = function (deployer, network, accounts) {
    
    if (network == "development") {
        deployer.deploy(MedShareToken);
        // Deploy library StringsAndBytes, then link StringsAndBytes to contract MedShareToken,
        // then deploy MedShareToken.
        deployer.deploy(StringsAndBytes);
        deployer.link(StringsAndBytes, MedShare);
        deployer.deploy(MedShare);
    } else {
        deployer.deploy(MedShareToken);
        // Deploy library StringsAndBytes, then link StringsAndBytes to contract MedShareToken,
        // then deploy MedShareToken.
        deployer.deploy(StringsAndBytes);
        deployer.link(StringsAndBytes, MedShare);
        deployer.deploy(MedShare);
    }
    
    // Deploy A, then deploy B, passing in A's newly deployed address
    /* deployer.deploy(A).then(function () {
        return deployer.deploy(B, A.address);
    }); */
};


