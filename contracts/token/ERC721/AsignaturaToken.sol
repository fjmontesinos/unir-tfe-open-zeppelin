pragma solidity ^0.5.0;

import "@openzeppelin/contracts/drafts/Counters.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./ERC721Metadata.sol";

contract AsignaturaToken is ERC721Metadata {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    // owner del contrato
    address private _owner;
    // cŕeditos que supone realizar la asginatura
    uint256 private _creditos;
    // grado de experimentalidad de la asignatura, valor entre 0 y 3
    uint256 private _experimentabilidad;
    // nota mínima para aprobar basada en dos decimales, i.e. 500 = 5
    uint256 internal _notaMinimaAprobado = 500;

    struct Asignatura {
        address universidad;
        address profesor;
        address alumno;
        string cursoAcademico;
        uint256 anioMatricula;
        uint256 nota;
        bool aprobado;
        bool evaluado;
        bool valida;
    }

    // matrículas registradas on-chain
    mapping (uint256 => Asignatura) private _matriculas;
    // años de matrícula por alumno para calcular el precio seǵun el año de matrícula
    mapping (address => uint256) private _aniosMatricula;
    // configuración de profesores por asignatura para cada universidad
    mapping (address => address) private _universidadesProfesores;

    // eventos
    event UniversidadRegistrada(address universidad, address profesor, address asignatura);
    event AlumnoMatriculado(address universidad, address profesor, address asignatura,
                            address alumno, string cursoAcademico, uint256 matriculaId);

    constructor(string memory name, string memory symbol, uint256 creditos, uint256 experimentabilidad, address owner, address estadoAddress)
        ERC721Metadata(name, symbol)
        public {
            require(experimentabilidad <= 3, 'Experimentabilidad incorrecto: 0-3');
            _creditos = creditos;
            _experimentabilidad = experimentabilidad;
            _owner = owner;
            setEstado(estadoAddress);
        }

    /**
     * @dev Permite minteado de un nuevo token ERC721 para un alumno en el momento de matricularese un alumno en una asignatura.
     *
     */
    function mintMatricula(address universidad, address profesor, address alumno, string memory cursoAcademico) internal returns (uint256) {
        _tokenIds.increment();

        uint256 nuevaMatriculaId = _tokenIds.current();
        _mint(universidad, nuevaMatriculaId);

        _matriculas[nuevaMatriculaId] = Asignatura(universidad, profesor, alumno, cursoAcademico,
            _aniosMatricula[alumno], uint256(0), false, false, true);

        _aniosMatricula[alumno]++;

        return nuevaMatriculaId;
    }

    /**
    * @dev Permite al owner de la asignatura registrar una universidad y un profesor en ella.
    *
    * Validaciones:
    *
    * - `universidad` Debe corresponder con una universidad registrada
    * - `profesor` Debe corresponder con un profesor registrado
    *
    */
    function registrarUniversidadProfesor(address universidad, address profesor) public onlyOwner {
        require(_estadoSC.isUniversidad(universidad), "Universidad no registrada");
        require(_estadoSC.isProfesor(profesor), "Profesor no registrado");
        _universidadesProfesores[universidad] = profesor;
    }

    /**
     * @dev Retorna el profesor configurado para una universidad
     *
     */
    function getProfesorUniversidad(address universidad) public view returns (address) {
        return _universidadesProfesores[universidad];
    }

    /**
     * @dev Permite actualizar el profesor de una asignatura en una universidad
     *
     * Validaciones:
     *
     * - `msg.sender` Debe corresponder con una universidad registrada
     * - `profesor` Debe corresponder con un profesor registrado
     * - `msg.sender` NO debe corresponder con una universidad registrada ya en la asignatura
     *
     */
    function updateProfesor(address _profesor) public {
        require(_estadoSC.isUniversidad(msg.sender), "Universidad no registrada");
        require(_estadoSC.isProfesor(_profesor), "Profesor no registrado");
        require(_universidadesProfesores[msg.sender] != address(0), 'Universidad no registrada en la asignatura');

        _universidadesProfesores[msg.sender] = _profesor;
    }


    /**
     * @dev Retorna el año de matŕicula que corresponde a un alumno pasado como parámetro
     *
     */
    function getAnioMatricula(address _alumno) public view returns (uint256) {
        if(_aniosMatricula[_alumno] >= 3) return 3;
        else return _aniosMatricula[_alumno];
    }

    /**
     * @dev Throws si se llama por una cuenta que el owner del token.
     *
     */
    modifier onlyOwner(){
        require(msg.sender == _owner, 'Ownable: caller is not the owner');
        _;
    }

    /**
    * @dev Permite a un alumno matricularse en el sistema previo pago de los tokens necesarios
    *
    * Validaciones:
    *
    * - `universidad` Debe corresponder con una universidad registrada
    * - `msg.sender` Debe corresponder con un alumno registrado
    * - `universidad` Debe corresponder con una universidad registrada ya en la asignatura
    *
    */
    function matricular(address universidad, string memory cursoAcademico) public returns (uint256) {
        require(_estadoSC.isUniversidad(universidad), 'Universidad no registrada');
        require(_estadoSC.isAlumno(msg.sender), 'Alumno no registrado');
        require(_universidadesProfesores[universidad] != address(0), 'Profesor no configurado');

        uint256 anioMatricula = getAnioMatricula(msg.sender);

        // obtener los tokens que el alumno debe entregar por la matrícula en la asignatura
        uint256 ectsNecesarios = _estadoSC.calcularECTSTokensParaAsignatura(universidad, _experimentabilidad, anioMatricula, _creditos);

        // trasnferir los tokens
        _estadoSC.transferECTSTokens(msg.sender, universidad, ectsNecesarios);

        uint256 matriculaId = mintMatricula(universidad, _universidadesProfesores[universidad], msg.sender, cursoAcademico);

        emit AlumnoMatriculado(universidad, _universidadesProfesores[universidad], address(this), msg.sender, cursoAcademico, matriculaId);

        // crear la matricula
        return matriculaId;
    }

    /**
     * @dev Retorna una matŕicula por su id, retorna la universidad, el profesor, el alumno, la nota, si está evaluado o no y
     * en el caso de estar evaluado si está aprobada
     *
     */
    function getMatricula(uint256 matriculaId) public view returns (address universidad,
                                                                    address profesor, address alumno,
                                                                    uint256 nota, bool aprobado,
                                                                    bool evaluado) {
        require(_matriculas[matriculaId].valida, 'Matriculo no registrada');
        return (_matriculas[matriculaId].universidad, _matriculas[matriculaId].profesor, _matriculas[matriculaId].alumno,
            _matriculas[matriculaId].nota, _matriculas[matriculaId].aprobado, _matriculas[matriculaId].evaluado);
    }

    /**
     * @dev Solicitar traslado de la matrícula a otra universidad
     *
     * Validaciones:
     *
     * - `matriculaId` Debe corresponder con una matrícula correcta y no evaluada
     * - `alumno` Debe corresponder con el alumno asociado a la matrícula
     * - `msg.sender` Debe corresponder con el profesor asociado a la matrícula y debe existir como profesor registrado en el sistema
     * - `universidad` Debe corresponder con una universidad registrada ya en la asignatura
     * - `nota` Nota debe ser <= 1000
     *
     */
    function evaluar(address alumno, uint256 matriculaId, uint256 nota) public {
        require(_matriculas[matriculaId].valida, 'Matrícula no valida');
        require(_matriculas[matriculaId].alumno == alumno, 'Matrícula no pertenece al alumno');
        require(_matriculas[matriculaId].profesor == msg.sender, 'Profesor no asociado a la Matrícula');
        require(_estadoSC.isProfesor(msg.sender), 'Profesor no registrado');
        require(_matriculas[matriculaId].evaluado == false, 'Asignatura ya evaluada');
        require(nota <= 1000, 'Nota máxima 10 (10000)');

        _matriculas[matriculaId].nota = nota;
        _matriculas[matriculaId].evaluado = true;

        // si se ha aprobado la asignatura se transfiere el token al alumno
        if(nota >= _notaMinimaAprobado) {
            _matriculas[matriculaId].aprobado = true;
            // traspasar el token de la universidad al alumno
            _estadoSC.transferAsginaturaToken(_matriculas[matriculaId].universidad, alumno, matriculaId);
        }
    }

    /**
     * @dev Solicitar traslado de la matrícula a otra universidad
     *
     * Validaciones:
     *
     * - `matriculaId` Debe corresponder con una matrícula correcta y aprobada
     * - `universidadDestino` Debe corresponder con una universidad registrada en el sistema
     * - `msg.sender` Debe corresponder con el alumno asociado a la matrícula y debe existir como alumno registrado en el sistema
     * - `universidadDestino` Debe corresponder con una universidad registrada ya en la asignatura
     *
     */
    function trasladar(uint256 matriculaId, address universidadDestino) public {
        require(_estadoSC.isAlumno(msg.sender), 'Alumno no registrado');
        require(_estadoSC.isUniversidad(universidadDestino), 'Universidad no registrada');
        require(_matriculas[matriculaId].aprobado, 'Matrícula no aprobada');
        require(_matriculas[matriculaId].alumno == msg.sender, 'Matrícula no pertenece al alumno');
        require(_universidadesProfesores[universidadDestino] != address(0), 'La universidad no ofrece esta asignatura');

        _matriculas[matriculaId].universidad = universidadDestino;

        _estadoSC.transferAsginaturaToken(msg.sender, universidadDestino, matriculaId);
    }

}