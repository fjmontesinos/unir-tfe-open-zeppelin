// Nos permitira validar eventos
// const TruffleAssert = require('truffle-assertions');
// para comprobar operaciones como el factorial
//const Math = require('mathjs');

const Estado = artifacts.require("./Estado.sol");
const ECTSToken = artifacts.require("./ECTSToken.sol");
const AsignaturaToken = artifacts.require("./AsignaturaToken.sol");

contract("Registro", accounts => {

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

    it("registrar universidad", async() => {
        await estado.registrarUniversidad(accounts[1], "UNIR", { from: accounts[0] });
        const universidades = await estado.getUniversidades();
        assert.equal(universidades[0], accounts[1]);
    });

    it("registrar profesor", async() => {
        await estado.registrarProfesor(accounts[2], "Javier Montesinos", { from: accounts[0] });
        const profesores = await estado.getProfesores();
        assert.equal(profesores[0], accounts[2]);
    });

    it("registrar alumno", async() => {
        await estado.registrarAlumno(accounts[3], "Keti Crespo", { from: accounts[0] });
        const alumnos = await estado.getAlumnos();
        assert.equal(alumnos[0], accounts[3]);
    });

});