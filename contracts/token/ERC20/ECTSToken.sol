pragma solidity ^0.5.0;

// import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "./ECTSERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract ECTSToken is ERC20, ERC20Detailed {
    using SafeMath for uint256;

    uint256 _maxCreditosCurso = 240;
    uint256 _maxAlumnos = 5000;
    uint256 _maxGrados = 500;
    uint256 _maxUniversidades = 200;
    
    // precio base en weis de la mínima parte de un crédito ETCS 
    // tendremos 10000 ECTSToken representan 1 Token completo
    // se inicializa en 14 euros el ECTSToken i.e. los 10000
    // que son 0,068 ethers -> un ECTSToken son 68000000000000000
    // así pues la mínima parte de un ECTSToken son 6800000000000
    uint256 _precioBaseECTSToken = uint256(6800000000000);

    constructor () ERC20Detailed("Créditos Universitarios Token", "ECTS", 4) public {
        _mint(msg.sender, _maxCreditosCurso.mul(_maxAlumnos).mul(_maxGrados).mul(_maxUniversidades).mul(10 ** uint256(decimals())));
    }
    
    /**
     * @dev Obtiene los créditos iniciales para asignar a una maxUniversidades
     * 
     **/
    function getCreditosInicialesUniversidad() public view onlyEstado returns (uint256) {
        return _maxCreditosCurso.mul(_maxAlumnos).mul(_maxGrados).mul(10 ** uint256(decimals()));
    }
    
    /**
     * @dev Obtiene el precio Base para los ECTSToken
     **/
    function getPrecioBaseECTSToken () public view returns (uint256) {
        return _precioBaseECTSToken;
    }

}