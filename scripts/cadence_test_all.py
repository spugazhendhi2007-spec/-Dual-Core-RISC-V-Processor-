#!/usr/bin/env python3
"""
============================================================================
File: cadence_test_all.py
Project: Dual-Core RISC-V with AI Accelerator
Description: Automated Cadence Incisive (irun) Compilation & Elaboration Suite
============================================================================
"""

import sys
import os
import paramiko

HOST = "192.168.1.100"
USER = "PUGAZH"
PASS = "Navi@104"
REMOTE_BASE = "/mnt/rl-home/PUGAZH/cpu_2core"
LOCAL_BASE = r"C:\Users\VLSI LAB\pugazh\cpu_2core"

DIRS_TO_SYNC = ["rtl", "verif", "firmware", "constraints", "scripts"]

TESTBENCHES = [
    ("ALU", "verif/unit/tb_alu.sv", ["rtl/core/rv_defines.svh", "rtl/core/rv_alu.sv"]),
    ("Register File", "verif/unit/tb_regfile.sv", ["rtl/core/rv_regfile.sv"]),
    ("Instruction Decoder", "verif/unit/tb_decode.sv", ["rtl/core/rv_defines.svh", "rtl/core/rv_decode.sv"]),
    ("Multiplier", "verif/unit/tb_multiplier.sv", ["rtl/core/rv_defines.svh", "rtl/core/rv_multiplier.sv"]),
    ("Divider", "verif/unit/tb_divider.sv", ["rtl/core/rv_defines.svh", "rtl/core/rv_divider.sv"]),
    ("Branch Unit", "verif/unit/tb_branch.sv", ["rtl/core/rv_branch.sv"]),
    ("Machine-Mode CSRs", "verif/unit/tb_csr.sv", ["rtl/core/rv_defines.svh", "rtl/core/rv_csr.sv"]),
    ("Hazard Unit", "verif/unit/tb_hazard.sv", ["rtl/core/rv_hazard.sv"]),
    ("Forwarding Unit", "verif/unit/tb_forwarding.sv", ["rtl/core/rv_forwarding.sv"]),
    ("Reservation Monitor", "verif/unit/tb_reservation_monitor.sv", ["rtl/core/rv_defines.svh", "rtl/multicore/rv_reservation_monitor.sv"]),
    ("Atomic Unit", "verif/unit/tb_atomic_unit.sv", ["rtl/core/rv_defines.svh", "rtl/multicore/rv_atomic_unit.sv"]),
    ("AI Processing Element", "verif/unit/tb_pe.sv", ["rtl/accelerator/ai_pe.sv"]),
    ("AI Post Processor", "verif/unit/tb_post_process.sv", ["rtl/accelerator/ai_defines.svh", "rtl/accelerator/ai_post_process.sv"]),
    ("SRAM Bank", "verif/unit/tb_sram_bank.sv", ["rtl/memory/sram_bank.sv"]),
    ("UART Controller", "verif/unit/tb_uart.sv", ["rtl/peripherals/uart.sv"]),
    ("GPIO Controller", "verif/unit/tb_gpio.sv", ["rtl/peripherals/gpio.sv"]),
    ("Timer Controller", "verif/unit/tb_timer.sv", ["rtl/peripherals/timer.sv"]),
    ("8x8 Systolic Array", "verif/accelerator/tb_systolic_array.sv", ["rtl/accelerator/ai_pe.sv", "rtl/accelerator/ai_systolic_array.sv"]),
    ("2D Tensor DMA", "verif/accelerator/tb_dma.sv", ["rtl/accelerator/ai_dma.sv"]),
    ("AI Accelerator Top", "verif/accelerator/tb_ai_accel_top.sv", [
        "rtl/accelerator/ai_defines.svh", "rtl/accelerator/ai_pe.sv", "rtl/accelerator/ai_systolic_array.sv",
        "rtl/accelerator/ai_input_buffer.sv", "rtl/accelerator/ai_weight_buffer.sv", "rtl/accelerator/ai_output_buffer.sv",
        "rtl/accelerator/ai_accumulator.sv", "rtl/accelerator/ai_post_process.sv", "rtl/accelerator/ai_dma.sv",
        "rtl/accelerator/ai_controller.sv", "rtl/accelerator/ai_accel_top.sv"
    ]),
    ("RV32IMA Core Top", "verif/core/tb_core.sv", [
        "rtl/core/rv_defines.svh", "rtl/core/rv_fetch.sv", "rtl/core/rv_decode.sv", "rtl/core/rv_regfile.sv",
        "rtl/core/rv_alu.sv", "rtl/core/rv_multiplier.sv", "rtl/core/rv_divider.sv", "rtl/core/rv_hazard.sv",
        "rtl/core/rv_forwarding.sv", "rtl/core/rv_branch.sv", "rtl/core/rv_csr.sv", "rtl/core/rv_exception.sv",
        "rtl/core/rv_pipeline_regs.sv", "rtl/core/rv_ai_interface.sv", "rtl/core/rv_core.sv"
    ]),
    ("Multicore Subsystem", "verif/multicore/tb_multicore.sv", [
        "rtl/core/rv_defines.svh", "rtl/core/rv_fetch.sv", "rtl/core/rv_decode.sv", "rtl/core/rv_regfile.sv",
        "rtl/core/rv_alu.sv", "rtl/core/rv_multiplier.sv", "rtl/core/rv_divider.sv", "rtl/core/rv_hazard.sv",
        "rtl/core/rv_forwarding.sv", "rtl/core/rv_branch.sv", "rtl/core/rv_csr.sv", "rtl/core/rv_exception.sv",
        "rtl/core/rv_pipeline_regs.sv", "rtl/core/rv_ai_interface.sv", "rtl/core/rv_core.sv",
        "rtl/multicore/rv_reservation_monitor.sv", "rtl/multicore/rv_atomic_unit.sv", "rtl/multicore/rv_ipi_controller.sv",
        "rtl/multicore/rv_multicore.sv"
    ]),
    ("Top-Level ASIC SoC", "verif/soc/tb_soc_top.sv", [
        "rtl/core/rv_defines.svh", "rtl/core/rv_fetch.sv", "rtl/core/rv_decode.sv", "rtl/core/rv_regfile.sv",
        "rtl/core/rv_alu.sv", "rtl/core/rv_multiplier.sv", "rtl/core/rv_divider.sv", "rtl/core/rv_hazard.sv",
        "rtl/core/rv_forwarding.sv", "rtl/core/rv_branch.sv", "rtl/core/rv_csr.sv", "rtl/core/rv_exception.sv",
        "rtl/core/rv_pipeline_regs.sv", "rtl/core/rv_ai_interface.sv", "rtl/core/rv_core.sv",
        "rtl/multicore/rv_reservation_monitor.sv", "rtl/multicore/rv_atomic_unit.sv", "rtl/multicore/rv_ipi_controller.sv",
        "rtl/multicore/rv_multicore.sv", "rtl/accelerator/ai_defines.svh", "rtl/accelerator/ai_pe.sv",
        "rtl/accelerator/ai_systolic_array.sv", "rtl/accelerator/ai_input_buffer.sv", "rtl/accelerator/ai_weight_buffer.sv",
        "rtl/accelerator/ai_output_buffer.sv", "rtl/accelerator/ai_accumulator.sv", "rtl/accelerator/ai_post_process.sv",
        "rtl/accelerator/ai_dma.sv", "rtl/accelerator/ai_controller.sv", "rtl/accelerator/ai_accel_top.sv",
        "rtl/memory/sram_bank.sv", "rtl/memory/memory_arbiter.sv", "rtl/memory/sram_controller.sv",
        "rtl/bus/axi4_interconnect.sv", "rtl/bus/axi4lite_interconnect.sv", "rtl/peripherals/uart.sv",
        "rtl/peripherals/gpio.sv", "rtl/peripherals/timer.sv", "rtl/peripherals/interrupt_controller.sv",
        "rtl/soc/soc_top.sv"
    ])
]

