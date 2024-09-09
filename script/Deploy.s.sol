// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {DEXAggregator} from "../src/DEXAggregator.sol";
import {UniswapChainflip} from "../src/UniswapChainflip.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy DEXAggregator
        DEXAggregator dexAggregator = new DEXAggregator(
            0xUniswapRouterAddress,
            0xSushiswapRouterAddress
        );
        console.log("DEXAggregator deployed at:", address(dexAggregator));

        // Deploy UniswapChainflip
        UniswapChainflip uniswapChainflip = new UniswapChainflip(
            msg.sender,
            0xChainflipVaultAddress,
            0xUniswapRouterAddress,
            0xWETHAddress
        );
        console.log("UniswapChainflip deployed at:", address(uniswapChainflip));

        vm.stopBroadcast();
    }
}
