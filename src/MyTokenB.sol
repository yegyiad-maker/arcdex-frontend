// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MyTokenB is ERC20 {
    /**
     * @notice Constructor for MyTokenB (MYTB).
     * @param initialSupply The whole token amount (e.g., 1,000,000) to mint.
     * It will be scaled by 10^18 (or the token's decimals).
     */
    constructor(uint256 initialSupply) ERC20("MyToken B", "MYTB") {
        // Mints supply (e.g., 1,000,000 * 10^18) to the deployer (msg.sender)
        _mint(msg.sender, initialSupply * 10**decimals());
    }

    /// @notice Allows minting of new tokens for testing and liquidity scripts.
    function mint(address to, uint256 amount) public {
        // Since this is a mock token for testing, we allow anyone to mint.
        _mint(to, amount);
    }
}