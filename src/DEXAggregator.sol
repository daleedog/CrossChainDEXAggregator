// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEXAggregator {
    address public owner;
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Router02 public sushiswapRouter;

    constructor(address _uniswapRouter, address _sushiswapRouter) {
        owner = msg.sender;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        sushiswapRouter = IUniswapV2Router02(_sushiswapRouter);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // Get the output amount of the best swap path
    function getBestSwap(
        address[] memory path,  // path includes both input and output tokens
        uint256 _amountIn
    ) public view returns (uint256, address) {
        uint256 uniswapOut = getAmountOut(uniswapRouter, path, _amountIn);
        uint256 sushiswapOut = getAmountOut(sushiswapRouter, path, _amountIn);

        if (uniswapOut >= sushiswapOut) {
            return (uniswapOut, address(uniswapRouter));
        } else {
            return (sushiswapOut, address(sushiswapRouter));
        }
    }

    // Get the output amount from a specific router
    function getAmountOut(
        IUniswapV2Router02 _router,
        address[] memory path,
        uint256 _amountIn
    ) internal view returns (uint256) {
        uint256[] memory amounts = _router.getAmountsOut(_amountIn, path);
        return amounts[amounts.length - 1]; // Output is the last element in the amounts array
    }

    // Execute the swap using arbitrary tokens, with a user-defined path (swapExactTokensForTokens)
    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address[] calldata path,  // User-defined path (input token to output token)
        address to,               // Address to send the output tokens to
        uint deadline             // Transaction deadline
    ) external {
        require(_amountIn > 0, "Must send tokens to swap");
        require(path.length >= 2, "Invalid path");

        // Get the best swap route and expected output
        (uint256 bestAmountOut, address bestRouter) = getBestSwap(path, _amountIn);

        require(bestAmountOut >= _minAmountOut, "Insufficient output amount");

        // Approve the router to spend the input tokens
        IERC20(path[0]).transferFrom(msg.sender, address(this), _amountIn); // Transfer input tokens to this contract
        IERC20(path[0]).approve(bestRouter, _amountIn);  // Approve the router to spend tokens

        // Perform the swap on the best router
        IUniswapV2Router02(bestRouter).swapExactTokensForTokens(
            _amountIn,
            _minAmountOut,
            path,
            to,             // Tokens are sent to the provided address
            deadline        // Transaction must be confirmed before this deadline
        );
    }

    // Withdraw function to allow the contract owner to withdraw remaining funds from the contract
    function withdraw(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, balance);
    }
}
