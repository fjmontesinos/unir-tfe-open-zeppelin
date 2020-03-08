pragma solidity ^0.5.0;

import "./entidades/Universidades.sol";
import "./entidades/Profesores.sol";
import "./entidades/Alumnos.sol";
import "./token/ERC20/ECTSToken.sol";
import "./token/ERC721/AsignaturaToken.sol";

contract Estado is Universidades, Profesores, Alumnos {

    address private _owner;
    ECTSToken private _ectsToken;

    mapping (address => bool) _asignaturas;
    address[] _asignaturasList;

    event UniversidadRegistrada(address _cuenta, string _nombre, uint256 _precioCredito);
    event AlumnoRegistrado(address _cuenta, string _nombre);
    event ProfesorRegistrado(address _cuenta, string _nombre);
    event TokensComprados(address _alumno, address _universidad, uint256 _tokens);

    constructor(address _ectsTokenAddress) public {
        _ectsToken = ECTSToken(_ectsTokenAddress);
        _owner = msg.sender;
    }

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
    function registrarUniversidad(address _cuenta, string memory _nombre) public onlyOwner {
        require(!universidades[_cuenta].valido, 'Universidad ya registrada');
        require(_cuenta != address(0), 'Dirección 0x no permitida');

        uint256 precioBase = _ectsToken.getPrecioBaseECTSToken();
        universidades[_cuenta] = Universidad(_cuenta, _nombre, precioBase,
            [uint256(100), uint256(100), uint256(100), uint256(100)],
            [uint256(100), uint256(100), uint256(100), uint256(100)],
            true);
        univesidadesList.push(_cuenta);

        // Se inicializan los créditos que la universidad podrá utilizar para ofertar sus asignaturas
        _ectsToken.transferFrom(_owner, _cuenta, _ectsToken.getCreditosInicialesUniversidad());

        emit UniversidadRegistrada(_cuenta, _nombre, precioBase);
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
    function registrarAlumno(address _cuenta, string memory _nombre) public onlyOwner {
        require(!alumnos[_cuenta].valido, 'Alumno ya registrado');
        require(_cuenta != address(0), 'Dirección 0x no permitida');

        alumnos[_cuenta] = Alumno(_cuenta, _nombre, true);
        alumnosList.push(_cuenta);

        emit AlumnoRegistrado(_cuenta, _nombre);
    }

    /**
     *
     *
     */
    function registrarProfesor(address _cuenta, string memory _nombre) public onlyOwner {
        require(!profesores[_cuenta].valido, 'Profesor ya registrado');
        require(_cuenta != address(0), 'Dirección 0x no permitida');

        profesores[_cuenta] = Profesor(_cuenta, _nombre, true);
        profesoresList.push(_cuenta);

        emit ProfesorRegistrado(_cuenta, _nombre);
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
    function comprarTokens(address payable _universidad, uint256 _creditos) public payable {
        require(alumnos[msg.sender].valido, 'Alumno no registrado');
        require(universidades[_universidad].valido, 'Universidad no registrada');
        require(msg.value == calcularCreditosToWeis(_universidad, _creditos), 'El ether debe ser exacto');

        // trasnferir los tokens al alumno
        _ectsToken.transferFrom(_universidad, msg.sender, _creditos.mul(ectsTokenDecimals));

        // transfer el ether a la universidad
        _universidad.transfer(msg.value);

        emit TokensComprados(msg.sender, _universidad, _creditos.mul(ectsTokenDecimals));
    }

    function transferTokens(address _from, address _to, uint256 _amount) public {
        // pasar los tokens del alumno a la universidad
        _ectsToken.transferFrom(_from, _to, _amount);
    }

    /**
     * @dev Crea nuevas asignaturas
     *
     **/
    function crearAsignatura(string memory _name, string memory _symbol, uint256 _creditos, uint256 _experimentabilidad) public onlyOwner returns (address) {
        AsignaturaToken asignaturaSC = new AsignaturaToken(_name, _symbol, _creditos, _experimentabilidad, _owner, address(this));

        _asignaturasList.push(address(asignaturaSC));
        _asignaturas[address(asignaturaSC)] = true;
        return address(asignaturaSC);
    }

    modifier onlyOwner(){
        require(msg.sender == _owner, 'Ownable: caller is not the owner');
        _;
    }

}
