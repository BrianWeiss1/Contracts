// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";


// interface IUniswapV2Router02 {
//     function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
//     function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
//     function WETH() external pure returns (address);
// }

interface IAaveFlashLoan {
    function flashLoan(address receiver, address[] calldata assets, uint[] calldata amounts, uint[] calldata modes, address onBehalfOf, bytes calldata params, uint16 referralCode) external;
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract FlashLoanRecipient is IFlashLoanRecipient {
    IVault private constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function makeFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external {
        require(msg.sender == owner, "Only owner can call this function");
        vault.flashLoan(this, tokens, amounts, userData);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == address(vault));
    }
}



contract MEVBot {
    address public owner;
    address public uniswapRouter;
    address public aaveFlashLoan;
    address public token;
    uint public slippageTolerance;
    uint public profitMargin;
    bool public isRunning;
    address public targetAddress;

    constructor(address _uniswapRouter, address _aaveFlashLoan, address _token, uint _slippageTolerance, uint _profitMargin, address _targetAddress) {
        owner = msg.sender;
        uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        aaveFlashLoan = _aaveFlashLoan;
        token = _token;
        slippageTolerance = _slippageTolerance;
        profitMargin = _profitMargin;
        isRunning = false;
        targetAddress = _targetAddress;
    }
    
    function swapTokens(uint amountIn, uint amountOutMin, address[] calldata path) external {
        require(msg.sender == owner, "Only owner can call this function");
        IERC20(token).transferFrom(msg.sender, address(this), amountIn);
        uint[] memory amounts = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp + 1800);
        uint profit = amounts[path.length - 1] * profitMargin / 100;
        IERC20(token).transfer(owner, profit);
    }

    function flashLoan(uint amountIn, uint amountOut, address[] calldata path) external {
        require(msg.sender == owner, "Only owner can call this function");
        uint[] memory amounts = new uint;
        address[] memory assets = new address;
        uint[] memory modes = new uint;
        amounts[0] = amountIn;
        amounts[1] = amountOut;
        amounts[2] = 0;
        assets[0] = token;
        modes[0] = 0;
        bytes memory params = abi.encode(amountIn, amountOut, path, assets, modes);
        IVault(balancerVault).flashLoan(address(this), assets, amounts, modes, address(this), params);
    }

    function transferTokens(address recipient, uint amount) external {
        require(msg.sender == owner, "Only owner can call this function");
        IERC20(token).transfer(recipient, amount);
    }

    function calculateOptimalAmount(uint amountIn, uint amountOutMin, uint balanceIn, uint balanceOut) public view returns (uint) {
        uint amountOut = amountIn * balanceOut * (10000 - slippageTolerance) / (balanceIn * 10000);
        return amountOut > amountOutMin ? amountIn : 0;
    }

    function monitorMempool(address targetAddr) internal {
        require(msg.sender == owner, "Only owner can call this function");
        require(isRunning == true, "The bot is not running");

        bytes32 targetHash = keccak256(abi.encodePacked(targetAddr));
        uint targetBlock = block.number + 1;
        uint[] memory amounts = new uint[](3);
        amounts[0] = 0;
        amounts[1] = 0;
        amounts[2] = 0;
        address[] memory assets = new address[](1);
        assets[0] = token;
        uint[] memory modes = new uint[](1);
        modes[0] = 0;
        bytes memory params = abi.encode(targetHash, targetBlock, amounts, assets, modes);
        IAaveFlashLoan(aaveFlashLoan).flashLoan(address(this), assets, amounts, modes, address(this), params, 0);
    }

    function executeOperation(
        address[] calldata _assets,
        uint[] calldata /*premiums*/,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(initiator == address(this), "Only MEVBot can call this function");
        (bytes32 targetHash, uint targetBlock, uint[] memory amounts, uint[] memory modes) = abi.decode(params, (bytes32, uint, uint[], uint[]));

        require(block.number == targetBlock, "Target block has not been reached yet");

        bytes32[] memory pendingHashes = new bytes32; // Fix memory array initialization
        uint count = 0;
        for (uint i = 0; i < 256; i++) {
            bytes32 hash = blockhash(targetBlock - i);
            if (hash == targetHash) {
                break;
            }
            pendingHashes[count] = hash;
            count++;
        }

        for (uint i = 0; i < count; i++) {
            bytes32 hash = pendingHashes[i];
            uint nonce = 0;
            while (true) {
                bytes32 txHash = keccak256(abi.encodePacked(hash, nonce));
                if (block.timestamp >= block.timestamp + 1800) {
                    break;
                }
                if (tx.gasprice > tx.gasprice * 10) {
                    break;
                }
                if (tx.origin == owner) {
                    break;
                }
                if (txHash == targetHash) {
                    address[] memory path = new address; 
                    path[0] = token;
                    path[1] = IWETH(uniswapRouter.WETH()).WETH();

                    if (amounts[0] * IERC20(path[1]).balanceOf(address(this)) / IERC20(path[0]).balanceOf(address(this)) > amounts[1]) {
                        uint[] memory flashAmounts = new uint; 
                        flashAmounts[0] = amounts[0];
                        flashAmounts[1] = amounts[0] * IERC20(path[1]).balanceOf(address(this)) / IERC20(path[0]).balanceOf(address(this));
                        flashAmounts[2] = 0;

                        address[] memory flashAssets = new address; 
                        flashAssets[0] = token;

                        uint[] memory flashModes = new uint; 
                        flashModes[0] = 0;

                        bytes memory flashParams = abi.encode(amounts[0], amounts[1], path, flashAssets, flashModes);

                        IVault(balancerVault).flashLoan(address(this), flashAssets, flashAmounts, flashModes, address(this), flashParams);
                    }
                    break;
                }
                nonce++;
            }
        }
        return true;
    }

    function withdraw() external {
        require(msg.sender == owner, "Only owner can call this function");
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner, balance);
    }

    function start() external {
        require(msg.sender == owner, "Only owner can call this function");
        isRunning = true;
        monitorMempool(targetAddress);
    }
    function stop() external {
        isRunning = false;
    }
}
