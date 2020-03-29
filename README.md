# TFE - Experto Universitario en Desarrollo de Aplicaciones Blockchain

Este repositorio recoge el desarrollo blockchain del TFE elaborado en el Experto Universitario en Desarrollo de Aplicaciones Blockchain en la Universidad UNIR de la promoción de octubre / 2019 a marzo / 2020

En la carpeta docs se recoge la memoria del proyecto; [Memoria TFE Javier Montesinos](https://github.com/fjmontesinos/unir-tfe-open-zeppelin/tree/master/docs)

El objetivo principal del proyecto es establecer un sistema basado en blockchain que permita la digitalización de títulos académicos basandonos en el uso de tokens ERC20 para la matriculación en las diferentes asignaturas que componen un grado y de tokens ERC721 para identificar las asignaturas aprobadas por los alumnos.

## Tests 

A continuación se recogen diferentes ejemplos de pruebas que se pueden realizar desde truffle console. No obstante estas pruebas se encuentran recogidas en los [tests](https://github.com/fjmontesinos/unir-tfe-open-zeppelin/tree/master/test) correspondientes del proyecto y se pueden lanzar mediante el comando:

```console
$ truffle test --network development --reset
```

### 1. Desplegar los SC
Desplegar SC Token ERC20 ECTSToken
Desplegar SC Administracion (informando address del SC ECTSToken)
Establecer address estado en el SC ECTSToken

```console
$ truffle migration --network development --reset
```

### 2. Registrar entidades
Cargar la instancia del contrato:

```console
$ truffle console
$ truffle(development)> let i = await Estado.at("0xede3DF874379eF565881D67B1c1629297D0AfA14")
```

Registrar Universidad, Profesor y Alumno: 

```console
$ truffle(development)> i.registrarUniversidad(accounts[1], "UNIR", {from: accounts[0]})
$ truffle(development)> i.registrarProfesor(accounts[2], "Profesor", {from: accounts[0]})
$ truffle(development)> i.registrarAlumno(accounts[3], "Alumno", {from: accounts[0]})
```

### 3. Comprar ECTS por parte del alumno

Cualquier usuario puede comprobar weis necesarios para adquirir 10 créditos en una universidad: 

```console
$ truffle(development)> (await i.calcularCreditosToWeis(accounts[1],10)).toString()
```

El alumno compra en ECTSToken 10 cŕeditos (680000000000000000 weis) a la universidad

```console
$ truffle(development)> i.comprarTokens(accounts[1],10, {from:accounts[3], value:680000000000000000})
```

Verificar Balance en ECTSToken del alumno: 

```console
$ truffle(development)> (await ects.balanceOf(accounts[3])).toString()
```

Verificar Balance en ECTSToken de la universidad: 

```console
$ truffle(development)> (await ects.balanceOf(accounts[1])).toString()
```

Verificar Balance para la universidad en ECTSToken del alumno: 
```console
$ truffle(development)> (await ects.getTokenAlumnoPorUniversidad(accounts[3],accounts[1])).toString()
```

### 4. Matriculación en asignaturas

Crear nueva asignatura ERC721 en SC Estado
```console
$ truffle(development)> i.crearAsignatura("Calculo 1", "CAL1", 7, 0)
```

Obtener asignaturas getAsignaturas de SC Estado
```console
$ truffle(development)> i.getAsignaturas() 
[ '0x3C4f47E398622ecbE4A069389880033871f502c2' ]
```

Instanciar la asignatura con la que interactuaremos

```console
$ truffle(development)> let a = await AsignaturaToken.at("0x3C4f47E398622ecbE4A069389880033871f502c2")
```

Estado - Registrar universidad y profesor para una asignatura en AsignaturaToken

```console
$ truffle(development)> a.registrarUniversidadProfesor(accounts[1],accounts[2], {from:accounts[0]})
```

Alumno - Matricular en una asignatura por parte de un alumno en AsignaturaToken

```console
$ truffle(development)> a.matricular(accounts[1], '19-20', {from:accounts[3]})
```

Verificar que se ha registrado
```console
$ truffle(development)> a.ownerOf(1) y (await a.balanceOf(accounts[1])).toString()
```

Verificar Balance en ECTSToken del alumno: 

```console
$ truffle(development)> (await ects.balanceOf(accounts[3])).toString()
```

Verificar Balance en ECTSToken de la universidad: 

```console
$ truffle(development)> (await ects.balanceOf(accounts[1])).toString()
```

Verificar Balance para la universidad en ECTSToken del alumno: 
```
$ truffle(development)> (await ects.getTokenAlumnoPorUniversidad(accounts[3],accounts[1])).toString()
```

## Direcciones ganache-cli

* (0) 0x722dFbc5865d6C3aD046D1bFE4805937F8aA1765 (100 ETH)
* (1) 0xFCa64BCAb1392BCe57601e9793dBc7C5B19db454 (100 ETH)
* (2) 0xDFe5d7A53ff3bd7E46f39112CF70a6C7DCE1689c (100 ETH)
* (3) 0xBA13a98460Feb8226e0792d2ff6C37bAEf237783 (100 ETH)
* (4) 0x718a4Cc3711473157d776753196e8F4b7eA209ab (100 ETH)
* (5) 0x69664628e23721D00551f0fEf9f1d043A41eFB3B (100 ETH)
* (6) 0xfc4c1615907ce5764189Fc6C4Cc8eeC24d63B38f (100 ETH)
* (7) 0x98707A987d60fab7C2E7b49B06eb8AEEC181f86f (100 ETH)
* (8) 0x57DFceF625DF5b46ceDDa237C5A53da589e71B09 (100 ETH)
* (9) 0x53A29C2BbA64d4e43Daf6295367613132f05a0C4 (100 ETH)
