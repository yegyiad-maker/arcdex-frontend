// script/DeployAllPools.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; 

import {Script} from "forge-std/Script.sol";
import {ArcDEXPool} from "../src/ArcDEXPool.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract DeployAllPoolsScript is Script {
    
    // --- 🛑 YOU MUST UPDATE THESE ADDRESSES AFTER RUNNING YOUR TOKEN DEPLOYMENT SCRIPT ---
    // The addresses from your trace logs:
    address constant MYTA_ADDRESS = 0xa654C7Ef6Ba495A77550D629f2b05bEF3e15c588; 
    address constant MYTB_ADDRESS = 0xECE33627200cA2430058EFFe099112852C65A5D6;
    // -----------------------------------------------------------------------------------
    
    // Arc Testnet Native USDC address
    address constant ARC_USDC_ADDRESS = 0x3600000000000000000000000000000000000000;

    // Liquidity amounts (5000 tokens of each, assuming 18 decimals)
    uint256 public constant INITIAL_LIQUIDITY = 5000 * 10**18;
    
    // Outputs to easily copy to the frontend
    address public usdcMytaPoolAddress;
    address public usdcMytbPoolAddress;
    address public mytaMytbPoolAddress;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        
        // --- 1. DEPLOY THE THREE POOLS ---

        // MYTA / USDC Pool 
        ArcDEXPool usdcMytaPool = new ArcDEXPool(MYTA_ADDRESS, ARC_USDC_ADDRESS);
        usdcMytaPoolAddress = address(usdcMytaPool);

        // MYTB / USDC Pool 
        ArcDEXPool usdcMytbPool = new ArcDEXPool(MYTB_ADDRESS, ARC_USDC_ADDRESS);
        usdcMytbPoolAddress = address(usdcMytbPool);

        // MYTA / MYTB Pool 
        ArcDEXPool mytaMytbPool = new ArcDEXPool(MYTA_ADDRESS, MYTB_ADDRESS);
        mytaMytbPoolAddress = address(mytaMytbPool);

        console.log("--- Deployment Complete ---");
        console.log("MYTA/USDC Pool Address:", usdcMytaPoolAddress);
        console.log("MYTB/USDC Pool Address:", usdcMytbPoolAddress);
        console.log("MYTA/MYTB Pool Address:", mytaMytbPoolAddress);

        // --- 2. APPROVE LIQUIDITY FOR ALL POOLS ---
        
        // Setup interfaces
        IERC20 myta = IERC20(MYTA_ADDRESS);
        IERC20 mytb = IERC20(MYTB_ADDRESS);
        IERC20 arcUsdc = IERC20(ARC_USDC_ADDRESS); // We still approve, but skip liquidity 

        // Approve MYTA (used in 2 pools)
        myta.approve(usdcMytaPoolAddress, INITIAL_LIQUIDITY);
        myta.approve(mytaMytbPoolAddress, INITIAL_LIQUIDITY);

        // Approve MYTB (used in 2 pools)
        mytb.approve(usdcMytbPoolAddress, INITIAL_LIQUIDITY);
        mytb.approve(mytaMytbPoolAddress, INITIAL_LIQUIDITY);

        // Approve USDC (used in 2 pools)
        arcUsdc.approve(usdcMytaPoolAddress, INITIAL_LIQUIDITY);
        arcUsdc.approve(usdcMytbPoolAddress, INITIAL_LIQUIDITY);

        // --- 3. ADD INITIAL LIQUIDITY (ONLY FOR THE WORKING MYTA/MYTB POOL) ---

        // USDC POOLS ARE SKIPPED DUE TO THE TOKEN TRANSFER ERROR.
        
        // Pool 3: MYTA / MYTB (This one should succeed)
        console.log("Adding liquidity to MYTA/MYTB...");
        mytaMytbPool.addLiquidity(MYTA_ADDRESS, MYTB_ADDRESS, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);

        console.log("Deployment and MYTA/MYTB Pool Initialization Complete!");
        console.log("NOTE: USDC pool liquidity must be added manually due to token transfer error.");

        vm.stopBroadcast();
    }
}