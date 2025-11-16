// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; // Updated pragma

import {Script} from "forge-std/Script.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ArcDEXPool} from "../src/ArcDEXPool.sol";
import {console} from "forge-std/console.sol";

contract InitLiquidityScript is Script {
    // 🛑 YOU MUST UPDATE THESE 3 ADDRESSES AFTER RE-DEPLOYING
    address constant DEX_POOL_ADDRESS = 0x106A4bfb4b7709bc809dC01C4972e7DeC91b0f80; // NEW Pool Address
    address constant MY_TOKEN_A_ADDRESS = 0xa654C7Ef6Ba495A77550D629f2b05bEF3e15c588; // NEW MYTA Address
    address constant MY_TOKEN_B_ADDRESS = 0xECE33627200cA2430058EFFe099112852C65A5D6; // NEW MYTB Address
    // ---------------------------------------------------------------------

    // 1000 tokens of each, assuming 18 decimals
    uint256 public constant INITIAL_LIQUIDITY_A = 1000 * 10**18;
    uint256 public constant INITIAL_LIQUIDITY_B = 1000 * 10**18;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        IERC20 myTokenA = IERC20(MY_TOKEN_A_ADDRESS);
        IERC20 myTokenB = IERC20(MY_TOKEN_B_ADDRESS);
        ArcDEXPool dexPool = ArcDEXPool(DEX_POOL_ADDRESS);

        console.log("Approving MyTokenA...");
        myTokenA.approve(address(dexPool), INITIAL_LIQUIDITY_A);
        console.log("Approving MyTokenB...");
        myTokenB.approve(address(dexPool), INITIAL_LIQUIDITY_B);

        // 2. Add Initial Liquidity
        // Call the new, robust addLiquidity function
        console.log("Adding liquidity (MYTA / MYTB)...");
        (uint256 amountA, uint256 amountB) = dexPool.addLiquidity(
            MY_TOKEN_A_ADDRESS,
            MY_TOKEN_B_ADDRESS,
            INITIAL_LIQUIDITY_A,
            INITIAL_LIQUIDITY_B
        );
        console.log("Liquidity added successfully!");
        console.log("Amount A added:", amountA);
        console.log("Amount B added:", amountB);

        vm.stopBroadcast();
    }
}