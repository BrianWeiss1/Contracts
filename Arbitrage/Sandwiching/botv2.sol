pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@aave/protocol-v2/contracts/interfaces/IFlashLoanReceiver.sol";
import "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";

contract SandwichBot is IFlashLoanReceiver {
    ILendingPoolAddressesProvider private _addressesProvider;
    IERC20 private _token;

    constructor(address addressesProvider, address token) {
        _addressesProvider = ILendingPoolAddressesProvider(addressesProvider);
        _token = IERC20(token);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // This is where you'd implement your sandwich attack strategy.
        // Be aware that this could be considered as frontrunning and might be illegal/unethical.

        // Repay the flashloan
        for (uint i = 0; i < assets.length; i++) {
            _token.approve(address(_addressesProvider.getLendingPool()), amounts[i] + premiums[i]);
        }

        return true;
    }

    function sandwichAttack(uint amount) external {
        ILendingPool lendingPool = ILendingPool(_addressesProvider.getLendingPool());
        address receiverAddress = address(this);

        address[] memory assets = new address;
        assets[0] = address(_token);

        uint256[] memory amounts = new uint256;
        amounts[0] = amount;

        uint256[] memory modes = new uint256;
        modes[0] = 0;

        lendingPool.flashLoan(receiverAddress, assets, amounts, modes, address(this), "", 0);
    }
}
