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

    it("estado:configuración correcta", async() => {
        const a = await ects.getEstado();
        assert.equal(a, estado.address);
    });

    it("estado::crear asignatura ERC721", async() => {
        await estado.crearAsignatura("Calculo 1", "CAL1", 7, 0);
        const asignaturas = await estado.getAsignaturas();

        let a = await AsignaturaToken.at(asignaturas[0]);
        const nombre = await a.name();
        const symbol = await a.symbol();

        assert.equal(nombre, 'Calculo 1');
        assert.equal(symbol, 'CAL1');
    });

    it("estado::registrar universidad - profesor en asignatura", async() => {
        const creditosAsignatura = 7;
        await estado.registrarUniversidad(accounts[1], "UNIR", { from: accounts[0] });
        await estado.registrarProfesor(accounts[2], "Javier Montesinos", { from: accounts[0] });
        await estado.crearAsignatura("Calculo 1", "CAL1", creditosAsignatura, 0);
        const asignaturas = await estado.getAsignaturas();
        let a = await AsignaturaToken.at(asignaturas[0]);

        await a.registrarUniversidadProfesor(accounts[1], accounts[2], { from: accounts[0] });
        const profesor = await a.getProfesorUniversidad(accounts[1], { from: accounts[0] });
        assert.equal(profesor, accounts[2]);

    });

    it("alumno::matricular en asignatura", async() => {
        // registrar las entidades del sistema
        await estado.registrarUniversidad(accounts[1], "UNIR", { from: accounts[0] });
        await estado.registrarProfesor(accounts[2], "Javier Montesinos", { from: accounts[0] });
        await estado.registrarAlumno(accounts[3], "Keti Crespo", { from: accounts[0] });

        // adquirir tokens el alumno a la universidad
        const creditos = 10;
        const weis = (await estado.calcularCreditosToWeis(accounts[1], creditos)).toString();
        await estado.comprarTokens(accounts[1], creditos, { from: accounts[3], value: weis });

        // balance de tokens del alumno, la universidad y el alumno para la universidad tras adquirir los tokens
        const balanceUni = (await ects.balanceOf(accounts[1])).toString();
        const balanceAlu = (await ects.balanceOf(accounts[3])).toString();
        const balanceAluXUni = (await ects.getTokenAlumnoPorUniversidad(accounts[3], accounts[1], { from: accounts[0] })).toString();

        // crear una asignatura por parte del estado
        const creditosAsignatura = 7;
        const experimentabilidad = 0;
        await estado.crearAsignatura("Calculo 1", "CAL1", creditosAsignatura, experimentabilidad);
        const asignaturas = await estado.getAsignaturas();
        let a = await AsignaturaToken.at(asignaturas[0]);

        // registrar una universidad y profesor para la asignatura
        await a.registrarUniversidadProfesor(accounts[1], accounts[2], { from: accounts[0] });

        // obtener año de matricula para el alumno en la asignatura hace que pueda necesitar más o menos ECTS
        const anioMatricula = (await a.getAnioMatricula(accounts[3])).toString();

        // obtener ECTS necesarios para matricular en asignatura
        const ectsNecesarios = (await estado.calcularECTSTokensParaAsignatura(accounts[1], experimentabilidad, anioMatricula, creditosAsignatura)).toString();

        // matricular
        await a.matricular(accounts[1], '19-20', { from: accounts[3] });

        // obtener le balance de
        const balanceUni2 = (await ects.balanceOf(accounts[1])).toString();
        const balanceAlu2 = (await ects.balanceOf(accounts[3])).toString();
        const balanceAluXUni2 = (await ects.getTokenAlumnoPorUniversidad(accounts[3], accounts[1], { from: accounts[0] })).toString();

        assert.equal(parseInt(balanceUni) + parseInt(ectsNecesarios), balanceUni2);
        assert.equal(parseInt(balanceAlu) - parseInt(ectsNecesarios), balanceAlu2);
        assert.equal(parseInt(balanceAluXUni) - parseInt(ectsNecesarios), balanceAluXUni2);

        // obtener el erc721 del alumno cuyo propietario es la universidad
        const ownerTokenERC721 = await a.ownerOf(1);
        assert.equal(ownerTokenERC721, accounts[1]);

        // verificar que el balance de la universidad es 1
        const balanceOfUni = (await a.balanceOf(accounts[1])).toString();
        assert.equal(1, balanceOfUni);
    });

    it("profesor::evaluar nota final de asignatura::suspenso", async() => {
        // registrar las entidades del sistema
        await estado.registrarUniversidad(accounts[1], "UNIR", { from: accounts[0] });
        await estado.registrarProfesor(accounts[2], "Javier Montesinos", { from: accounts[0] });
        await estado.registrarAlumno(accounts[3], "Keti Crespo", { from: accounts[0] });

        // adquirir tokens el alumno a la universidad
        const creditos = 10;
        const weis = (await estado.calcularCreditosToWeis(accounts[1], creditos)).toString();
        await estado.comprarTokens(accounts[1], creditos, { from: accounts[3], value: weis });

        // crear una asignatura por parte del estado
        const creditosAsignatura = 7;
        const experimentabilidad = 0;
        await estado.crearAsignatura("Calculo 1", "CAL1", creditosAsignatura, experimentabilidad);
        const asignaturas = await estado.getAsignaturas();
        let a = await AsignaturaToken.at(asignaturas[0]);

        // registrar una universidad y profesor para la asignatura
        await a.registrarUniversidadProfesor(accounts[1], accounts[2], { from: accounts[0] });

        // matricular
        await a.matricular(accounts[1], '19-20', { from: accounts[3] });
        const matriculaId = 1;

        const notaFinal = 400;
        await a.evaluar(accounts[3], matriculaId, notaFinal, { from: accounts[2] });
        const matricula = await a.getMatricula(matriculaId);
        const nota = parseInt(matricula.nota.toString());
        const aprobado = matricula.aprobado;
        const evaluado = matricula.evaluado;

        // verificar la nota correctamente
        assert.equal(nota, notaFinal);
        // verificar que ya está evaluado
        assert.equal(evaluado, true);
        // verificar que ya está evaluado
        assert.equal(aprobado, false);
    });

    it("profesor::evaluar nota final de asignatura::aprobado", async() => {
        // registrar las entidades del sistema
        await estado.registrarUniversidad(accounts[1], "UNIR", { from: accounts[0] });
        await estado.registrarProfesor(accounts[2], "Javier Montesinos", { from: accounts[0] });
        await estado.registrarAlumno(accounts[3], "Keti Crespo", { from: accounts[0] });

        // adquirir tokens el alumno a la universidad
        const creditos = 10;
        const weis = (await estado.calcularCreditosToWeis(accounts[1], creditos)).toString();
        await estado.comprarTokens(accounts[1], creditos, { from: accounts[3], value: weis });

        // crear una asignatura por parte del estado
        const creditosAsignatura = 7;
        const experimentabilidad = 0;
        await estado.crearAsignatura("Calculo 1", "CAL1", creditosAsignatura, experimentabilidad);
        const asignaturas = await estado.getAsignaturas();
        let a = await AsignaturaToken.at(asignaturas[0]);

        // registrar una universidad y profesor para la asignatura
        await a.registrarUniversidadProfesor(accounts[1], accounts[2], { from: accounts[0] });

        // matricular
        await a.matricular(accounts[1], '19-20', { from: accounts[3] });
        const matriculaId = 1;

        const notaFinal = 700;
        await a.evaluar(accounts[3], matriculaId, notaFinal, { from: accounts[2] });
        const matricula = await a.getMatricula(matriculaId);
        const nota = parseInt(matricula.nota.toString());
        const aprobado = matricula.aprobado;
        const evaluado = matricula.evaluado;

        // verificar la nota correctamente
        assert.equal(nota, notaFinal);
        // verificar que ya está evaluado
        assert.equal(evaluado, true);
        // verificar que ya está evaluado
        assert.equal(aprobado, true);

        // obtener el erc721 del alumno cuyo propietario debe ser el alumno
        const ownerTokenERC721 = await a.ownerOf(1);
        assert.equal(ownerTokenERC721, accounts[3]);

        // verificar que el balance de la alumno es 1
        const balanceOfAlu = (await a.balanceOf(accounts[3])).toString();
        assert.equal(1, balanceOfAlu);
    });

    it("alumno::solicitar traslado de asignatura", async() => {
        // registrar las entidades del sistema
        await estado.registrarUniversidad(accounts[1], "UNIR", { from: accounts[0] });
        await estado.registrarProfesor(accounts[2], "Javier Montesinos", { from: accounts[0] });
        await estado.registrarAlumno(accounts[3], "Keti Crespo", { from: accounts[0] });
        await estado.registrarUniversidad(accounts[4], "UNEX", { from: accounts[0] });

        // adquirir tokens el alumno a la universidad
        const creditos = 10;
        const weis = (await estado.calcularCreditosToWeis(accounts[1], creditos)).toString();
        await estado.comprarTokens(accounts[1], creditos, { from: accounts[3], value: weis });

        // crear una asignatura por parte del estado
        const creditosAsignatura = 7;
        const experimentabilidad = 0;
        await estado.crearAsignatura("Calculo 1", "CAL1", creditosAsignatura, experimentabilidad);
        const asignaturas = await estado.getAsignaturas();
        let a = await AsignaturaToken.at(asignaturas[0]);

        // registrar una universidad y profesor para la asignatura
        await a.registrarUniversidadProfesor(accounts[1], accounts[2], { from: accounts[0] });

        // matricular
        await a.matricular(accounts[1], '19-20', { from: accounts[3] });
        const matriculaId = 1;

        const notaFinal = 700;
        await a.evaluar(accounts[3], matriculaId, notaFinal, { from: accounts[2] });

        // trasladar a la universidad UNED la asignatura
        await a.trasladar(matriculaId, accounts[4], { from: accounts[3] });

        // obtener el erc721 del alumno cuyo propietario debe ser la universidad
        const ownerTokenERC721 = await a.ownerOf(1);
        assert.equal(ownerTokenERC721, accounts[4]);

        // verificar que el balance de la universidad uned es 1
        const balanceOfAlu = (await a.balanceOf(accounts[4])).toString();
        assert.equal(1, balanceOfAlu);

        // verificar que consta la universidad en la matricula del alumno
        const matricula = await a.getMatricula(matriculaId);
        assert.equal(accounts[4], matricula.universidad);
    });

});