`timescale 1ns / 1ps

// ==============================================================
// MASTER REGRESSION TESTBENCH: tb_regression_88.v
// Complete 88/88 Verification Suite (ALU, RF, CU, CPU Integration)
// Student name: Lam Duy Loc
// Student ID:   SE190907
// ==============================================================
module tb_regression_88;

    // ----------------------------------------------------------
    // Global Clock & Tracking Variables
    // ----------------------------------------------------------
    reg clk = 0;
    always #5 clk = ~clk; // 10 ns clock period

    integer total_tests  = 0;
    integer total_errors = 0;
    integer phase1_ok = 0, phase2_ok = 0, phase3_ok = 0, phase4_ok = 0;
    integer i, cycle = 0;

    // ----------------------------------------------------------
    // DUT 1: ALU (11 checks)
    // ----------------------------------------------------------
    reg  [3:0] alu_a, alu_b;
    reg  [2:0] alu_ctrl;
    wire [3:0] alu_res;
    wire       alu_c, alu_z;

    alu ALU_DUT (
        .a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl),
        .result(alu_res), .carry(alu_c), .zero(alu_z)
    );

    // ----------------------------------------------------------
    // DUT 2: Register File (11 checks)
    // ----------------------------------------------------------
    reg        rf_rst = 1;
    reg  [1:0] rf_ra = 0, rf_rb = 0, rf_wa = 0;
    reg  [3:0] rf_wd = 0;
    reg        rf_we = 0;
    wire [3:0] rf_qa, rf_qb;

    register_file RF_DUT (
        .clk(clk), .rst(rf_rst),
        .ra(rf_ra), .rb(rf_rb), .wa(rf_wa), .wd(rf_wd), .we(rf_we),
        .qa(rf_qa), .qb(rf_qb)
    );

    // ----------------------------------------------------------
    // DUT 3: Control Unit (22 checks)
    // ----------------------------------------------------------
    reg  [3:0] cu_op = 4'b0000;
    reg        cu_ex_jmp = 0, cu_ex_jz = 0, cu_zero_flag = 0;
    wire [2:0] cu_alu_ctrl;
    wire       cu_alu_src_sel, cu_wb_sel, cu_reg_we, cu_mem_we;
    wire       cu_zero_we, cu_carry_we, cu_is_jmp, cu_is_jz;
    wire       cu_pc_sel, cu_flush;

    control_unit CU_DUT (
        .opcode(cu_op), .alu_ctrl(cu_alu_ctrl), .alu_src_sel(cu_alu_src_sel),
        .wb_sel(cu_wb_sel), .reg_we(cu_reg_we), .mem_we(cu_mem_we),
        .zero_we(cu_zero_we), .carry_we(cu_carry_we), .is_jmp(cu_is_jmp), .is_jz(cu_is_jz),
        .ex_is_jmp(cu_ex_jmp), .ex_is_jz(cu_ex_jz), .zero_flag(cu_zero_flag),
        .pc_sel(cu_pc_sel), .flush(cu_flush)
    );

    wire [10:0] cu_signals = {cu_alu_ctrl, cu_alu_src_sel, cu_wb_sel, cu_reg_we, cu_mem_we,
                              cu_zero_we, cu_carry_we, cu_is_jmp, cu_is_jz};

    // ----------------------------------------------------------
    // DUT 4: 4-Bit RISC CPU Top Level (44 checks)
    // ----------------------------------------------------------
    reg         cpu_rst = 1;
    wire [3:0]  cpu_pc_out, cpu_alu_out, cpu_wb_data_out;
    wire [11:0] cpu_instr_out;
    wire        cpu_zero_out, cpu_carry_out;

    cpu_top #(.PROGRAM_FILE("program.mem")) CPU (
        .clk(clk), .rst(cpu_rst),
        .pc_out(cpu_pc_out), .instr_out(cpu_instr_out), .alu_out(cpu_alu_out),
        .wb_data_out(cpu_wb_data_out), .zero_out(cpu_zero_out), .carry_out(cpu_carry_out)
    );

    always @(posedge clk) begin
        if (cpu_rst) cycle <= 0;
        else         cycle <= cycle + 1;
    end

    // ----------------------------------------------------------
    // Verification Helper Tasks
    // ----------------------------------------------------------
    task test_alu;
        input [8*12:1] name;
        input [3:0] in_a, in_b;
        input [2:0] op;
        input [3:0] exp_r;
        input       exp_c, exp_z;
        begin
            alu_a = in_a; alu_b = in_b; alu_ctrl = op;
            #10;
            total_tests = total_tests + 1;
            if (alu_res == exp_r && alu_c == exp_c && alu_z == exp_z) begin
                $display("  PASS %0s a=%b b=%b -> result=%b C=%b Z=%b", name, alu_a, alu_b, alu_res, alu_c, alu_z);
                phase1_ok = phase1_ok + 1;
            end else begin
                $display("  FAIL %0s a=%b b=%b -> result=%b C=%b Z=%b (expected %b C=%b Z=%b)",
                         name, alu_a, alu_b, alu_res, alu_c, alu_z, exp_r, exp_c, exp_z);
                total_errors = total_errors + 1;
            end
        end
    endtask

    task check_rf;
        input [8*26:1] name;
        input [3:0] actual, expected;
        begin
            total_tests = total_tests + 1;
            if (actual == expected) begin
                $display("  PASS %0s = %b", name, actual);
                phase2_ok = phase2_ok + 1;
            end else begin
                $display("  FAIL %0s = %b (expected %b)", name, actual, expected);
                total_errors = total_errors + 1;
            end
        end
    endtask

    task write_rf;
        input [1:0] addr;
        input [3:0] data;
        begin
            rf_wa = addr; rf_wd = data; rf_we = 1;
            @(posedge clk); #1;
            rf_we = 0;
        end
    endtask

    task check_cu_op;
        input [8*6:1] name;
        input [3:0] op;
        input [10:0] exp_sig;
        begin
            cu_op = op; #1;
            total_tests = total_tests + 1;
            if (cu_signals == exp_sig) begin
                $display("  PASS %0s alu=%0d src=%b wb=%b rwe=%b mwe=%b zwe=%b cwe=%b jmp=%b jz=%b",
                         name, cu_alu_ctrl, cu_alu_src_sel, cu_wb_sel, cu_reg_we, cu_mem_we,
                         cu_zero_we, cu_carry_we, cu_is_jmp, cu_is_jz);
                phase3_ok = phase3_ok + 1;
            end else begin
                $display("  FAIL %0s got %b, expected %b", name, cu_signals, exp_sig);
                total_errors = total_errors + 1;
            end
        end
    endtask

    task check_cu_branch;
        input [8*24:1] name;
        input jmp, jz, z, exp_pc_sel;
        begin
            cu_ex_jmp = jmp; cu_ex_jz = jz; cu_zero_flag = z; #1;
            total_tests = total_tests + 1;
            if (cu_pc_sel == exp_pc_sel && cu_flush == exp_pc_sel) begin
                $display("  PASS %0s pc_sel=%b flush=%b", name, cu_pc_sel, cu_flush);
                phase3_ok = phase3_ok + 1;
            end else begin
                $display("  FAIL %0s pc_sel=%b flush=%b (expected %b)", name, cu_pc_sel, cu_flush, exp_pc_sel);
                total_errors = total_errors + 1;
            end
        end
    endtask

    task reset_cpu;
        begin
            cpu_rst = 1;
            @(posedge clk); @(posedge clk); #1;
            cpu_rst = 0;
        end
    endtask

    task load_cpu_prog;
        input [8*20:1] file_name;
        begin
            cpu_rst = 1;
            for (i = 0; i < 16; i = i + 1) begin
                CPU.IMEM.mem[i] = 12'hC00;
                CPU.DMEM.mem[i] = 4'b0000;
            end
            $readmemh(file_name, CPU.IMEM.mem);
        end
    endtask

    task finish_cpu;
        input [3:0] addr;
        begin
            @(negedge clk);
            while (!(CPU.ex_valid && CPU.ex_pc == addr))
                @(negedge clk);
            @(posedge clk); #1;
        end
    endtask

    task check_cpu_4b;
        input [8*44:1] name;
        input [3:0] actual, expected;
        begin
            total_tests = total_tests + 1;
            if (actual === expected) begin
                $display("  PASS %0s = %b", name, actual);
                phase4_ok = phase4_ok + 1;
            end else begin
                $display("  FAIL %0s = %b (expected %b)", name, actual, expected);
                total_errors = total_errors + 1;
            end
        end
    endtask

    task check_cpu_1b;
        input [8*44:1] name;
        input actual, expected;
        begin
            total_tests = total_tests + 1;
            if (actual === expected) begin
                $display("  PASS %0s = %b", name, actual);
                phase4_ok = phase4_ok + 1;
            end else begin
                $display("  FAIL %0s = %b (expected %b)", name, actual, expected);
                total_errors = total_errors + 1;
            end
        end
    endtask

    // ----------------------------------------------------------
    // MAIN REGRESSION EXECUTION
    // ----------------------------------------------------------
    initial begin
        $display("\n=======================================================");
        $display("   Student name: Lam Duy Loc");
        $display("   Student ID:   SE190907");
        $display("=======================================================\n");

        // ------------------------------------------------------
        // PHASE 1: ALU Verification (11 Checks)
        // ------------------------------------------------------
        $display(">>> PHASE 1: Testing 4-bit ALU (alu.v) - 11 Tests <<<");
        test_alu("ADD 5+3      ", 4'b0101, 4'b0011, 3'd0, 4'b1000, 0, 0);
        test_alu("ADD 15+1     ", 4'b1111, 4'b0001, 3'd0, 4'b0000, 1, 1);
        test_alu("SUB 5-3      ", 4'b0101, 4'b0011, 3'd1, 4'b0010, 1, 0);
        test_alu("SUB 3-5      ", 4'b0011, 4'b0101, 3'd1, 4'b1110, 0, 0);
        test_alu("SUB 7-7      ", 4'b0111, 4'b0111, 3'd1, 4'b0000, 1, 1);
        test_alu("AND          ", 4'b1100, 4'b1010, 3'd2, 4'b1000, 0, 0);
        test_alu("OR           ", 4'b1100, 4'b1010, 3'd3, 4'b1110, 0, 0);
        test_alu("XOR          ", 4'b1100, 4'b1010, 3'd4, 4'b0110, 0, 0);
        test_alu("XOR to zero  ", 4'b0110, 4'b0110, 3'd4, 4'b0000, 0, 1);
        test_alu("NOT 0101     ", 4'b0101, 4'b0000, 3'd5, 4'b1010, 0, 0);
        test_alu("PASS b       ", 4'b0000, 4'b1001, 3'd6, 4'b1001, 0, 0);

        // ------------------------------------------------------
        // PHASE 2: Register File Verification (11 Checks)
        // ------------------------------------------------------
        $display("\n>>> PHASE 2: Testing Register File (register_file.v) - 11 Tests <<<");
        @(posedge clk); #1;
        rf_rst = 0; rf_ra = 0; rf_rb = 3; #1;
        check_rf("after reset R0 (port A)", rf_qa, 4'b0000);
        check_rf("after reset R3 (port B)", rf_qb, 4'b0000);

        write_rf(2'd0, 4'b0001);
        write_rf(2'd1, 4'b0101);
        write_rf(2'd2, 4'b1010);
        write_rf(2'd3, 4'b1111);

        rf_ra = 0; rf_rb = 1; #1;
        check_rf("R0 on port A", rf_qa, 4'b0001);
        check_rf("R1 on port B", rf_qb, 4'b0101);
        rf_ra = 2; rf_rb = 3; #1;
        check_rf("R2 on port A", rf_qa, 4'b1010);
        check_rf("R3 on port B", rf_qb, 4'b1111);
        rf_ra = 1; rf_rb = 1; #1;
        check_rf("R1 on both ports (A)", rf_qa, 4'b0101);
        check_rf("R1 on both ports (B)", rf_qb, 4'b0101);

        rf_wa = 2; rf_wd = 4'b0000; rf_we = 0;
        @(posedge clk); #1;
        rf_ra = 2; #1;
        check_rf("R2 unchanged when we = 0", rf_qa, 4'b1010);

        rf_rst = 1; @(posedge clk); #1; rf_rst = 0;
        rf_ra = 3; rf_rb = 2; #1;
        check_rf("R3 after second reset", rf_qa, 4'b0000);
        check_rf("R2 after second reset", rf_qb, 4'b0000);

        // ------------------------------------------------------
        // PHASE 3: Control Unit Verification (22 Checks)
        // ------------------------------------------------------
        $display("\n>>> PHASE 3: Testing Control Unit (control_unit.v) - 22 Tests <<<");
        check_cu_op("ADD   ", 4'b0000, {3'd0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0});
        check_cu_op("SUB   ", 4'b0001, {3'd1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0});
        check_cu_op("AND   ", 4'b0010, {3'd2, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0});
        check_cu_op("OR    ", 4'b0011, {3'd3, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0});
        check_cu_op("XOR   ", 4'b0100, {3'd4, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0});
        check_cu_op("NOT   ", 4'b0101, {3'd5, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0});
        check_cu_op("LDI   ", 4'b0110, {3'd6, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0});
        check_cu_op("MOV   ", 4'b0111, {3'd6, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0});
        check_cu_op("LOAD  ", 4'b1000, {3'd6, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0});
        check_cu_op("STORE ", 4'b1001, {3'd6, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0});
        check_cu_op("JMP   ", 4'b1010, {3'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0});
        check_cu_op("JZ    ", 4'b1011, {3'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1});
        check_cu_op("RES-C ", 4'b1100, {3'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0});
        check_cu_op("RES-D ", 4'b1101, {3'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0});
        check_cu_op("RES-E ", 4'b1110, {3'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0});
        check_cu_op("RES-F ", 4'b1111, {3'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0});

        check_cu_branch("no jump instruction     ", 0, 0, 0, 0);
        check_cu_branch("no jump, Zero = 1       ", 0, 0, 1, 0);
        check_cu_branch("JMP                     ", 1, 0, 0, 1);
        check_cu_branch("JMP (Zero = 1)          ", 1, 0, 1, 1);
        check_cu_branch("JZ with Zero = 0        ", 0, 1, 0, 0);
        check_cu_branch("JZ with Zero = 1        ", 0, 1, 1, 1);

        // ------------------------------------------------------
        // PHASE 4: CPU Integration & Programs (44 Checks)
        // ------------------------------------------------------
        $display("\n>>> PHASE 4: Testing CPU Top Level (cpu_top.v) - 44 Tests <<<");

        // Test 1: Demonstration program (6 checks)
        reset_cpu;
        finish_cpu(2);
        check_cpu_4b("ADD R1,R2 -> R1 (5+3)", CPU.RF.r1, 4'b1000);
        finish_cpu(4);
        check_cpu_4b("LDI R3,1010 -> R3", CPU.RF.r3, 4'b1010);
        check_cpu_4b("XOR R1,R3 -> R1", CPU.RF.r1, 4'b0010);
        check_cpu_4b("R2 still 0011", CPU.RF.r2, 4'b0011);
        finish_cpu(5);
        check_cpu_4b("JMP 0101: PC = 5", cpu_pc_out, 4'd5);
        finish_cpu(5);
        check_cpu_4b("JMP loops at 5", cpu_pc_out, 4'd5);

        // Test 2: Arithmetic and memory (10 checks)
        load_cpu_prog("prog_arith.mem");
        reset_cpu;
        finish_cpu(2);
        check_cpu_4b("ADD R1,R2 -> R1", CPU.RF.r1, 4'b1000);
        check_cpu_1b("ADD: Carry", cpu_carry_out, 1'b0);
        check_cpu_1b("ADD: Zero", cpu_zero_out, 1'b0);
        finish_cpu(3);
        check_cpu_4b("STORE R1,0 -> mem[0]", CPU.DMEM.mem[0], 4'b1000);
        finish_cpu(5);
        check_cpu_4b("SUB R1,R2 -> R1", CPU.RF.r1, 4'b0010);
        check_cpu_1b("SUB: Zero", cpu_zero_out, 1'b0);
        check_cpu_1b("SUB: Carry (no borrow)", cpu_carry_out, 1'b1);
        finish_cpu(6);
        check_cpu_4b("STORE R1,1 -> mem[1]", CPU.DMEM.mem[1], 4'b0010);
        finish_cpu(7);
        check_cpu_4b("LOAD R0,0 -> R0", CPU.RF.r0, 4'b1000);
        finish_cpu(8);
        check_cpu_4b("SUB R2,R2 -> R2", CPU.RF.r2, 4'b0000);
        check_cpu_1b("Zero flag after 0000", cpu_zero_out, 1'b1);

        // Test 3: Logic operations (8 checks)
        load_cpu_prog("prog_logic.mem");
        reset_cpu;
        finish_cpu(3);
        check_cpu_4b("AND 1100, 1010 -> R3", CPU.RF.r3, 4'b1000);
        finish_cpu(5);
        check_cpu_4b("OR 1100, 1010 -> R3", CPU.RF.r3, 4'b1110);
        finish_cpu(6);
        check_cpu_4b("XOR 1100, 1010 -> R1", CPU.RF.r1, 4'b0110);
        finish_cpu(7);
        check_cpu_4b("MOV R2,R1 -> R2", CPU.RF.r2, 4'b0110);
        finish_cpu(9);
        check_cpu_4b("NOT 0101 -> R0", CPU.RF.r0, 4'b1010);
        finish_cpu(10);
        check_cpu_4b("LDI R3,1010 -> R3", CPU.RF.r3, 4'b1010);
        finish_cpu(11);
        check_cpu_4b("XOR R3,R3 -> R3", CPU.RF.r3, 4'b0000);
        check_cpu_1b("Zero flag after XOR 0000", cpu_zero_out, 1'b1);

        // Test 4: PC and jumps (11 checks)
        load_cpu_prog("prog_jump.mem");
        cpu_rst = 1;
        @(posedge clk); @(posedge clk); #1;
        cpu_rst = 0;
        check_cpu_4b("PC after reset", cpu_pc_out, 4'd0);
        @(posedge clk); #1;
        check_cpu_4b("PC increment (0 -> 1)", cpu_pc_out, 4'd1);
        finish_cpu(1);
        check_cpu_4b("JMP 4: PC becomes 0100", cpu_pc_out, 4'b0100);
        check_cpu_1b("JMP flushed ID/EX", CPU.ex_valid, 1'b0);
        finish_cpu(5);
        check_cpu_1b("SUB R1, R1 sets Zero", cpu_zero_out, 1'b1);
        finish_cpu(6);
        check_cpu_4b("JZ 9 taken: PC = 9", cpu_pc_out, 4'd9);
        finish_cpu(10);
        check_cpu_1b("ADD R3,R3 clears Zero", cpu_zero_out, 1'b0);
        finish_cpu(11);
        check_cpu_4b("JZ 14 not taken: next is addr 12", CPU.ex_pc, 4'd12);
        finish_cpu(13);
        check_cpu_4b("R0 = 1 (JMP skipped 2, 3)", CPU.RF.r0, 4'd1);
        check_cpu_4b("R2 = 6 (JZ skipped 7, 8)", CPU.RF.r2, 4'd6);
        check_cpu_4b("Program stops at PC = 13", cpu_pc_out, 4'd13);

        // Test 5: Reset and unknown values (9 checks)
        cpu_rst = 1;
        @(posedge clk); #1;
        check_cpu_4b("PC after reset", cpu_pc_out, 4'd0);
        check_cpu_4b("R0 after reset", CPU.RF.r0, 4'd0);
        check_cpu_4b("R2 after reset", CPU.RF.r2, 4'd0);
        check_cpu_1b("Zero after reset", cpu_zero_out, 1'b0);
        check_cpu_1b("Carry after reset", cpu_carry_out, 1'b0);
        check_cpu_1b("IF/ID empty after reset", CPU.id_valid, 1'b0);
        check_cpu_1b("ID/EX empty after reset", CPU.ex_valid, 1'b0);
        cpu_rst = 0;
        repeat (6) @(posedge clk);
        #1;

        total_tests = total_tests + 1;
        if ((^{cpu_pc_out, cpu_instr_out, cpu_alu_out, cpu_wb_data_out, cpu_zero_out, cpu_carry_out,
              CPU.RF.r0, CPU.RF.r1, CPU.RF.r2, CPU.RF.r3}) === 1'bx) begin
            $display("  FAIL unknown (X) value found on key outputs");
            total_errors = total_errors + 1;
        end else begin
            $display("  PASS no unknown (X) values on key outputs or registers");
            phase4_ok = phase4_ok + 1;
        end

        // ------------------------------------------------------
        // GRAND SUMMARY REPORT
        // ------------------------------------------------------
        $display("\n=======================================================");
        $display("                   GRAND SUMMARY REPORT                ");
        $display("=======================================================");
        $display(" Student name: Lam Duy Loc");
        $display(" Student ID:   SE190907");
        $display("-------------------------------------------------------");
        $display(" Phase 1: ALU Tests            : %2d / 11 checks PASSED", phase1_ok);
        $display(" Phase 2: Register File Tests  : %2d / 11 checks PASSED", phase2_ok);
        $display(" Phase 3: Control Unit Tests   : %2d / 22 checks PASSED", phase3_ok);
        $display(" Phase 4: CPU Top Level Tests  : %2d / 44 checks PASSED", phase4_ok);
        $display("-------------------------------------------------------");
        if (total_errors == 0)
            $display(" OVERALL VERDICT: PASSED (%0d of %0d checks OK)", total_tests, total_tests);
        else
            $display(" OVERALL VERDICT: FAILED (%0d errors encountered)", total_errors);
        $display("=======================================================\n");

        $finish;
    end

endmodule