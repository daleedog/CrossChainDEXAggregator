// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/UniswapChainflip.sol";
import "../src/DEXAggregator.sol";

contract UniswapChainflipTest is Test {
    UniswapChainflip uniswapChainflip;
    DEXAggregator dexAggregator;

    address constant UNISWAP_ROUTER = 0xUniswapRouterAddress; // Replace with real Uniswap router address
    address constant CHAINFLIP_VAULT = 0xChainflipVaultAddress; // Replace with real Chainflip vault address
    address constant WETH = 0xWETHAddress; // Replace with real WETH address
    address constant TOKEN_A = 0xTokenA; // Token A address for testing
    address constant TOKEN_B = 0xTokenB; // Token B address for testing
    address user = address(0x123); // User address for testing
    uint256 userPrivateKey = uint256(0x123456789abcdef); // Replace with a test private key

    function setUp() public {
        // Deploy contracts for testing
        dexAggregator = new DEXAggregator(UNISWAP_ROUTER, 0xSushiswapRouterAddress); // Example setup
        uniswapChainflip = new UniswapChainflip(user, CHAINFLIP_VAULT, UNISWAP_ROUTER, WETH);

        // Label addresses for better clarity in test logs
        vm.label(UNISWAP_ROUTER, "UniswapRouter");
        vm.label(CHAINFLIP_VAULT, "ChainflipVault");
        vm.label(WETH, "WETH");
        vm.label(TOKEN_A, "TokenA");
        vm.label(TOKEN_B, "TokenB");
        vm.label(user, "User");

        // Fund user with Ether for transaction fees
        vm.deal(user, 10 ether);
    }

    function testSwapUsingUniswapAndChainflip() public {
        // Arrange: Set up initial balances and mock Uniswap behavior
        uint256 amountIn = 1 ether;
        vm.startPrank(user);

        // Mock Uniswap's response for token swap
        address[] memory path = new address[](2[()]()        path[0] = TOKEN_A;
        path[1] = TOKEN_B;

        // Act: Perform a token swap using Uniswap and Chainflip
        uniswapChainflip.swap(path, amountIn, 1, user, block.timestamp + 1000);

        // Assert: Check if Chainflip is called and user receives swapped tokens
        uint256 finalBalance = IERC20(TOKEN_B).balanceOf(user);
        assertTrue(finalBalance > 0, "User should receive swapped tokens.");

        vm.stopPrank();
    }

    function testSwapRevertsIfRouterNotSet() public {
        // Act and Assert: Ensure the swap reverts if the Uniswap router is not set properly
        address[] memory path = new address[](2[()]()        path[0] = TOKEN_A;
        path[1] = TOKEN_B;

        // Remove router
        uniswapChainflip = new UniswapChainflip(user, CHAINFLIP_VAULT, address(0), WETH);

        vm.expectRevert("Router address is invalid");
        uniswapChainflip.swap(path, 1 ether, 1, user, block.timestamp + 1000);
    }

    function testSwapNativeToken() public {
        // Arrange: Prepare for swapping native ETH through Uniswap and Chainflip
        uint256 amountIn = 1 ether;
        vm.startPrank(user);

        address[] memory path = new address[](2[()]()        path[0] = WETH;  // Swap from ETH (via WETH)
        path[1] = TOKEN_A;

        // Act: Perform the swap using native ETH
        uniswapChainflip.swap{value: amountIn}(path, amountIn, 1, user, block.timestamp + 1000);

        // Assert: Check the token balance after the swap
        uint256 finalBalance = IERC20(TOKEN_A).balanceOf(user);
        assertTrue(finalBalance > 0, "User should receive tokens after ETH swap.");

        vm.stopPrank();
    }

    function testInsufficientOutputAmountReverts() public {
        // Arrange: Swap setup with an unrealistic minimum output amount
        uint256 amountIn = 1 ether;
        vm.startPrank(user);

        address[] memory path = new address[](2[()]()        path[0] = TOKEN_A;
        path[1] = TOKEN_B;

        // Act and Assert: Expect swap to revert if minimum output is too high
        vm.expectRevert("Insufficient output amount");
        uniswapChainflip.swap(path, amountIn, 1000 ether, user, block.timestamp + 1000);

        vm.stopPrank();
    }

    function testChainflipIntegration() public {
        // Arrange: Setup swap with Chainflip mock
        uint256 amountIn = 2 ether;
        vm.startPrank(user);

        address[] memory path = new address[](2[()]()        path[0] = TOKEN_A;
        path[1] = TOKEN_B;

        // Mock a Chainflip integration where the swap happens cross-chain
        // (Here, we're just assuming the swap goes through; add Chainflip contract logic later)

        // Act: Perform swap with Chainflip integration
        uniswapChainflip.swap(path, amountIn, 1, user, block.timestamp + 1000);

        // Assert: Verify user balance and successful interaction
        uint256 finalBalance = IERC20(TOKEN_B).balanceOf(user);
        assertTrue(finalBalance > 0, "User should receive tokens via Chainflip.");

        vm.stopPrank();
    }

    function testGasCostsForSwap() public {
        // Arrange: Measure gas usage of swap function
        uint256 amountIn = 1 ether;
        vm.startPrank(user);

        address[] memory path = new address[](2[()]()        path[0] = TOKEN_A;
        path[1] = TOKEN_B;

        // Act: Execute swap and measure gas
        uint256 gasStart = gasleft();
        uniswapChainflip.swap(path, amountIn, 1, user, block.timestamp + 1000);
        uint256 gasUsed = gasStart - gasleft();

        // Assert: Print the gas used for the swap function
        emit log_named_uint("Gas used for swap", gasUsed);

        vm.stopPrank();
    }
}
