// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FlashLoanRecipient is IFlashLoanRecipient {
    IVault private constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IUniswapV2Router02 private constant uniswapRouter = IUniswapV2Router02(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD);
    
    function makeFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external {
        vault.flashLoan(this, tokens, amounts, userData);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == address(vault), "Sender must be vault");

        // Swap the flash loaned tokens for another token on Uniswap
        address tokenToSwap = address(tokens[0]);
        address tokenToReceive = address(0xTokenToReceiveAddress);
        uint256 amountToSwap = amounts[0];
        uint256 amountOutMin = 0; // Minimum amount of tokens to receive, set this based on your slippage tolerance

        // Approve Uniswap to spend the flash loaned tokens
        IERC20(tokenToSwap).approve(address(uniswapRouter), amountToSwap);

        // Perform the swap on Uniswap
        address[] memory path = new address;
        path[0] = tokenToSwap;
        path[1] = tokenToReceive;
        uniswapRouter.swapExactTokensForTokens(
            amountToSwap,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );

        // Additional operations with the swapped tokens can be added here

        // Repay the flash loan
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 repaymentAmount = amounts[i] + feeAmounts[i];
            tokens[i].transfer(address(vault), repaymentAmount);
        }
    }
}