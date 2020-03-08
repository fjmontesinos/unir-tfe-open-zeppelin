// Nos permitira validar eventos
// const TruffleAssert = require('truffle-assertions');
// para comprobar operaciones como el factorial
//const Math = require('mathjs');

const Estado = artifacts.require("./Estado.sol");
const ECTSToken = artifacts.require("./ECTSToken.sol");
const AsignaturaToken = artifacts.require("./AsignaturaToken.sol");

contract("Tokens ERC721", accounts => {

    let estado, ects;

    beforeEach(async() => {
        ects = await ECTSToken.new();
        estado = await Estado.new(ects.address);
        ects.setEstado(estado.address);
    });

    it("configuración correcta", async() => {
        const a = await ects.getEstado();
        assert.equal(a, estado.address);
    });

    it("crear asignatura ERC721", async() => {
        await estado.crearAsignatura("Calculo 1", "CAL1", 7, 0);
        const asignaturas = await estado.getAsignaturas();

        let a = await AsignaturaToken.at(asignaturas[0]);
        const nombre = await a.name();
        const symbol = await a.symbol();

        assert.equal(nombre, 'Calculo 1');
        assert.equal(symbol, 'CAL1');
    });

});