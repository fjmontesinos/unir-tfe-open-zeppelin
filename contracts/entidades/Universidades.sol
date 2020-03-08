pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract Universidades {
    using SafeMath for uint256;
    
    uint256 ectsTokenDecimals = 10 ** uint256(4);

    event PrecioExperimentabilidadActualizado(address _cuenta, uint8 _tipoPrecio, uint256 _precio);
    event PrecioAnioMatriculaActualizado(address _cuenta, uint8 _anio, uint256 _precio);
    event PrecioCreditoActualizado(address _cuenta, uint256 _precioCredito);

    struct Universidad {
        address cuenta;
        string nombre;
        uint256 precioCredito;
        uint256[4] preciosExperimentabilidad;
        uint256[4] preciosAnioMatricula;
        bool valido; // comprueba que la universidad es Ok.
    }

    // Mapa que recoge las universidades disponibles en el sistema
    mapping(address => Universidad) universidades;

    // obtener un listado que nos permita iterar por todas las universidades
    address[] univesidadesList;

    function getUniversidades() public view returns (address[] memory) {
        return univesidadesList;
    }

    /**
     * @dev Obtiene para la cuenta facilitada como parámetro nombre de la universidad
     *
     * Validaciones:
     *
     * - `_cuenta` debe corresponder con una universidad registrada y valida
     */
    function getUniversidad(address _cuenta) public view returns (string memory, uint256) {
        require(universidades[_cuenta].valido, 'Universidad no registrada');
        return (universidades[_cuenta].nombre,
            universidades[_cuenta].precioCredito);
    }

    /**
     * @dev Obtiene para la cuenta facilitada como parámetro los factores de correción de precio de matricula por experimentabilidad
     *
     * Validaciones:
     *
     * - `_cuenta` debe corresponder con una universidad registrada y valida
     */
    function getUniPreciosExperimentabilidad(address _cuenta) public view returns (string memory, uint256, uint256, uint256, uint256) {
        require(universidades[_cuenta].valido, 'Universidad no registrada');
        return (universidades[_cuenta].nombre,
            universidades[_cuenta].preciosExperimentabilidad[0],
            universidades[_cuenta].preciosExperimentabilidad[1],
            universidades[_cuenta].preciosExperimentabilidad[2],
            universidades[_cuenta].preciosExperimentabilidad[3]);
    }

    /**
     * @dev Obtiene para la cuenta facilitada como parámetro los factores de correción de precio de matricula por año
     *
     * Validaciones:
     *
     * - `_cuenta` debe corresponder con una universidad registrada y valida
     */
    function getUniPreciosAnioMatricula(address _cuenta) public view returns (string memory, uint256, uint256, uint256, uint256) {
        require(universidades[_cuenta].valido, 'Universidad no registrada');
        return (universidades[_cuenta].nombre,
            universidades[_cuenta].preciosAnioMatricula[0],
            universidades[_cuenta].preciosAnioMatricula[1],
            universidades[_cuenta].preciosAnioMatricula[2],
            universidades[_cuenta].preciosAnioMatricula[3]);
    }

    /**
     * @dev Actualiza para la cuenta facilitada como parámetro los factores de correción de precio de matricula por experimentabilidad
     *
     * Emite el evento {PrecioExperimentabilidadActualizado} indicando el precio actualizado
     *
     * Validaciones:
     *
     * - `_tipo` debe ser un valor entre 0 y 3. Siendo 0 = grado de experimentabilidad 1 y 3 = grado 4
     * - `_precio` debe ser un valor entre 0 y 999
     */
    function updatePrecioExperimentabilidad(uint8 _tipo, uint256 _precio) public onlyUniversidad {
        require( ( (_tipo >=0) && (_tipo<=3) ), 'Expermientabilidad incorrecto: 0-3');
        require( ( (_precio >=0) && (_precio<=999) ), 'Precio incorrecto: 0-999');

        universidades[msg.sender].preciosExperimentabilidad[_tipo] = _precio;

        emit PrecioExperimentabilidadActualizado(msg.sender, _tipo, _precio);
    }

    /**
     * @dev Actualiza para la cuenta facilitada como parámetro los factores de correción de precio de matricula por año de matrícula
     *
     * Emite el evento {PrecioAnioMatriculaActualizado} indicando el precio actualizado
     *
     * Validaciones:
     *
     * - `_tipo` debe ser un valor entre 0 y 3. Siendo 0 = año de matrícula 1 y 3 = año de matrícula 4 y sucesivos
     * - `_precio` debe ser un valor entre 0 y 999
     */
    function updatePrecioAnioMatricula(uint8 _anio, uint256 _precio) public onlyUniversidad {
        require( ( (_anio >=0) && (_anio<=3) ), 'Año incorrecto: 0-3');
        require( ( (_precio >=0) && (_precio<=999) ), 'Precio incorrecto: 0-999');

        universidades[msg.sender].preciosAnioMatricula[_anio] = _precio;

        emit PrecioAnioMatriculaActualizado(msg.sender, _anio, _precio);
    }
    
    /**
     * @dev Actualiza para la cuenta facilitada como parámetro el recargo en wei por traspaso de asignatura
     *
     * Emite el evento {FeedTraspasoActualizado} indicando el precio actualizado
     *
     */
    function updatePrecioCredito(uint256 _precioCredito) public onlyUniversidad {
        universidades[msg.sender].precioCredito = _precioCredito;
        emit PrecioCreditoActualizado(msg.sender, _precioCredito);
    }

    /**
     * @dev Calcula el precio en weis de los créditos que se desean adquirir para una Universidad Concreta
     *
     * Validaciones:
     *
     * - `_cuenta` debe corresponder con una universidad registrada y valida
     */
    function calcularCreditosToWeis(address _universidad, uint256 _creditos) public view returns (uint256) {
        require(universidades[_universidad].valido, 'Universidad no registrada');
        return _creditos.mul(ectsTokenDecimals).mul(universidades[_universidad].precioCredito);
    }
    
    /**
     * @dev Calcula el total de Tokens ECTSToken necesarios para matricularnos en una universidad en una asignatura, con 
     * un grado de experimentabilidad concreto, en un año de matrícula concreto y para la cual se necesitan unos créditos concretos.
     *
     * Validaciones:
     *
     * - `_cuenta` debe corresponder con una universidad registrada y valida
     */
    function calcularECTSTokensParaAsignatura(address _universidad,
        uint256 _experimentabilidad, uint256 _anioMatricula, uint256 _creditos) public view returns (uint256) {
        require(universidades[_universidad].valido, 'Universidad no registrada');
        require(_creditos > 0, 'Créditos debe ser > 0');
        
        return _creditos.mul(universidades[_universidad].preciosExperimentabilidad[_experimentabilidad].mul(universidades[_universidad].preciosAnioMatricula[_anioMatricula]));
    }
    
    function isUniversidad(address _cuenta) public view returns (bool){
        return universidades[_cuenta].valido;
    }
    
    /**
     * Modificador para verificar que la cuenta corresponde con una universidad valida
     * */
    modifier onlyUniversidad() {
        if ( universidades[msg.sender].valido ) {
            _;
        }
    }

}