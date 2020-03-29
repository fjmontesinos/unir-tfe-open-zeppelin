pragma solidity ^0.5.0;

contract Alumnos {

    struct Alumno {
        address cuenta;
        bool valido; // comprueba si el miembro es Ok.
    }

    // Mapa que recoge los alumnos disponibles en el sistema
    mapping(address => Alumno) alumnos;

    // Array que nos permita iterar por todos los alumnos
    address[] alumnosList;

    /**
     * @dev Obtener un listado que nos permita iterar por todos los alumnos
     *
     */
    function getAlumnos() public view returns (address[] memory) {
        return alumnosList;
    }

    /**
     * @dev Modificador para verificar que la cuenta pasada como parámetros es un alumno valido
     *
     */
    function isAlumno(address _cuenta) public view returns (bool){
        return alumnos[_cuenta].valido;
    }

}