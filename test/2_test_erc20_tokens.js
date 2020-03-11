// Nos permitira validar eventos
// const TruffleAssert = require('truffle-assertions');
// para comprobar operaciones como el factorial
//const Math = require('mathjs');

const Estado = artifacts.require("./Estado.sol");
const ECTSToken = artifacts.require("./ECTSToken.sol");
const AsignaturaToken = artifacts.require("./AsignaturaToken.sol");

contract("Tokens ERC20", accounts => {

    let estado, ects;

    beforeEach(async() => {
        ects = await ECTSToken.new();
        estado = await Estado.new(ects.address);
        ects.setEstado(estado.address);
    });

    it("estado::configuración correcta", async() => {
        const a = await ects.getEstado();
        assert.equal(a, estado.address);
    });

    it("alumno::calcular weis x créditos", async() => {
        await estado.registrarUniversidad(accounts[1], { from: accounts[0] });
        const base = 6800000000000;
        const decimales = 10000;
        const creditos = 10;
        const weis = (await estado.calcularCreditosToWeis(accounts[1], creditos)).toString();
        assert.equal(weis, creditos * decimales * base);
    });

    it("alumno::comprar tokens ects", async() => {
        await estado.registrarUniversidad(accounts[1], { from: accounts[0] });
        await estado.registrarAlumno(accounts[3], { from: accounts[0] });
        const decimales = 10000;
        const creditos = 10;
        const weis = (await estado.calcularCreditosToWeis(accounts[1], creditos)).toString();

        const balanceUni1 = (await ects.balanceOf(accounts[1])).toString();

        await estado.comprarTokens(accounts[1], creditos, { from: accounts[3], value: weis });

        const balanceUni2 = (await ects.balanceOf(accounts[1])).toString();
        const balanceAlu = (await ects.balanceOf(accounts[3])).toString();

        const balanceAluXUni = (await ects.getTokenAlumnoPorUniversidad(accounts[3], accounts[1], { from: accounts[0] })).toString();

        assert.equal(balanceUni1, parseInt(balanceUni2) + parseInt(balanceAlu));
        assert.equal(balanceAlu, balanceAluXUni);
    });

});