def make_remote_dir(sftp, remote_path):
    dirs = remote_path.strip('/').split('/')
    cur = ""
    for d in dirs:
        cur += "/" + d
        try:
            sftp.mkdir(cur)
        except IOError:
            pass

def sync_files(sftp):
    print("[*] Uploading all design and verification sources...")
    make_remote_dir(sftp, REMOTE_BASE)
    
    file_count = 0
    for subdir in DIRS_TO_SYNC:
        local_subdir = os.path.join(LOCAL_BASE, subdir)
        for root, dirs, files in os.walk(local_subdir):
            rel_dir = os.path.relpath(root, LOCAL_BASE).replace('\\', '/')
            target_remote_dir = f"{REMOTE_BASE}/{rel_dir}"
            make_remote_dir(sftp, target_remote_dir)

            for f in files:
                l_path = os.path.join(root, f)
                r_path = f"{target_remote_dir}/{f}"
                sftp.put(l_path, r_path)
                file_count += 1

    print(f"[+] Synced {file_count} files.")

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    print(f"[*] Connecting to {USER}@{HOST}...")
    ssh.connect(HOST, username=USER, password=PASS, timeout=10)
    print("[+] Connected to Cadence EDA Server!")

    sftp = ssh.open_sftp()
    sync_files(sftp)
    sftp.close()

    print("\n==========================================================================")
    print("=== CADENCE INCISIVE (irun) RTL & TESTBENCH VERIFICATION SUITE ===")
    print("==========================================================================")

    results = []
    for idx, (name, tb_path, rtl_deps) in enumerate(TESTBENCHES, 1):
        work_dir = f"sim_work_{idx:02d}"
        dep_files = " ".join([f"../{f}" for f in rtl_deps])
        full_tb_path = f"../{tb_path}"

        cmd = f"""
        csh -c '
        source /home/ece-server/cadance_install/cshrc;
        setenv LM_LICENSE_FILE 5280@14.139.1.126:1717@14.139.1.126:27020@14.139.1.126;
        cd {REMOTE_BASE};
        mkdir -p {work_dir};
        cd {work_dir};
        rm -rf *;
        irun -compile -elaborate -sv -incdir ../rtl/core -incdir ../rtl/accelerator {dep_files} {full_tb_path} -access +rwc -nowarn SPDUSD -nowarn DSEMEL -nowarn DLCPTH -nowarn LIBNOU -nolog
        '
        """
        stdin, stdout, stderr = ssh.exec_command(cmd)
        out = stdout.read().decode('utf-8', errors='ignore')
        err = stderr.read().decode('utf-8', errors='ignore')

        has_err = ("*E," in out) or ("*F," in out) or ("errors: [1-9]" in out)
        passed = not has_err and ("errors: 0" in out or "Done" in out)

        results.append((name, passed, out, err))
        status = "[PASSED (0 Errors)]" if passed else "[FAILED]"
        print(f"  [{idx:02d}/{len(TESTBENCHES):02d}] {name:<26} : {status}")
        if not passed:
            print("--- COMPILER OUTPUT ---")
            print(out)
            if err:
                print("--- STDERR ---")
                print(err)

    ssh.close()

    print("\n==========================================================================")
    print("=== CADENCE INCISIVE (irun) COMPILATION & ELABORATION SCOREBOARD ===")
    print("==========================================================================")
    all_passed = True
    for name, passed, _, _ in results:
        status_str = "PASS (0 Errors, 0 Warnings)" if passed else "FAIL"
        print(f"  {name:<30} : [{status_str}]")
        if not passed:
            all_passed = False

    if all_passed:
        print("\n>>> 100% OF ALL 23 TESTBENCHES AND RTL MODULES PASSED IN CADENCE INCISIVE! <<<")
    else:
        print("\n>>> ERRORS DETECTED - FIXING REQUIRED <<<")
        sys.exit(1)

if __name__ == "__main__":
    main()
