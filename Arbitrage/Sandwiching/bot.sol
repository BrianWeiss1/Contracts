// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "https://github.com/flashbots/pm/blob/main/sol/contracts/FlashLoanReceiverBase.sol";
import "https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol";
import "https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";

contract SandwichBot is FlashLoanReceiverBase {
    address public constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant SUSHISWAP_FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address public constant WETH_ADDRESS = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint256 public constant AMOUNT_IN = 1000 ether;
    uint256 public constant AMOUNT_OUT = 1000 ether;
    uint256 public constant DEADLINE = 10 minutes;

    constructor(address _flashLoanReceiver) FlashLoanReceiverBase(_flashLoanReceiver) {}

    function sandwich() external {
        address[] memory path = new address;
        path[0] = WETH_ADDRESS;
        path[1] = DAI_ADDRESS;

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(IUniswapV2Factory(UNISWAP_FACTORY).getRouter(WETH_ADDRESS));
        IUniswapV2Router02 sushiswapRouter = IUniswapV2Router02(IUniswapV2Factory(SUSHISWAP_FACTORY).getRouter(WETH_ADDRESS));

        uint256[] memory amounts = uniswapRouter.getAmountsOut(AMOUNT_IN, path);
        uint256 amountOutUniswap = amounts[1];

        amounts = sushiswapRouter.getAmountsOut(AMOUNT_IN, path);
        uint256 amountOutSushiswap = amounts[1];

        if (amountOutUniswap > amountOutSushiswap) {
            // Buy from Sushiswap, sell on Uniswap
            IUniswapV2Pair sushiswapPair = IUniswapV2Pair(IUniswapV2Factory(SUSHISWAP_FACTORY).getPair(DAI_ADDRESS, WETH_ADDRESS));
            sushiswapPair.swap(0, amountOutSushiswap, address(this), bytes(""));

            IERC20 dai = IERC20(DAI_ADDRESS);
            dai.approve(address(uniswapRouter), amountOutSushiswap);

            uniswapRouter.swapExactTokensForTokens(amountOutSushiswap, AMOUNT_OUT, path, address(this), DEADLINE);
        } else {
            // Buy from Uniswap, sell on Sushiswap
            IUniswapV2Pair uniswapPair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).getPair(DAI_ADDRESS, WETH_ADDRESS));
            uniswapPair.swap(0, amountOutUniswap, address(this), bytes(""));

            IERC20 dai = IERC20(DAI_ADDRESS);
            dai.approve(address(sushiswapRouter), amountOutUniswap);

            sushiswapRouter.swapExactTokensForTokens(amountOutUniswap, AMOUNT_OUT, path, address(this), DEADLINE);
        }
    }
}
