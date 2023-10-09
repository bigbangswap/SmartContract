// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.4;

import './interfaces/IERC20Metadata.sol';
import './libs/Address.sol';
import './libs/CfoTakeableV2.sol';
import './libs/ChainId.sol';

interface ISwapFactory {
    function getPair(address token0,address token1) external view returns(address);
}

interface IStakingPool{
    function exists(address account) external view returns(bool);
}

contract BBG is CfoTakeableV2, IERC20Metadata {

    using Address for address;

    string private constant _name = "BBG Token";
    string private constant _symbol = "BBG";
    uint256 private _totalSupply = 100_000_000 * 1e18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
    
    mapping(address => bool) public isOtherSwapPair;

    uint256 public constant RATE_PERCISION = 10000;
    uint256 public buyFeeRate = 400;
    uint256 public sellFeeRate = 400;
    address public feeTo;

    address public usdt;
    address public wbnb;
    address public pancakeSwapFactory;

    constructor( address _initHolder, address _feeAddress ){
        uint256 chainId = ChainId.get();
        if ( chainId == 56 ) {
            // mainnet
            usdt = address(0x55d398326f99059fF775485246999027B3197955);
            wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
            pancakeSwapFactory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
        } else if ( chainId == 97 ) {
            // testnet
            usdt = address(0x894040DCAb6F356B7e3FDC6914A8F765b95bbc6a);
            wbnb = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
            pancakeSwapFactory = address(0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc);
        }
        feeTo = address(_feeAddress);

        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(_name)), chainId, address(this)));

        address holder = _initHolder == address(0) ? msg.sender : _initHolder;
        _balances[holder] = _totalSupply;
        emit Transfer(address(0), holder, _totalSupply);
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool){
        require(block.timestamp <= deadline, "ERC20permit: expired");
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_name)),
                ChainId.get(),
                address(this)
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ERC20permit: invalid signature");
        require(signatory == owner, "ERC20permit: unauthorized");

        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _allowances[sender][_msgSender()] -= amount;

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        uint recipientAmount = amount;
        bool isBuy = isSwapPair(sender);
        bool isSell = isSwapPair(recipient);
        if(recipient != address(0) && (isBuy || isSell)){
            uint feeRate = isBuy ? buyFeeRate : sellFeeRate;
            uint feeAmount = amount * feeRate / RATE_PERCISION;
            recipientAmount -= feeAmount;
            _takeFee(sender, feeTo, feeAmount);
        }
        
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + recipientAmount;
        emit Transfer(sender, recipient, recipientAmount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _takeFee(address _from, address _to, uint _fee) internal {
        if(_fee > 0){
            _balances[_to] = _balances[_to] + _fee;
            emit Transfer(_from, _to, _fee);
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function isSwapPair(address pair) public view returns(bool){
        if(pair == address(0)){
            return false;
        }

        return ISwapFactory(pancakeSwapFactory).getPair(address(this), usdt) == pair 
            || ISwapFactory(pancakeSwapFactory).getPair(address(this), wbnb) == pair 
            || isOtherSwapPair[pair];
    }

    function burn(uint amount) external returns (uint256){
        if (_totalSupply - amount < 1000_000e18) {
            uint256 burned = _totalSupply - 1000_000e18;
            require(burned <= amount, "exceeds burn amount");
            _balances[msg.sender] -= burned;
            _totalSupply = 1000_000e18;
            emit Transfer(msg.sender, address(0), burned);
            return burned;
        } else {
            _balances[msg.sender] -= amount;
            _totalSupply -= amount;
            emit Transfer(msg.sender, address(0), amount);
            return amount;
        }
    }

    function addOtherSwapPair(address _swapPair) external onlyOwner {
        require(_swapPair != address(0),"_swapPair can not be address 0");
        isOtherSwapPair[_swapPair] = true;
    }

    function removeOtherSwapPair(address _swapPair) external onlyOwner {
        require(_swapPair != address(0),"_swapPair can not be address 0");
        isOtherSwapPair[_swapPair] = false;
    }

    function setBuyFeeRate(uint _rate) external onlyOwner {
        require(_rate <= RATE_PERCISION,"rate too large");
        buyFeeRate = _rate;
    }

    function setSellFeeRate(uint _rate) external onlyOwner {
        require(_rate <= RATE_PERCISION,"rate too large");
        sellFeeRate = _rate;
    }

    function setFeeTo(address _feeTo) external onlyOwner {
	require(_feeTo != address(0), "invalid address");
        feeTo = _feeTo;
    }

}
