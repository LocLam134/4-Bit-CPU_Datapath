# 4-Bit RISC CPU Datapath with 3-Stage Pipeline (Verilog HDL)

![Language](https://img.shields.io/badge/Language-Verilog_HDL-blue.svg)
![EDA Tool](https://img.shields.io/badge/Vivado-2026.1-orange.svg)
![Target FPGA](https://img.shields.io/badge/FPGA-Xilinx_Virtex--7-red.svg)
![Verification](https://img.shields.io/badge/Verification-88%2F88_Checks_PASSED-brightgreen.svg)

## 📌 Project Overview
This repository contains the complete RTL design, technology synthesis, and automated verification of a **4-bit RISC CPU Datapath** featuring a **3-Stage Pipeline (IF / ID / EX)** and **Harvard Architecture**. The processor is designed from scratch in **Verilog HDL** and verified/synthesized using **Xilinx/AMD Vivado ML Edition 2026.1** targeting the Virtex-7 FPGA (`xc7vx485tffg1157-1`).

---

## ✨ Key Architectural Features
- **Harvard Architecture:** Physically separated Instruction ROM (16 x 12-bit) and Data RAM (16 x 4-bit) buses eliminate structural hazards, enabling simultaneous instruction fetch and data memory access.
- **3-Stage Pipeline Organization:**
  1. **IF (Instruction Fetch):** 4-bit Program Counter (`PC`), `PC_MUX`, Instruction Memory (`IMEM`), and `IF/ID` Pipeline Register (`IR`).
  2. **ID (Instruction Decode):** Central Control Unit (`CU`), Dual-Port Register File (`RF` with $R0-R3$), and `ID/EX` Pipeline Register (`ID_EX`).
  3. **EX & WB (Execute & Write-Back):** 4-bit `ALU`, `OPERAND_MUX`, Condition Flag Register (`Zero`, `Carry`), Data Memory (`DMEM`), and Write-Back Multiplexer (`WB_MUX`).
- **Peak Throughput:** Sustains an ideal execution rate of **1 Instruction Per Cycle (1 IPC)** during sequential instruction streams.
- **Control Hazard Resolution:** Built-in hardware Branch Unit (`flush = pc_sel`) automatically injects 2 bubble cycles (`NOP = 12'hC00`) and clears validity bits upon taken branches (`JMP` or `JZ`), preventing speculative state corruption.

---

## 📂 Hardware Hierarchy & File Descriptions

```text
├── sources/
│   ├── cpu_top.v               # Top-level processor integration (12 sub-modules)
│   ├── program_counter.v       # 4-bit synchronous Program Counter (PC)
│   ├── instruction_memory.v    # 16x12-bit Instruction ROM (initialized via .mem)
│   ├── instruction_register.v  # IF/ID pipeline register with synchronous flush
│   ├── control_unit.v          # Instruction Decoder (ID) & Branch Unit (EX)
│   ├── register_file.v         # 4x4-bit Register File (R0-R3, 2-read / 1-write)
│   ├── pipeline_register.v     # ID/EX pipeline register for control & datapath sync
│   ├── alu.v                   # 4-bit Arithmetic and Logic Unit (8 operations)
│   ├── flag_register.v         # Sequential Zero (Z) and Carry (C) status flags
│   ├── data_memory.v           # 16x4-bit synchronous Data RAM
│   └── mux.v                   # Parameterized 2-to-1 Multiplexers (PC, Operand, WB)
├── sim/
│   ├── tb_regression_88.v      # Unified self-checking regression testbench (88 checks)
│   ├── tb_alu.v                # Phase 1: Standalone ALU verification (11 checks)
│   ├── tb_register_file.v      # Phase 2: Register File verification (11 checks)
│   ├── tb_control_unit.v       # Phase 3: Decoder & Branch Unit verification (22 checks)
│   └── tb_cpu_top.v            # Phase 4: Full CPU integration verification (44 checks)
├── programs                    # Machine-code test programs (program, arith, logic, jump)
└── Screenshots/                # Vivado schematics, waveforms, truth tables, and reports
```

---

## 📖 Instruction Set Architecture (12-Bit ISA) & Truth Tables

### 1. Instruction Word Format (12-Bit Fixed)
| Bits `[11:8]` | Bits `[7:6]` | Bits `[5:4]` | Bits `[3:0]` |
| :---: | :---: | :---: | :---: |
| **Opcode (4 bits)** | **Rd (2 bits)** | **Rs (2 bits)** | **Immediate / Address (4 bits)** |

### 2. Instruction Decoder Truth Table (ID Stage)
| Opcode | Mnemonic | Operation | `alu_ctrl` | `alu_src_sel` | `wb_sel` | `reg_we` | `mem_we` | `zero_we` | `carry_we` | `is_jmp` | `is_jz` |
| :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `0000` | **ADD** | `Rd <= Rd + Rs` | `000` | 0 | 0 | 1 | 0 | 1 | 1 | 0 | 0 |
| `0001` | **SUB** | `Rd <= Rd - Rs` | `001` | 0 | 0 | 1 | 0 | 1 | 1 | 0 | 0 |
| `0010` | **AND** | `Rd <= Rd & Rs` | `010` | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 0 |
| `0011` | **OR** | `Rd <= Rd \| Rs` | `011` | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 0 |
| `0100` | **XOR** | `Rd <= Rd ^ Rs` | `100` | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 0 |
| `0101` | **NOT** | `Rd <= ~Rd` | `101` | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 0 |
| `0110` | **LDI** | `Rd <= imm` | `110` | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| `0111` | **MOV** | `Rd <= Rs` | `110` | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| `1000` | **LOAD** | `Rd <= DMEM[imm]` | `110` | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `1001` | **STORE** | `DMEM[imm] <= Rd` | `110` | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| `1010` | **JMP** | `PC <= imm` | `000` | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| `1011` | **JZ** | `if (Z) PC <= imm` | `000` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| `1100–1111` | **NOP** | No Operation | `000` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

> **Notes:** `alu_src_sel`: `0 = Rs`, `1 = immediate` | `wb_sel`: `0 = ALU`, `1 = Memory` | Reserved opcodes `1100–1111` default to safe NOP values to prevent unintentional latches.

### 3. ALU Function Truth Table (`alu.v`)
| `alu_ctrl [2:0]` | Operation | `result [3:0]` | `carry` | `zero` |
| :---: | :---: | :--- | :--- | :--- |
| `000` | **ADD** | `A + B` (low 4 bits) | Carry-out of `A + B` | `1` if `result == 0000`, else `0` |
| `001` | **SUB** | `A - B` | `1` if `A >= B` (no borrow), else `0` | `1` if `result == 0000`, else `0` |
| `010` | **AND** | `A & B` | `0` | `1` if `result == 0000`, else `0` |
| `011` | **OR** | `A \| B` | `0` | `1` if `result == 0000`, else `0` |
| `100` | **XOR** | `A ^ B` | `0` | `1` if `result == 0000`, else `0` |
| `101` | **NOT** | `~A` | `0` | `1` if `result == 0000`, else `0` |
| `110` | **PASS** | `B` | `0` | `1` if `result == 0000`, else `0` |
| `111` | **Default** | `0000` | `0` | `1` |

> **Note:** `zero = ~|result` (reduction NOR of `result`).

### 4. Branch Unit Truth Table (EX Stage)
| `is_jmp` | `is_jz` | `zero_flag` | `pc_sel` | `flush` | Action |
| :---: | :---: | :---: | :---: | :---: | :--- |
| 0 | 0 | 0 | 0 | 0 | `PC + 1` (no branch) |
| 0 | 0 | 1 | 0 | 0 | `PC + 1` (no branch) |
| 0 | 1 | 0 | 0 | 0 | `JZ` not taken, `PC + 1` |
| 0 | 1 | 1 | 1 | 1 | `JZ` taken, jump target |
| 1 | 0 | 0 | 1 | 1 | `JMP` taken, jump target |
| 1 | 0 | 1 | 1 | 1 | `JMP` taken, jump target |

> **Boolean Logic:** `pc_sel = ex_is_jmp | (ex_is_jz & zero_flag)` and `flush = pc_sel`.

---

## 🧪 Automated Verification Results
The processor is verified using a unified self-checking master regression suite (`tb_regression_88.v`) covering 4 hierarchical test phases:

```text
=======================================================
                 GRAND SUMMARY REPORT                  
=======================================================
 Student name: Lam Duy Loc
 Student ID:   SE190907
-------------------------------------------------------
 Phase 1: ALU Tests           : 11 / 11 checks PASSED
 Phase 2: Register File Tests : 11 / 11 checks PASSED
 Phase 3: Control Unit Tests  : 22 / 22 checks PASSED
 Phase 4: CPU Top Level Tests : 44 / 44 checks PASSED
-------------------------------------------------------
OVERALL VERDICT: PASSED (88 of 88 checks OK)
=======================================================
$finish called at time : 866 ns
```

---

## 📊 FPGA Synthesis & Resource Utilization
- **Target Device:** Xilinx Virtex-7 (`xc7vx485tffg1157-1`)
- **Elaborated RTL Netlist:** 13 Cells, 28 I/O Ports, 116 Nets
- **Synthesis Status:** `Synthesis Complete` (0 Errors, 0 Unintended Latches)

| Resource Type | Used | Available | Utilization (%) | Architectural Breakdown |
| :--- | :---: | :---: | :---: | :--- |
| **Slice LUTs** | **35** | 303,600 | `0.01%` | ALU, Instruction Decoder, Branch Unit, and 3 MUXes |
| **Slice Registers (FFs)** | **50** | 607,200 | `0.01%` | 16 (RF) + 4 (PC) + 2 (Flags) + 28 (Pipeline Registers) |
| **Bonded I/O Ports** | **28** | 600 | `4.67%` | 2 Inputs (`clk`, `rst`) + 26 Observation Outputs |

---

## 🖼️ Hardware & Simulation Screenshots

### 1. Project Hierarchy & RTL Sources
<img width="1915" height="985" alt="Project_Sources" src="https://github.com/user-attachments/assets/b6f8c3ad-c3d1-4f27-b6f8-efc66ef96e97" />

### 2. RTL Elaborated Schematic
<img width="1357" height="512" alt="Schematic2" src="https://github.com/user-attachments/assets/956d64c6-4c4f-4ac5-9bd0-70de77f5e16b" />

### 3. Detailed 3-Stage Pipeline Waveform (200 ns – 360 ns)
<img width="1917" height="1011" alt="waveform2" src="https://github.com/user-attachments/assets/a94db0eb-370a-4f9b-b7fd-38d95c9a8ce3" />

### 4. Full Simulation Waveform (0 ns – 866 ns)
<img width="1917" height="1025" alt="waveform1" src="https://github.com/user-attachments/assets/753acf6b-16df-49ba-ac0d-4001f52d6162" />

### 5. Automated Regression Verification Log (88/88 Checks Passed)
<img width="1917" height="1025" alt="Tcl_Console" src="https://github.com/user-attachments/assets/e1ef758b-a32b-4542-adfe-44f01b523cf9" />

### 6. FPGA Resource Utilization Report
<img width="1916" height="981" alt="Report_Utilization" src="https://github.com/user-attachments/assets/deabeea0-8c15-471e-9c58-dd15f32a17cd" />

---

## 🚀 How to Run in Vivado
1. Open **Vivado ML Edition** and create a new RTL project targeting `xc7vx485tffg1157-1`.
2. Add all Verilog design files from `sources/` as **Design Sources** and set `cpu_top.v` as the top module.
3. Add `tb_regression_88.v` and all `.mem` program files as **Simulation Sources**.
4. Click **Run Simulation -> Run Behavioral Simulation** and inspect the **Tcl Console** for the `OVERALL VERDICT: PASSED (88 of 88 checks OK)` summary at `866 ns`.

---

## 👨‍💻 Author
- **Name:** Lam Duy Loc
- **Student ID:** SE190907
- **Specialization:** Semiconductor & Integrated Circuit Design — FPT University
- GitHub: https://github.com/LocLam134
- Email: loc.slh11357@gmail.com
