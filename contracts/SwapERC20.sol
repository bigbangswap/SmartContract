
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import './interfaces/ISwapERC20.sol';
import './libs/SafeMath.sol';
import './libs/ChainId.sol';
import "./libs/Counters.sol";

contract SwapERC20 is ISwapERC20 {
    using SafeMath for uint;
    using Counters for Counters.Counter;

    Counters.Counter private _nonces;
    string public constant override name = 'BigBangSwap LP Token';
    string public constant override symbol = 'BigBangSwap LP Token';
    uint8 public constant override decimals = 18;
    uint public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public immutable override DOMAIN_SEPARATOR;
    // PERMIT_TYPEHASH = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                ChainId.get(),
                address(this)
            )
        );
    }

    // LP token can be sent to address(0), for the minimal initial lp
    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        require(spender != address(0), "invalid spender address");
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
	require(to != address(0), "invalid to");
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
	require(from != address(0), "invalid to");
	require(to != address(0), "invalid to");
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces.current(), deadline));
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(structHash);
        address signer = ECDSA.recover(digest, v, r, s);
        require(signer == owner && signer != address(0), "Swap: Invalid signature");
        require(block.timestamp <= deadline, "Swap: Signature expired");

        _nonces.increment();
        _approve(owner, spender, amount);
    }

}
