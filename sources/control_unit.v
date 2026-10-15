// ==============================================================
// MODULE: control_unit.v
// Description: Hardwired control unit with Decoder (ID) and Branch Unit (EX)
// ==============================================================

// SUBMODULE 1: Instruction Decoder (Combinational logic in ID stage)
module instruction_decoder (
    input      [3:0] opcode,      // Instruction opcode [11:8]
    output reg [2:0] alu_ctrl,    // ALU function selector
    output reg       alu_src_sel, // Operand B MUX: 0 = Rs, 1 = immediate
    output reg       wb_sel,      // Write-back MUX: 0 = ALU, 1 = Memory
    output reg       reg_we,      // Register file write enable
    output reg       mem_we,      // Data RAM write enable
    output reg       zero_we,     // Zero flag write enable
    output reg       carry_we,    // Carry flag write enable
    output reg       is_jmp,      // Unconditional jump indicator
    output reg       is_jz        // Conditional jump indicator
);

    // Opcode definitions
    localparam ADD   = 4'b0000;
    localparam SUB   = 4'b0001;
    localparam AND   = 4'b0010;
    localparam OR    = 4'b0011;
    localparam XOR   = 4'b0100;
    localparam NOT   = 4'b0101;
    localparam LDI   = 4'b0110;
    localparam MOV   = 4'b0111;
    localparam LOAD  = 4'b1000;
    localparam STORE = 4'b1001;
    localparam JMP   = 4'b1010;
    localparam JZ    = 4'b1011;

    // ALU control codes (must match alu.v)
    localparam ALU_ADD  = 3'd0;
    localparam ALU_SUB  = 3'd1;
    localparam ALU_AND  = 3'd2;
    localparam ALU_OR   = 3'd3;
    localparam ALU_XOR  = 3'd4;
    localparam ALU_NOT  = 3'd5;
    localparam ALU_PASS = 3'd6;

    always @(*) begin
        // Safe default assignments (NOP behaviour)
        alu_ctrl    = ALU_ADD;
        alu_src_sel = 1'b0;
        wb_sel      = 1'b0;
        reg_we      = 1'b0;
        mem_we      = 1'b0;
        zero_we     = 1'b0;
        carry_we    = 1'b0;
        is_jmp      = 1'b0;
        is_jz       = 1'b0;

        case (opcode)
            ADD: begin
                alu_ctrl = ALU_ADD;
                reg_we   = 1'b1;
                zero_we  = 1'b1;
                carry_we = 1'b1;
            end
            SUB: begin
                alu_ctrl = ALU_SUB;
                reg_we   = 1'b1;
                zero_we  = 1'b1;
                carry_we = 1'b1;
            end
            AND: begin
                alu_ctrl = ALU_AND;
                reg_we   = 1'b1;
                zero_we  = 1'b1;
            end
            OR: begin
                alu_ctrl = ALU_OR;
                reg_we   = 1'b1;
                zero_we  = 1'b1;
            end
            XOR: begin
                alu_ctrl = ALU_XOR;
                reg_we   = 1'b1;
                zero_we  = 1'b1;
            end
            NOT: begin
                alu_ctrl = ALU_NOT;
                reg_we   = 1'b1;
                zero_we  = 1'b1;
            end
            LDI: begin
                alu_ctrl    = ALU_PASS;
                alu_src_sel = 1'b1;
                reg_we      = 1'b1;
            end
            MOV: begin
                alu_ctrl = ALU_PASS;
                reg_we   = 1'b1;
            end
            LOAD: begin
                alu_ctrl    = ALU_PASS;
                alu_src_sel = 1'b1;
                wb_sel      = 1'b1;
                reg_we      = 1'b1;
            end
            STORE: begin
                alu_ctrl    = ALU_PASS;
                alu_src_sel = 1'b1;
                mem_we      = 1'b1;
            end
            JMP: begin
                is_jmp = 1'b1;
            end
            JZ: begin
                is_jz = 1'b1;
            end
            default: begin
                // Reserved opcodes (1100-1111) retain default values (NOP)
            end
        endcase
    end

endmodule

// SUBMODULE 2: Branch Unit (Combinational logic in EX stage)
module branch_unit (
    input      is_jmp,    // Instruction in EX is JMP
    input      is_jz,     // Instruction in EX is JZ
    input      zero_flag, // Registered Zero flag from Flag Register
    output reg pc_sel,    // PC MUX select: 0 = PC+1, 1 = Jump target
    output     flush      // Flush pipeline registers on taken jump
);

    always @(*) begin
        if (is_jmp)
            pc_sel = 1'b1;
        else if (is_jz && zero_flag)
            pc_sel = 1'b1;
        else
            pc_sel = 1'b0;
    end

    // Whenever branch is taken, flush the two preceding pipeline stages
    assign flush = pc_sel;

endmodule

// SUBMODULE 3: Top Control Unit combining Decoder and Branch Unit
module control_unit (
    // Decode stage interface (ID)
    input  [3:0] opcode,
    output [2:0] alu_ctrl,
    output       alu_src_sel,
    output       wb_sel,
    output       reg_we,
    output       mem_we,
    output       zero_we,
    output       carry_we,
    output       is_jmp,
    output       is_jz,

    // Execute stage interface (EX)
    input        ex_is_jmp,
    input        ex_is_jz,
    input        zero_flag,
    output       pc_sel,
    output       flush
);

    instruction_decoder DECODER (
        .opcode      (opcode),
        .alu_ctrl    (alu_ctrl),
        .alu_src_sel (alu_src_sel),
        .wb_sel      (wb_sel),
        .reg_we      (reg_we),
        .mem_we      (mem_we),
        .zero_we     (zero_we),
        .carry_we    (carry_we),
        .is_jmp      (is_jmp),
        .is_jz       (is_jz)
    );

    branch_unit BRANCH (
        .is_jmp      (ex_is_jmp),
        .is_jz       (ex_is_jz),
        .zero_flag   (zero_flag),
        .pc_sel      (pc_sel),
        .flush       (flush)
    );

endmodule