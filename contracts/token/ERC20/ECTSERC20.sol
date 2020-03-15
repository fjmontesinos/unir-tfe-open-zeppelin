pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../Estado.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    address private _owner;
    address private _estadoAddress;
    Estado private _estadoSC;

    // permitirá almacenar los tokens adquiridos por cada alumno en cada una de las universidades
    mapping (address => mapping (address => uint256)) private _tokensUsuarioPorUniversidad;

    function setEstado(address estadoAddress) public onlyEstado {
        _estadoAddress = estadoAddress;
        _estadoSC = Estado(estadoAddress);
    }

    constructor() public {
        _owner = msg.sender;
    }

    function getEstado() public view returns (address) {
        return _estadoAddress;
    }

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public notIsAlumno returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view notIsAlumno returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public notIsAlumno returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public notIsAlumno returns (bool) {
        _transfer(sender, recipient, amount);

        // fj2m 20200301
        // si el operador de administración es cero i.e. no se ha definido o el
        // usuario que llama a la función no es el operador de administación del estado se verifica la aprobación
        // de la trasnferencia de tokens
        if(_estadoAddress == address(0) || msg.sender != _estadoAddress) {
            _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        }
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public notIsAlumno returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public notIsAlumno returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        // fj2m - 20200301
        // cambiar los balances de tokens de alumnos por _tokensUsuarioPorUniversidad
        if(_estadoSC.isAlumno(recipient)) {
            // el alumno recibe tokens de la universidad
            if(_tokensUsuarioPorUniversidad[recipient][sender] > 0) {
                // si ya tenía tokens se añaden
                // todo analizar por que el método SafeMath.add no funciona aquí
                uint256 valorActual = _tokensUsuarioPorUniversidad[recipient][sender];
                uint256 valorNuevo = valorActual + amount;
                require(valorNuevo >= valorActual, "ECTSERC20: addition overflow");
                _tokensUsuarioPorUniversidad[recipient][sender] = valorNuevo;

            } else {
                // si no tenía todavía tokens se inicializa
                _tokensUsuarioPorUniversidad[recipient][sender] = amount;
            }

        } else if (_estadoSC.isAlumno(sender)) {
            // el alumno entrega tokens a la universidad por matrícula -> se restan del balance de este respecto a la universidad
            // previamente se verifica que el alumno dispone de tokens para la universidad.
            require(_tokensUsuarioPorUniversidad[sender][recipient] >= amount, "ERC20: transfer amount exceeds balance (Alumno)");

            // todo verificar que el sub si funciona correctamente
            uint256 valorActual = _tokensUsuarioPorUniversidad[sender][recipient];
            _tokensUsuarioPorUniversidad[sender][recipient] = valorActual - amount;
        }

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }

    /**
     * @dev Throws si se llama por una cuenta registrada como alumno.
     * fj2m 20200301
     */
    modifier notIsAlumno() {
        require(! _estadoSC.isAlumno(msg.sender), "Alumno: llamada realizada por un alumno");
        _;
    }

    /**
     * @dev Throws si se llama por una cuenta que no sea el operador de administración o el owner del token.
     * fj2m 20200301
     */
    modifier onlyEstado(){
        require(msg.sender == _estadoAddress || msg.sender == _owner, 'Estado: llamada no realizada por owner ni estado');
        _;
    }

    /**
     * @dev Obtiene los tokens de un alumno para una universidad concreta
     *
     * Valiaciones:
     *
     * Se verifica que el msg.sender sea o bien el operador de administración o el owner del token
     *
     * fj2m 20200301
     */
    function getTokenAlumnoPorUniversidad(address _alumno, address _universidad) public view onlyEstado returns (uint256) {
        return _tokensUsuarioPorUniversidad[_alumno][_universidad];

    }

    /**
     * @dev Obtiene los tokens de un alumno para una universidad concreta llamada realizada por el proipo alumno
     *
     * Valiaciones:
     *
     * Se verifica que el msg.sender sea un alumno
     *
     * fj2m 20200301
     */
    function getTokensPorUniversidad(address _universidad) public view  returns (uint256) {
        require(_estadoSC.isAlumno(msg.sender), "Alumno: llamada NO realizada por un alumno");
        return _tokensUsuarioPorUniversidad[msg.sender][_universidad];

    }
}
