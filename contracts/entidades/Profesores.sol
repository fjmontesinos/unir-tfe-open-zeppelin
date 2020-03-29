pragma solidity ^0.5.0;

contract Profesores {

    struct Profesor {
        address cuenta;
        bool valido; // comprueba si el miembro es Ok.
    }

    // Mapa que recoge los profesores disponibles en el sistema
    mapping(address => Profesor) profesores;

    // array que nos permita iterar por todos los profesores
    address[] profesoresList;

    /**
     * @dev Obtener un listado que nos permita iterar por todos los profesores
     *
     */
    function getProfesores() public view returns (address[] memory) {
        return profesoresList;
    }

    /**
     * @dev Modificador para verificar que la cuenta pasada como parámetros es un profesor valido
     *
     */
    function isProfesor(address _cuenta) public view returns (bool){
        return profesores[_cuenta].valido;
    }

}