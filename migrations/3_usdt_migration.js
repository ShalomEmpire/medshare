const USDTether = artifacts.require("USDTether");

module.exports = function (deployer) {
  deployer.deploy(USDTether);
};


