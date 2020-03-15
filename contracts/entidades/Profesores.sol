pragma solidity ^0.5.0;

contract Profesores {

    struct Profesor {
        address cuenta;
        bool valido; // comprueba si el miembro es Ok.
    }

    // Mapa que recoge los profesores disponibles en el sistema
    mapping(address => Profesor) profesores;

    // obtener un listado que nos permita iterar por todos los profesores
    address[] profesoresList;

    function getProfesores() public view returns (address[] memory) {
        return profesoresList;
    }

    function isProfesor(address _cuenta) public view returns (bool){
        return profesores[_cuenta].valido;
    }

}