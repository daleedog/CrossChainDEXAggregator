// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISwapRouter02} from "@uniswap-interfaces/ISwapRouter02.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IVault} from "@chainflip-interfaces/IVault.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract UniswapChainflip is Ownable {
    ISwapRouter02 swapRouter;
    IVault cfVault;
    using SafeCast for uint256;
    IWETH wETH;

    event UniswapCCM(
        uint32 srcChain,
        bytes srcAddress,
        address token,
        uint256 amount
    );


    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event UniswapErrorFundsReturned(address indexed token, address indexed receiver, uint256 amount);

    constructor(
        address owner,
        address _cfVault,
        address _swapRouter02,
        address _wETH
    ) Ownable(owner) {
        cfVault = IVault(_cfVault);
        swapRouter = ISwapRouter02(_swapRouter02);
        wETH= IWETH(_wETH);
    }

    event BytesDebug(bytes);

    receive() external payable {}

    function setRouter(address _router) external onlyOwner {
        swapRouter = ISwapRouter02(_router);
    }

    function getRouter() external view returns (address) {
        return address(swapRouter);
    }
    function cfReceive(
        uint32 srcChain,
        bytes calldata srcAddress,
        bytes calldata message,
        address token,
        uint256 amount
    ) external payable returns (uint256 amountOut) {
        require(msg.sender == address(cfVault), "only router");
        (bytes memory callData, address sender) = abi.decode(
            message,
            (bytes, address)
        );
        if (msg.value > 0) {
            wETH.deposit{value:msg.value}();
            wETH.approve(address(swapRouter), msg.value);
            (bool _success, ) = address(swapRouter).call(callData);
            if (!_success) {
                wETH.withdraw(msg.value);
                payable(sender).transfer(msg.value);
                emit UniswapErrorFundsReturned(ETH_ADDRESS, sender, msg.value);
            }
        } else {
            IERC20(token).approve(address(swapRouter), amount);
            (bool _success, ) = address(swapRouter).call(callData);
            if (!_success) {
                IERC20(token).transfer(sender, amount);
                emit UniswapErrorFundsReturned(token, sender, amount);
            }
        }

        emit UniswapCCM(srcChain, srcAddress, token, amount);
    }

    function _isNotZero(address token) internal pure returns (bool) {
        require(token != address(0), "token is zero");
    }
}
