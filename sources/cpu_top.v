// ==============================================================
// MODULE: cpu_top.v
// Description: Top-level integration of the 4-bit 3-stage pipelined RISC CPU
// ==============================================================
module cpu_top #(
    parameter PROGRAM_FILE = "program.mem" // Default program file to load
)(
    input             clk,         // System clock
    input             rst,         // System synchronous reset

    // Observable debug outputs for waveform verification or FPGA LEDs
    output     [3:0]  pc_out,      // Current fetch address (PC)
    output     [11:0] instr_out,   // Instruction word currently in Execute stage
    output     [3:0]  alu_out,     // ALU result
    output     [3:0]  wb_data_out, // Data written back to destination register
    output            zero_out,    // Registered Zero flag
    output            carry_out    // Registered Carry flag
);

    // ----------------------------------------------------------
    // Inter-stage global control signals
    // ----------------------------------------------------------
    wire        pc_sel;  // PC source select (from EX stage Branch Unit)
    wire        flush;   // Pipeline flush control (from EX stage Branch Unit)
    wire [3:0]  ex_imm;  // Target jump address / immediate from EX stage

    // ==========================================================
    // STAGE 1: IF (Instruction Fetch)
    // ==========================================================
    wire [3:0]  pc;
    wire [3:0]  pc_plus_1 = pc + 4'd1;
    wire [3:0]  pc_next;
    wire [11:0] fetched;

    // PC MUX: selects between sequential PC+1 and branch target
    mux2 PC_MUX (
        .d0  (pc_plus_1),
        .d1  (ex_imm),
        .sel (pc_sel),
        .y   (pc_next)
    );

    // Program Counter register
    program_counter PC (
        .clk     (clk),
        .rst     (rst),
        .pc_en   (1'b1), // Active fetch every cycle
        .pc_next (pc_next),
        .pc_out  (pc)
    );

    // Instruction Memory ROM
    instruction_memory #(.PROGRAM_FILE(PROGRAM_FILE)) IMEM (
        .address     (pc),
        .instruction (fetched)
    );

    // IF/ID Pipeline Register (Instruction Register)
    wire [11:0] id_instr;
    wire [3:0]  id_pc;
    wire        id_valid;

    instruction_register IR (
        .clk             (clk),
        .rst             (rst),
        .ir_load         (1'b1),
        .flush           (flush),
        .pc_in           (pc),
        .instruction_in  (fetched),
        .instruction_out (id_instr),
        .pc_out          (id_pc),
        .valid_out       (id_valid)
    );

    // ==========================================================
    // STAGE 2: ID (Instruction Decode)
    // ==========================================================
    wire [3:0] id_opcode = id_instr[11:8];
    wire [1:0] id_rd     = id_instr[7:6];
    wire [1:0] id_rs     = id_instr[5:4];
    wire [3:0] id_imm    = id_instr[3:0];

    wire [2:0] id_alu_ctrl;
    wire       id_alu_src_sel, id_wb_sel, id_reg_we, id_mem_we;
    wire       id_zero_we, id_carry_we, id_is_jmp, id_is_jz;

    wire       ex_is_jmp, ex_is_jz;
    wire       zero_flag, carry_flag;

    // Hardwired Control Unit
    control_unit CU (
        // Decode logic inputs/outputs
        .opcode      (id_opcode),
        .alu_ctrl    (id_alu_ctrl),
        .alu_src_sel (id_alu_src_sel),
        .wb_sel      (id_wb_sel),
        .reg_we      (id_reg_we),
        .mem_we      (id_mem_we),
        .zero_we     (id_zero_we),
        .carry_we    (id_carry_we),
        .is_jmp      (id_is_jmp),
        .is_jz       (id_is_jz),
        // Execute logic branch interface
        .ex_is_jmp   (ex_is_jmp),
        .ex_is_jz    (ex_is_jz),
        .zero_flag   (zero_flag),
        .pc_sel      (pc_sel),
        .flush       (flush)
    );

    // ID/EX Pipeline Register
    wire [2:0]  ex_alu_ctrl;
    wire        ex_alu_src_sel, ex_wb_sel, ex_reg_we, ex_mem_we;
    wire        ex_zero_we, ex_carry_we;
    wire [1:0]  ex_rd, ex_rs;
    wire [3:0]  ex_pc;
    wire        ex_valid;
    wire [11:0] ex_instr;

    pipeline_register ID_EX (
        .clk            (clk),
        .rst            (rst),
        .flush          (flush),
        // Inputs from ID
        .alu_ctrl_in    (id_alu_ctrl),
        .alu_src_sel_in (id_alu_src_sel),
        .wb_sel_in      (id_wb_sel),
        .reg_we_in      (id_reg_we),
        .mem_we_in      (id_mem_we),
        .zero_we_in     (id_zero_we),
        .carry_we_in    (id_carry_we),
        .is_jmp_in      (id_is_jmp),
        .is_jz_in       (id_is_jz),
        .rd_in          (id_rd),
        .rs_in          (id_rs),
        .imm_in         (id_imm),
        .pc_in          (id_pc),
        .valid_in       (id_valid),
        .instr_in       (id_instr),
        // Outputs to EX
        .alu_ctrl       (ex_alu_ctrl),
        .alu_src_sel    (ex_alu_src_sel),
        .wb_sel         (ex_wb_sel),
        .reg_we         (ex_reg_we),
        .mem_we         (ex_mem_we),
        .zero_we        (ex_zero_we),
        .carry_we       (ex_carry_we),
        .is_jmp         (ex_is_jmp),
        .is_jz          (ex_is_jz),
        .rd             (ex_rd),
        .rs             (ex_rs),
        .imm            (ex_imm),
        .pc             (ex_pc),
        .valid          (ex_valid),
        .instr          (ex_instr)
    );

    // ==========================================================
    // STAGE 3: EX (Execute, Memory Access, Write-Back)
    // ==========================================================
    wire [3:0] rd_value;
    wire [3:0] rs_value;
    wire [3:0] alu_b;
    wire [3:0] alu_result;
    wire       alu_zero, alu_carry;
    wire [3:0] mem_data;
    wire [3:0] wb_data;

    // Dual-port Register File
    register_file RF (
        .clk (clk),
        .rst (rst),
        .ra  (ex_rd),      // Port A reads Rd
        .rb  (ex_rs),      // Port B reads Rs
        .wa  (ex_rd),      // Destination write address is Rd
        .wd  (wb_data),    // Result data from write-back MUX
        .we  (ex_reg_we),  // Write enable
        .qa  (rd_value),
        .qb  (rs_value)
    );

    // Operand B Multiplexer (picks Rs value or Immediate constant)
    mux2 OPERAND_MUX (
        .d0  (rs_value),
        .d1  (ex_imm),
        .sel (ex_alu_src_sel),
        .y   (alu_b)
    );

    // 4-bit Arithmetic Logic Unit
    alu ALU (
        .a        (rd_value),
        .b        (alu_b),
        .alu_ctrl (ex_alu_ctrl),
        .result   (alu_result),
        .carry    (alu_carry),
        .zero     (alu_zero)
    );

    // Flag Register for condition tracking
    flag_register FLAGS (
        .clk        (clk),
        .rst        (rst),
        .zero_we    (ex_zero_we),
        .carry_we   (ex_carry_we),
        .zero_in    (alu_zero),
        .carry_in   (alu_carry),
        .zero_flag  (zero_flag),
        .carry_flag (carry_flag)
    );

    // Data RAM for LOAD / STORE
    data_memory DMEM (
        .clk        (clk),
        .address    (alu_result), // Memory address passed via ALU PASS
        .write_data (rd_value),   // Data from register Rd
        .mem_we     (ex_mem_we),
        .read_data  (mem_data)
    );

    // Write-back Multiplexer (selects ALU output or Data Memory read value)
    mux2 WB_MUX (
        .d0  (alu_result),
        .d1  (mem_data),
        .sel (ex_wb_sel),
        .y   (wb_data)
    );

    // ----------------------------------------------------------
    // Output Port Assignments
    // ----------------------------------------------------------
    assign pc_out      = pc;
    assign instr_out   = ex_instr;
    assign alu_out     = alu_result;
    assign wb_data_out = wb_data;
    assign zero_out    = zero_flag;
    assign carry_out   = carry_flag;

endmodule