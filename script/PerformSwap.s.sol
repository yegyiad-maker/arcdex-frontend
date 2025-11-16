// script/PerformSwap.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; 

import {Script} from "forge-std/Script.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ArcDEXPool} from "../src/ArcDEXPool.sol";
import {console} from "forge-std/console.sol";

contract PerformSwapScript is Script {
    
    // --- 🛑 UPDATE ALL ADDRESSES FROM DeployAllPools.s.sol ---
    address constant MYTA_ADDRESS = 0xa654C7Ef6Ba495A77550D629f2b05bEF3e15c588; 
    address constant ARC_USDC_ADDRESS = 0x3600000000000000000000000000000000000000;
    address constant USDC_MYTA_POOL_ADDRESS = 0xECE33627200cA2430058EFFe099112852C65A5D6; // PASTE ADDRESS
    // ---------------------------------------------------------------------

    uint256 public constant SWAP_AMOUNT = 10 * 10**18;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address swapper = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Define contracts
        IERC20 myta = IERC20(MYTA_ADDRESS);
        IERC20 usdc = IERC20(ARC_USDC_ADDRESS);
        ArcDEXPool usdcMytaPool = ArcDEXPool(USDC_MYTA_POOL_ADDRESS);
        
        console.log("--- Swapper: ", swapper);

        // --- SWAP 1: MYTA for USDC ---
        
        uint256 initialUSDCBalance = usdc.balanceOf(swapper);
        
        console.log("\n*** SWAP 1: MYTA -> USDC ***");
        
        // 1. Approve MYTA
        myta.approve(USDC_MYTA_POOL_ADDRESS, SWAP_AMOUNT);

        // 2. Perform the Swap (MYTA to USDC)
        usdcMytaPool.swap(myta, SWAP_AMOUNT);
        
        uint256 finalUSDCBalance = usdc.balanceOf(swapper);
        uint256 amountReceived = finalUSDCBalance - initialUSDCBalance;

        console.log("MYTA In:", SWAP_AMOUNT);
        console.log("USDC Out:", amountReceived);
        console.log("Reserves After Swap 1: 0: %s, 1: %s", usdcMytaPool.reserve0(), usdcMytaPool.reserve1());

        vm.stopBroadcast();
    }
}