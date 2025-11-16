// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ArcDEXPool {
    IERC20 public immutable TOKEN_0;
    IERC20 public immutable TOKEN_1;

    uint256 public reserve0; // Reserve for TOKEN_0
    uint256 public reserve1; // Reserve for TOKEN_1

    uint256 public constant FEE_NUMERATOR = 997;
    uint256 public constant FEE_DENOMINATOR = 1000;

    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1);
    event Swapped(address indexed swapper, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        require(token0 != address(0) && token0 != token1, "Invalid token addresses");

        TOKEN_0 = IERC20(token0);
        TOKEN_1 = IERC20(token1);
    }

    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = balance0;
        reserve1 = balance1;
    }

    /**
     * @notice Calculates the optimal liquidity amount for token B given an amount for token A.
     * @dev Used internally to calculate proportional deposits.
     */
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(reserveA > 0, "DEX: INSUFFICIENT_LIQUIDITY_BURNED"); // Should not happen in this context
        return (amountA * reserveB) / reserveA;
    }

    /**
     * @notice CRITICAL FIX: Robust addLiquidity function.
     * This function now accepts the two token addresses and the desired amounts,
     * handling sorting and ratio calculations internally.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) public returns (uint256 amount0, uint256 amount1) {
        // 1. Sort inputs to match the pool's internal TOKEN_0/TOKEN_1 order
        (uint256 amount0Desired, uint256 amount1Desired) =
            tokenA == address(TOKEN_0) ? (amountADesired, amountBDesired) : (amountBDesired, amountADesired);

        // 2. Calculate the actual amounts to add based on the current pool ratio
        if (reserve0 == 0 && reserve1 == 0) {
            // This is the first liquidity deposit, so we accept the desired amounts
            amount0 = amount0Desired;
            amount1 = amount1Desired;
        } else {
            // This is a subsequent deposit. We must maintain the ratio.
            // We calculate the optimal amount of B for the desired amount of A
            uint256 amount1Optimal = quote(amount0Desired, reserve0, reserve1);

            if (amount1Optimal <= amount1Desired) {
                // The user provided enough B (or more than enough).
                // A is the limiting factor.
                amount0 = amount0Desired;
                amount1 = amount1Optimal;
            } else {
                // The user did not provide enough B for the desired A.
                // B is the limiting factor. We calculate the optimal A for the desired B.
                uint256 amount0Optimal = quote(amount1Desired, reserve1, reserve0);
                // We must check this is not more than they wanted to provide
                require(amount0Optimal <= amount0Desired, "DEX: INSUFFICIENT_A_AMOUNT");
                amount0 = amount0Optimal;
                amount1 = amount1Desired;
            }
        }

        require(amount0 > 0 && amount1 > 0, "DEX: INSUFFICIENT_LIQUIDITY");

        // 3. Transfer the calculated amounts
        require(TOKEN_0.transferFrom(msg.sender, address(this), amount0), "Transfer 0 failed");
        require(TOKEN_1.transferFrom(msg.sender, address(this), amount1), "Transfer 1 failed");

        // 4. Update reserves
        _update(TOKEN_0.balanceOf(address(this)), TOKEN_1.balanceOf(address(this)));

        emit LiquidityAdded(msg.sender, amount0, amount1);
    }

    /// @notice Swaps tokenIn for tokenOut
    function swap(IERC20 tokenIn, uint256 amountIn) public {
        require(amountIn > 0, "Amount must be greater than zero");
        require(reserve0 > 0 && reserve1 > 0, "Pool reserves are zero");

        // Determine tokenOut and corresponding reserves
        IERC20 tokenOut;
        uint256 reserveIn;
        uint256 reserveOut;

        if (tokenIn == TOKEN_0) {
            tokenOut = TOKEN_1;
            reserveIn = reserve0;
            reserveOut = reserve1;
        } else if (tokenIn == TOKEN_1) {
            tokenOut = TOKEN_0;
            reserveIn = reserve1;
            reserveOut = reserve0;
        } else {
            revert("Invalid token");
        }

        // 1. Transfer tokenIn from the caller to the pool
        require(tokenIn.transferFrom(msg.sender, address(this), amountIn), "Transfer In failed");

        // 2. Calculate the output amount (Constant Product Formula with fee)
        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;
        uint256 numerator = reserveOut * amountInWithFee;
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        uint256 amountOut = numerator / denominator;

        require(amountOut > 0, "Insufficient output");

        // 4. Transfer the output token to the caller
        //    ***THIS MUST HAPPEN BEFORE UPDATING RESERVES***
        require(tokenOut.transfer(msg.sender, amountOut), "Transfer Out failed");

        // 3. (MOVED) Update reserves by reading balances (robust anti-reentrancy measure)
        //    Now that both transfers are complete, we can safely read balances.
        _update(TOKEN_0.balanceOf(address(this)), TOKEN_1.balanceOf(address(this)));

        emit Swapped(msg.sender, address(tokenIn), amountIn, address(tokenOut), amountOut);
    }
}