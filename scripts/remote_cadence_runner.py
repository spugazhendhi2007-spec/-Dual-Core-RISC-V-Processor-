#!/usr/bin/env python3
"""
============================================================================
File: remote_cadence_runner.py
Project: Dual-Core RISC-V with AI Accelerator
Description: Fast Automated Remote Cadence Incisive (irun) Test Execution
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
    ("tb_alu", "verif/unit/tb_alu.sv", "rtl/core/rv_alu.sv"),
    ("tb_regfile", "verif/unit/tb_regfile.sv", "rtl/core/rv_regfile.sv"),
    ("tb_decode", "verif/unit/tb_decode.sv", "rtl/core/rv_decode.sv"),
    ("tb_multiplier", "verif/unit/tb_multiplier.sv", "rtl/core/rv_multiplier.sv"),
    ("tb_divider", "verif/unit/tb_divider.sv", "rtl/core/rv_divider.sv"),
    ("tb_branch", "verif/unit/tb_branch.sv", "rtl/core/rv_branch.sv"),
    ("tb_csr", "verif/unit/tb_csr.sv", "rtl/core/rv_csr.sv"),
    ("tb_hazard", "verif/unit/tb_hazard.sv", "rtl/core/rv_hazard.sv"),
    ("tb_forwarding", "verif/unit/tb_forwarding.sv", "rtl/core/rv_forwarding.sv"),
    ("tb_reservation_monitor", "verif/unit/tb_reservation_monitor.sv", "rtl/multicore/rv_reservation_monitor.sv"),
    ("tb_atomic_unit", "verif/unit/tb_atomic_unit.sv", "rtl/multicore/rv_atomic_unit.sv"),
    ("tb_pe", "verif/unit/tb_pe.sv", "rtl/accelerator/ai_pe.sv"),
    ("tb_post_process", "verif/unit/tb_post_process.sv", "rtl/accelerator/ai_post_process.sv"),
    ("tb_sram_bank", "verif/unit/tb_sram_bank.sv", "rtl/memory/sram_bank.sv"),
    ("tb_uart", "verif/unit/tb_uart.sv", "rtl/peripherals/uart.sv"),
    ("tb_gpio", "verif/unit/tb_gpio.sv", "rtl/peripherals/gpio.sv"),
    ("tb_timer", "verif/unit/tb_timer.sv", "rtl/peripherals/timer.sv"),
    ("tb_systolic_array", "verif/accelerator/tb_systolic_array.sv", "rtl/accelerator/ai_pe.sv rtl/accelerator/ai_systolic_array.sv"),
    ("tb_dma", "verif/accelerator/tb_dma.sv", "rtl/accelerator/ai_dma.sv"),
    ("tb_ai_accel_top", "verif/accelerator/tb_ai_accel_top.sv", "rtl/accelerator/ai_pe.sv rtl/accelerator/ai_systolic_array.sv rtl/accelerator/ai_input_buffer.sv rtl/accelerator/ai_weight_buffer.sv rtl/accelerator/ai_output_buffer.sv rtl/accelerator/ai_accumulator.sv rtl/accelerator/ai_post_process.sv rtl/accelerator/ai_dma.sv rtl/accelerator/ai_controller.sv rtl/accelerator/ai_accel_top.sv"),
    ("tb_core", "verif/core/tb_core.sv", "rtl/core/rv_fetch.sv rtl/core/rv_decode.sv rtl/core/rv_regfile.sv rtl/core/rv_alu.sv rtl/core/rv_multiplier.sv rtl/core/rv_divider.sv rtl/core/rv_hazard.sv rtl/core/rv_forwarding.sv rtl/core/rv_branch.sv rtl/core/rv_csr.sv rtl/core/rv_exception.sv rtl/core/rv_pipeline_regs.sv rtl/core/rv_ai_interface.sv rtl/core/rv_core.sv"),
    ("tb_multicore", "verif/multicore/tb_multicore.sv", "rtl/core/rv_fetch.sv rtl/core/rv_decode.sv rtl/core/rv_regfile.sv rtl/core/rv_alu.sv rtl/core/rv_multiplier.sv rtl/core/rv_divider.sv rtl/core/rv_hazard.sv rtl/core/rv_forwarding.sv rtl/core/rv_branch.sv rtl/core/rv_csr.sv rtl/core/rv_exception.sv rtl/core/rv_pipeline_regs.sv rtl/core/rv_ai_interface.sv rtl/core/rv_core.sv rtl/multicore/rv_reservation_monitor.sv rtl/multicore/rv_atomic_unit.sv rtl/multicore/rv_ipi_controller.sv rtl/multicore/rv_multicore.sv"),
    ("tb_soc_top", "verif/soc/tb_soc_top.sv", "rtl/core/rv_fetch.sv rtl/core/rv_decode.sv rtl/core/rv_regfile.sv rtl/core/rv_alu.sv rtl/core/rv_multiplier.sv rtl/core/rv_divider.sv rtl/core/rv_hazard.sv rtl/core/rv_forwarding.sv rtl/core/rv_branch.sv rtl/core/rv_csr.sv rtl/core/rv_exception.sv rtl/core/rv_pipeline_regs.sv rtl/core/rv_ai_interface.sv rtl/core/rv_core.sv rtl/multicore/rv_reservation_monitor.sv rtl/multicore/rv_atomic_unit.sv rtl/multicore/rv_ipi_controller.sv rtl/multicore/rv_multicore.sv rtl/accelerator/ai_pe.sv rtl/accelerator/ai_systolic_array.sv rtl/accelerator/ai_input_buffer.sv rtl/accelerator/ai_weight_buffer.sv rtl/accelerator/ai_output_buffer.sv rtl/accelerator/ai_accumulator.sv rtl/accelerator/ai_post_process.sv rtl/accelerator/ai_dma.sv rtl/accelerator/ai_controller.sv rtl/accelerator/ai_accel_top.sv rtl/memory/sram_bank.sv rtl/memory/memory_arbiter.sv rtl/memory/sram_controller.sv rtl/bus/axi4_interconnect.sv rtl/bus/axi4lite_interconnect.sv rtl/peripherals/uart.sv rtl/peripherals/gpio.sv rtl/peripherals/timer.sv rtl/peripherals/interrupt_controller.sv rtl/soc/soc_top.sv"),
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
    print("[*] Uploading design & verification sources via SFTP...")
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

    print(f"[+] Successfully synced {file_count} files.")

def run_tests():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    print(f"[*] Connecting to {USER}@{HOST}...")
    ssh.connect(HOST, username=USER, password=PASS, timeout=10)
    print("[+] Connected to Cadence EDA Server!")

    sftp = ssh.open_sftp()
    sync_files(sftp)
    sftp.close()

    print("\n==========================================================================")
    print("=== RUNNING CADENCE INCISIVE (irun) ON ALL MODULES AND TESTBENCHES ===")
    print("==========================================================================")

    results = {}
    for tb_name, tb_file, rtl_deps in TESTBENCHES:
        print(f"\n---> [SIMULATING] {tb_name} ...", flush=True)
        cmd = f"csh -c 'source /home/ece-server/cadance_install/cshrc; cd {REMOTE_BASE}; irun -64bit -sv -incdir rtl/core -incdir rtl/accelerator {rtl_deps} {tb_file} -access +rwc -nowarn DLCPTH -nowarn LIBNOU -nolog'"
        stdin, stdout, stderr = ssh.exec_command(cmd)
        out = stdout.read().decode('utf-8', errors='ignore')
        err = stderr.read().decode('utf-8', errors='ignore')

        passed = ("PASSED" in out) and ("*E," not in out) and ("*F," not in out)
        results[tb_name] = (passed, out, err)

        if passed:
            print(f"[PASSED] {tb_name}")
        else:
            print(f"[FAILED] {tb_name}")
            print("--- COMPILER / SIMULATOR OUTPUT ---")
            print(out)
            if err:
                print("--- STDERR ---")
                print(err)

    ssh.close()

    print("\n==========================================================================")
    print("=== CADENCE INCISIVE (irun) TEST EXECUTION SCOREBOARD ===")
    print("==========================================================================")
    all_ok = True
    for tb_name, (passed, out, err) in results.items():
        status_str = "PASSED" if passed else "FAILED"
        print(f"  {tb_name:<28} : [{status_str}]")
        if not passed:
            all_ok = False

    if all_ok:
        print("\n>>> ALL 23 TESTBENCHES PASSED 100% CLEANLY IN CADENCE INCISIVE! <<<")
    else:
        print("\n>>> SOME MODULES REQUIRE ATTENTION <<<")
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
