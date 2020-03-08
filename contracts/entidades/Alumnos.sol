pragma solidity ^0.5.0;

contract Alumnos {

    struct Alumno {
        address cuenta;
        string nombre;
        bool valido; // comprueba si el miembro es Ok.
    }

    // Mapa que recoge los alumnos disponibles en el sistema
    mapping(address => Alumno) alumnos;

    // obtener un listado que nos permita iterar por todos los alumnos
    address[] alumnosList;

    function getAlumnos() public view returns (address[] memory) {
        return alumnosList;
    }

    function getAlumno(address _cuenta) public view returns (string memory) {
        require(alumnos[_cuenta].valido, 'Alumno no registrado');
        return (alumnos[_cuenta].nombre);
    }

    function isAlumno(address _cuenta) public view returns (bool){
        return alumnos[_cuenta].valido;
    }

}