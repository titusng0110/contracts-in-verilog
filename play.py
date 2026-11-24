import os
import subprocess
import sys
import time

# 1. Compile with Verilator
# Note: Executables built by Verilator are placed in the 'obj_dir' directory by default.
compile_res = subprocess.run(
    [
        "verilator",
        "--binary",  # Automatically build a standalone executable
        "--timing",  # Required if your testbench uses delays (#delay)
        "-sv",  # Parse as SystemVerilog
        "-Wno-fatal",  # Prevent lint warnings from aborting compilation
        "-j",
        "0",  # Use all CPU cores for faster C++ compilation
        "--top-module",
        "tb_employment_contract",  # Top testbench module name
        "-o",
        "movie_sim",  # Name of the output binary
        "employment_contract.sv",
        "tb_employment_contract.sv",
    ]
)

if compile_res.returncode != 0:
    print("[Error] Verilator compilation failed.")
    sys.exit(1)

# 2. Run simulation and capture output
# Verilator places the binary inside the 'obj_dir' directory
sim_proc = subprocess.run(
    ["./obj_dir/movie_sim"], capture_output=True, text=True
)

if sim_proc.returncode != 0:
    print("[Error] Simulation failed:")
    print(sim_proc.stderr)
    sys.exit(1)

frames = [f.strip() for f in sim_proc.stdout.split("===FRAME===") if f.strip()]

# 3. Clear terminal once and hide cursor
os.system("clear")
sys.stdout.write("\033[?25l")  # Hide cursor for clean video capture

try:
    for frame in frames:
        # Move cursor to home position (row 1, col 1) without scrolling
        sys.stdout.write("\033[H")
        for line in frame.splitlines():
            # \033[K clears any leftover characters from previous line
            sys.stdout.write(line + "\033[K\n")
        sys.stdout.flush()
        time.sleep(1)
finally:
    # Always restore cursor when finished
    sys.stdout.write("\033[?25h\n")
    sys.stdout.flush()

print("[Simulation Finished]")
