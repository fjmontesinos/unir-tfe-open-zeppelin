const ECTSToken = artifacts.require("./ECTSToken.sol");
const Estado = artifacts.require("./Estado.sol");

module.exports = function(deployer, network, accounts) {
    var ectsTokenSC;
    deployer.deploy(ECTSToken, { from: accounts[0] })
        .then(() => ECTSToken.deployed())
        .then((instance) => {
            ectsTokenSC = instance;
            return deployer.deploy(Estado, instance.address, { from: accounts[0] });
        })
        .then(() => Estado.deployed())
        .then((instance) => {
            ectsTokenSC.setEstado(instance.address, { from: accounts[0] });
        });
};