// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; // Updated pragma

import {Script} from "forge-std/Script.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ArcDEXPool} from "../src/ArcDEXPool.sol";
import {console} from "forge-std/console.sol";

contract PerformSwapScript is Script {
    // 🛑 IMPORTANT: PASTE THE 3 ADDRESSES FROM YOUR DEPLOYMENT/INIT SCRIPTS HERE
    address constant DEX_POOL_ADDRESS = 0x175d2B9b3481A44C30baBA9ABeed9B9e2A9954b6; // Your deployed DEX Pool
    address constant MY_TOKEN_A_ADDRESS = 0x32268eA834d5e7afAc9e1492fdAA77b99C6DDe67; // Your MYTA Token
    address constant MY_TOKEN_B_ADDRESS = 0x7B3F6713f752f48F37076081432810E0f1C89268; // Your MYTB Token
    // ---------------------------------------------------------------------

    // Amount to swap (10 tokens for the first swap)
    uint256 public constant SWAP_AMOUNT_A = 10 * 10**18;
    
    // FIX: Changed public to external for modern Solc compatibility with Forge scripts
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address swapper = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Define contracts
        IERC20 myTokenA = IERC20(MY_TOKEN_A_ADDRESS);
        IERC20 myTokenB = IERC20(MY_TOKEN_B_ADDRESS);
        ArcDEXPool dexPool = ArcDEXPool(DEX_POOL_ADDRESS);
        
        // --- CAPTURE INITIAL BALANCE SAFELY ---
        uint256 initialBalanceMYTA = myTokenA.balanceOf(swapper);

        uint256 balanceMYTB_before;
        uint256 balanceMYTB_after_swap1;
        uint256 amountReceived;
        
        console.log("--- Swapper: ", swapper);
        console.log("--- Initial MYTA Balance: %s", initialBalanceMYTA); 
        
        // --- SWAP 1: MYTA for MYTB ---
        
        console.log("\n*** SWAP 1: MYTA -> MYTB ***");
        balanceMYTB_before = myTokenB.balanceOf(swapper);
        
        // 1. Approve MYTA
        console.log("Approving MYTA...");
        myTokenA.approve(address(dexPool), SWAP_AMOUNT_A);

        // 2. Perform the Swap (MYTA to MYTB)
        dexPool.swap(myTokenA, SWAP_AMOUNT_A);
        
        balanceMYTB_after_swap1 = myTokenB.balanceOf(swapper);
        amountReceived = balanceMYTB_after_swap1 - balanceMYTB_before;

        console.log("MYTA In:", SWAP_AMOUNT_A);
        console.log("MYTB Out:", amountReceived);
        // FIX: Use reserve0() and reserve1() for logging, as pool uses sorted tokens
        console.log("Reserves After Swap 1: 0: %s, 1: %s", dexPool.reserve0(), dexPool.reserve1());


        // --- SWAP 2: MYTB for MYTA (The Reverse Swap) ---
        
        console.log("\n*** SWAP 2: MYTB -> MYTA (REVERSE) ***");
        
        // 1. Approve the amount received in the first swap (MYTB)
        console.log("Approving MYTB (received amount) for reverse swap...");
        myTokenB.approve(address(dexPool), amountReceived);

        // 2. Perform the Reverse Swap (MYTB to MYTA)
        dexPool.swap(myTokenB, amountReceived);
        
        console.log("MYTB In:", amountReceived);
        // FIX: Use reserve0() and reserve1() for logging
        console.log("Reserves After Swap 2: 0: %s, 1: %s", dexPool.reserve0(), dexPool.reserve1());

        // 3. Final sanity check and logging
        uint256 finalBalanceMYTA = myTokenA.balanceOf(swapper);

        console.log("\n--- Final State ---");
        console.log("Final MYTA Balance:", finalBalanceMYTA);
        console.log("Final MYTB Balance:", myTokenB.balanceOf(swapper));
        
        console.log("Total MYTA lost due to fees/impact: %s", initialBalanceMYTA - finalBalanceMYTA); 

        vm.stopBroadcast();
    }
}