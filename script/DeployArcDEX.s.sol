// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; // Updated pragma

import {Script} from "forge-std/Script.sol";
import {ArcDEXPool} from "../src/ArcDEXPool.sol";
import {MyTokenA} from "../src/MyTokenA.sol";
import {MyTokenB} from "../src/MyTokenB.sol";
import {console} from "forge-std/console.sol";

contract DeployArcDEXScript is Script {
    
    // We will mint 1 million tokens for each mock token
    uint256 public constant INITIAL_SUPPLY = 1_000_000;

    // FIX: Changed public to external for modern Solc compatibility with Forge scripts
    function run() external returns (address arcDexPoolAddress, address myTokenAAddress, address myTokenBAddress) { 
        // 1. Get the private key for broadcasting
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // 2. DEPLOY MyToken A (MYTA)
        console.log("Deploying MyToken A (MYTA)...");
        MyTokenA myTokenA = new MyTokenA(INITIAL_SUPPLY);
        myTokenAAddress = address(myTokenA);
        
        // 3. DEPLOY MyTokenB (MYTB)
        console.log("Deploying MyToken B (MYTB)...");
        MyTokenB myTokenB = new MyTokenB(INITIAL_SUPPLY);
        myTokenBAddress = address(myTokenB);

        // 4. DEPLOY THE DEX POOL (using MYTA and MYTB)
        console.log("Deploying ArcDEXPool for MYTA / MYTB...");
        // The constructor sorts the tokens, so the order doesn't strictly matter here
        ArcDEXPool dexPool = new ArcDEXPool(myTokenAAddress, myTokenBAddress);
        arcDexPoolAddress = address(dexPool);

        vm.stopBroadcast();
        
        console.log("--- Deployment Complete ---");
        console.log("MyToken (MYTA) Address:", myTokenAAddress);
        console.log("MyTokenB (MYTB) Address:", myTokenBAddress);
        console.log("ArcDEXPool Address:", arcDexPoolAddress);
    }
}