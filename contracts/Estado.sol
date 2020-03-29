pragma solidity ^0.5.0;

import "./entidades/Universidades.sol";
import "./entidades/Profesores.sol";
import "./entidades/Alumnos.sol";
import "./token/ERC20/ECTSToken.sol";
import "./token/ERC721/AsignaturaToken.sol";

contract Estado is Universidades, Profesores, Alumnos {

    // owner del sc
    address private _owner;

    // instancia del sc asociado a los tokens ERC20 ECTSToken
    ECTSToken private _ectsToken;

    // registro de asignaturas mintadas on-chain
    mapping (address => bool) _asignaturas;
    // array de asignaturas para recuperar todas las asignaturas mintadas
    address[] _asignaturasList;

    // eventos
    event UniversidadRegistrada(address _cuenta, uint256 _precioCredito);
    event AlumnoRegistrado(address _cuenta);
    event ProfesorRegistrado(address _cuenta);
    event TokensComprados(address _alumno, address _universidad, uint256 _tokens);
    event AsignaturaCreada(address asignatura, string nombre, string simbolo, uint256 creditos, uint256 experimentabilidad);

    constructor(address _ectsTokenAddress) public {
        _ectsToken = ECTSToken(_ectsTokenAddress);
        _owner = msg.sender;
    }

    /**
     * @dev Retorna el array de las direcciones de los SC de asignaturas creadas
     *
     */
    function getAsignaturas() public view returns (address[] memory) {
        return _asignaturasList;
    }

    /**
     * @dev Registra una universidad en el sistema, el sistema la asigna una cantidad inicial de tokens ECTS para
     * las matrículas de sus alumnos
     *
     * Emite el evento {UniversidadRegistrada} indicando la universidad que se ha registrado
     *
     * Validaciones:
     *
     * - `_cuenta` No debe corresponder con una universidad ya registrada
     */
    function registrarUniversidad(address _cuenta) public onlyOwner {
        require(!universidades[_cuenta].valido, 'Universidad ya registrada');
        require(_cuenta != address(0), 'Dirección 0x no permitida');

        uint256 precioBase = _ectsToken.getPrecioBaseECTSToken();
        universidades[_cuenta] = Universidad(_cuenta, precioBase,
            [uint256(100), uint256(110), uint256(120), uint256(130)],
            [uint256(100), uint256(110), uint256(120), uint256(130)],
            true);
        univesidadesList.push(_cuenta);

        // Se inicializan los créditos que la universidad podrá utilizar para ofertar sus asignaturas
        _ectsToken.transferFrom(_owner, _cuenta, _ectsToken.getTokensInicialesUniversidad());

        emit UniversidadRegistrada(_cuenta, precioBase);
    }

    /**
     * @dev Registra un alumno en el sistema
     *
     * Emite el evento {AlumnoRegistrado} indicando el alumno que se ha registrado
     *
     * Validaciones:
     *
     * - `_cuenta` No debe corresponder con un alumno ya registrado
     */
    function registrarAlumno(address _cuenta) public onlyOwner {
        require(!alumnos[_cuenta].valido, 'Alumno ya registrado');
        require(_cuenta != address(0), 'Dirección 0x no permitida');

        alumnos[_cuenta] = Alumno(_cuenta, true);
        alumnosList.push(_cuenta);

        emit AlumnoRegistrado(_cuenta);
    }

    /**
     * @dev Registra un profesor en el sistema
     *
     * Emite el evento {ProfesorRegistrado} indicando el profesor que se ha registrado
     *
     * Validaciones:
     *
     * - `_cuenta` No debe corresponder con un profesor ya registrado
     */
    function registrarProfesor(address _cuenta) public onlyOwner {
        require(!profesores[_cuenta].valido, 'Profesor ya registrado');
        require(_cuenta != address(0), 'Dirección 0x no permitida');

        profesores[_cuenta] = Profesor(_cuenta, true);
        profesoresList.push(_cuenta);

        emit ProfesorRegistrado(_cuenta);
    }

    /**
     * @dev Permite a un alumno comprar ETCSToken para matricularse en una asignatura en la univeridad
     *
     * Emite el evento {TokensComprados} indicando el alumno que compra los tokens, la universidad a la que los compra y el total de tokens comprados
     *
     * Validaciones:
     *
     * - `_universidad` debe corresponder con una universidad registrada y valida
     * - `msg.sender` debe corresponder con un alumno registrado y valido
     * - `msg.value` debe corresponder de forma exacta con el precio en weis de los tokens vendidos por la universidad
     */
    function comprarTokens(address payable _universidad, uint256 _tokens) public payable {
        require(alumnos[msg.sender].valido, 'Alumno no registrado');
        require(universidades[_universidad].valido, 'Universidad no registrada');
        require(msg.value == calcularTokensToWeis(_universidad, _tokens), 'El ether debe ser exacto');

        // trasnferir los tokens al alumno
        _ectsToken.transferFrom(_universidad, msg.sender, _tokens);

        // transfer el ether a la universidad
        _universidad.transfer(msg.value);

        emit TokensComprados(msg.sender, _universidad, _tokens);
    }

    /**
     * @dev Crea nueva asignatura
     *
     * Emite el evento {AsignaturaCreada} indicando la dirección del SC asociado a la asignatura creada, su nombre, símbolo, cŕeditos y la experimentalidad
     *
     * Validaciones:
     *
     * - `msg.sender` debe corresponder con el owner del contrato
     **/
    function crearAsignatura(string memory _name, string memory _symbol, uint256 _creditos, uint256 _experimentabilidad) public onlyOwner returns (address) {
        AsignaturaToken asignaturaSC = new AsignaturaToken(_name, _symbol, _creditos, _experimentabilidad, _owner, address(this));

        _asignaturasList.push(address(asignaturaSC));
        _asignaturas[address(asignaturaSC)] = true;

        address a = address(asignaturaSC);

        emit AsignaturaCreada(a, _name, _symbol, _creditos, _experimentabilidad);

        return address(asignaturaSC);
    }

    /**
     * @dev Transfiere tokens ECTS de una dirección a otra para que al matricular en una asignatura se puedan pasar los tokens de un alumno a una universidad
     *
     * Validaciones:
     *
     * - `msg.sender` debe corresponder con un sc registrado como asignatura ERC721
     **/
    function transferECTSTokens(address _from, address _to, uint256 _amount) public {
        require(_asignaturas[msg.sender] == true, 'Sender debe ser una asignatura registrada');

        // pasar los tokens del alumno a la universidad
        _ectsToken.transferFrom(_from, _to, _amount);
    }

    /**
     * @dev Transfiere tokens AsignaturaToken (ERC721) de una dirección a otra cuando se aprueba una asignatura o cuano se solicita un traslado
     *
     * Validaciones:
     *
     * - `msg.sender` debe corresponder con un sc registrado como asignatura ERC721
     **/
    function transferAsginaturaToken(address _from, address _to, uint256 _matriculaId) public {
        require(_asignaturas[msg.sender] == true, 'Sender debe ser una asignatura registrada');

        AsignaturaToken asignaturaSC = AsignaturaToken(msg.sender);
        // pasar el token el alumno a la univesidad
        asignaturaSC.transferFrom(_from, _to, _matriculaId);
    }

    /**
     * @dev Modificador para verificar que la dirección que realiza una llamada es el owner del contrato
     *
     * Validaciones:
     *
     * - `msg.sender` debe corresponder con un sc registrado como asignatura ERC721
     **/
    modifier onlyOwner(){
        require(msg.sender == _owner, 'Ownable: caller is not the owner');
        _;
    }

}
