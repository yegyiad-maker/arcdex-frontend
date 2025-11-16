import subprocess
import os
import time

# --- Configuration ---
# Number of times to run the forge script
RUN_COUNT = 100 

# The command to execute the swap script.
# We ensure the required environment variables are checked/used here.
FORGE_COMMAND = [
    "forge",
    "script",
    "script/PerformSwap.s.sol:PerformSwapScript",
    "--rpc-url", os.environ.get("ARC_TESTNET_RPC_URL", "RPC_URL_NOT_SET"),
    "--broadcast",
    "-vvvv" # User requested maximum verbosity
]

def run_forge_script(iteration):
    """
    Executes the forge swap script command and handles output/errors.
    """
    print(f"\n--- Running swap iteration {iteration}/{RUN_COUNT} ---")
    
    # Check if RPC URL is available before attempting the run
    if FORGE_COMMAND[5] == "RPC_URL_NOT_SET":
        print("ERROR: ARC_TESTNET_RPC_URL environment variable is not set.")
        return False

    # Execute the command
    try:
        # 🛑 CRITICAL FIX: Added encoding='utf-8' to handle Windows console output
        result = subprocess.run(
            FORGE_COMMAND,
            check=True,  
            capture_output=True,
            text=True,
            encoding='utf-8' # <--- THIS FIXES THE UnicodeDecodeError
        )
        print(f"Iteration {iteration} successful. Swap transaction broadcasted.")
        
        # Print key transaction details from the verbose output
        output_lines = result.stdout.split('\n')
        
        # Look for relevant output lines (Hash, Total Paid, etc.)
        for line in output_lines:
            line = line.strip()
            if line.startswith('Script ran successfully.') or \
               'Hash:' in line or \
               'Total Paid:' in line:
                print(f"-> {line}")

    except subprocess.CalledProcessError as e:
        print(f"Iteration {iteration} FAILED with error code {e.returncode}.")
        print("--- Stdout (Partial Output) ---")
        # Print only the first 20 lines of stdout to avoid flooding the console with -vvvv output
        print('\n'.join(e.stdout.split('\n')[:20]))
        print("--- Stderr ---")
        print(e.stderr)
        return False
    except FileNotFoundError:
        print("FATAL ERROR: 'forge' command not found. Ensure Foundry is installed and in your PATH.")
        return False
    
    return True

def main():
    """Main function to loop the script execution."""
    successful_runs = 0
    start_time = time.time()
    
    print(f"Starting automated swap test: {RUN_COUNT} iterations.")
    
    for i in range(1, RUN_COUNT + 1):
        if run_forge_script(i):
            successful_runs += 1
        
        # Small delay to mitigate rate limiting issues
        time.sleep(0.2) 

    end_time = time.time()
    
    print("\n===========================================")
    print(f"Swap Automation Complete: {successful_runs} / {RUN_COUNT} runs successful.")
    print(f"Total time elapsed: {end_time - start_time:.2f} seconds.")
    print("===========================================")

if __name__ == "__main__":
    main()