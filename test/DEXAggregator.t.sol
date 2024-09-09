// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/DEXAggregator.sol";
import "forge-std/console.sol"; // for logging

contract DEXAggregatorTest is Test {
    DEXAggregator dexAggregator;

    address constant UNISWAP_ROUTER = 0xUniswapRouterAddress; // Replace with Uniswap router
    address constant SUSHISWAP_ROUTER = 0xSushiswapRouterAddress; // Replace with Sushiswap router
    address constant TOKEN_A = 0xTokenA; // Token A address for testing
    address constant TOKEN_B = 0xTokenB; // Token B address for testing
    address user = address(0x123); // User address for testing
    uint256 userPrivateKey = uint256(0x123456789abcdef); // Replace with a test private key

    function setUp() public {
        // Deploy the DEXAggregator with Uniswap and Sushiswap routers
        dexAggregator = new DEXAggregator(UNISWAP_ROUTER, SUSHISWAP_ROUTER);

        // Label addresses for clarity in test logs
        vm.label(UNISWAP_ROUTER, "UniswapRouter");
        vm.label(SUSHISWAP_ROUTER, "SushiswapRouter");
        vm.label(TOKEN_A, "TokenA");
        vm.label(TOKEN_B, "TokenB");
        vm.label(user, "User");

        // Fund user with Ether for transaction fees
        vm.deal(user, 10 ether);
    }

    function testGetBestSwap_UniswapHasBetterRate() public {
        // Arrange: Set up mock swap results for both Uniswap and Sushiswap
        uint256 amountIn = 1 ether;
        uint256 uniswapAmountOut = 200 ether;
        uint256 sushiswapAmountOut = 190 ether;

        // Mock Uniswap swap return value
        vm.mockCall(
            UNISWAP_ROUTER,
            abi.encodeWithSignature("getAmountsOut(uint256,address[])", amountIn, createPath(TOKEN_A, TOKEN_B)),
            abi.encode(uniswapAmountOut)
        );

        // Mock Sushiswap swap return value
        vm.mockCall(
            SUSHISWAP_ROUTER,
            abi.encodeWithSignature("getAmountsOut(uint256,address[])", amountIn, createPath(TOKEN_A, TOKEN_B)),
            abi.encode(sushiswapAmountOut)
        );

        // Act: Get the best swap path
        (uint256 bestAmountOut, address bestRouter) = dexAggregator.getBestSwap(createPath(TOKEN_A, TOKEN_B), amountIn);

        // Assert: Ensure Uniswap gives the best price
        assertEq(bestAmountOut, uniswapAmountOut, "Uniswap should offer the best amount out.");
        assertEq(bestRouter, UNISWAP_ROUTER, "Best router should be Uniswap.");
    }

    function testGetBestSwap_SushiswapHasBetterRate() public {
        // Arrange: Set up mock swap results where Sushiswap gives a better rate
        uint256 amountIn = 1 ether;
        uint256 uniswapAmountOut = 180 ether;
        uint256 sushiswapAmountOut = 200 ether;

        // Mock Uniswap swap return value
        vm.mockCall(
            UNISWAP_ROUTER,
            abi.encodeWithSignature("getAmountsOut(uint256,address[])", amountIn, createPath(TOKEN_A, TOKEN_B)),
            abi.encode(uniswapAmountOut)
        );

        // Mock Sushiswap swap return value
        vm.mockCall(
            SUSHISWAP_ROUTER,
            abi.encodeWithSignature("getAmountsOut(uint256,address[])", amountIn, createPath(TOKEN_A, TOKEN_B)),
            abi.encode(sushiswapAmountOut)
        );

        // Act: Get the best swap path
        (uint256 bestAmountOut, address bestRouter) = dexAggregator.getBestSwap(createPath(TOKEN_A, TOKEN_B), amountIn);

        // Assert: Ensure Sushiswap gives the best price
        assertEq(bestAmountOut, sushiswapAmountOut, "Sushiswap should offer the best amount out.");
        assertEq(bestRouter, SUSHISWAP_ROUTER, "Best router should be Sushiswap.");
    }

    function testGetBestSwap_RevertsIfNoPathExists() public {
        // Arrange: Set up input values without a valid path
        uint256 amountIn = 1 ether;

        // Act and Assert: Expect the function to revert
        vm.expectRevert("DEXAggregator: No path available");
        dexAggregator.getBestSwap(new address[](0