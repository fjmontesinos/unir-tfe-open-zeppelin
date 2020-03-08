pragma solidity ^0.5.0;

contract Profesores {

    struct Profesor {
        address cuenta;
        string nombre;
        bool valido; // comprueba si el miembro es Ok.
    }

    // Mapa que recoge los profesores disponibles en el sistema
    mapping(address => Profesor) profesores;

    // obtener un listado que nos permita iterar por todos los profesores
    address[] profesoresList;

    function getProfesores() public view returns (address[] memory) {
        return profesoresList;
    }

    function getProfesor(address _cuenta) public view returns (string memory) {
        require(profesores[_cuenta].valido, 'Profesor no registrado');
        return (profesores[_cuenta].nombre);
    }

    function isProfesor(address _cuenta) public view returns (bool){
        return profesores[_cuenta].valido;
    }

}