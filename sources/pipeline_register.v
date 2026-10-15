// ==============================================================
// MODULE: pipeline_register.v
// Description: ID/EX Pipeline Register between Decode and Execute stages
// ==============================================================
module pipeline_register (
    input             clk,             // System clock
    input             rst,             // Synchronous reset
    input             flush,           // Pipeline flush signal

    // Control and field inputs from Decode stage (ID)
    input      [2:0]  alu_ctrl_in,
    input             alu_src_sel_in,
    input             wb_sel_in,
    input             reg_we_in,
    input             mem_we_in,
    input             zero_we_in,
    input             carry_we_in,
    input             is_jmp_in,
    input             is_jz_in,
    input      [1:0]  rd_in,
    input      [1:0]  rs_in,
    input      [3:0]  imm_in,
    input      [3:0]  pc_in,
    input             valid_in,
    input      [11:0] instr_in,

    // Outputs to Execute stage (EX)
    output reg [2:0]  alu_ctrl,
    output reg        alu_src_sel,
    output reg        wb_sel,
    output reg        reg_we,
    output reg        mem_we,
    output reg        zero_we,
    output reg        carry_we,
    output reg        is_jmp,
    output reg        is_jz,
    output reg [1:0]  rd,
    output reg [1:0]  rs,
    output reg [3:0]  imm,
    output reg [3:0]  pc,
    output reg        valid,
    output reg [11:0] instr
);

    always @(posedge clk) begin
        if (rst || flush) begin
            // Bubble state: clear all write enables to prevent side effects
            alu_ctrl    <= 3'd0;
            alu_src_sel <= 1'b0;
            wb_sel      <= 1'b0;
            reg_we      <= 1'b0;
            mem_we      <= 1'b0;
            zero_we     <= 1'b0;
            carry_we    <= 1'b0;
            is_jmp      <= 1'b0;
            is_jz       <= 1'b0;
            rd          <= 2'd0;
            rs          <= 2'd0;
            imm         <= 4'd0;
            pc          <= 4'd0;
            valid       <= 1'b0;
            instr       <= 12'hC00;
        end else begin
            // Propagate decoded instruction and controls to Execute stage
            alu_ctrl    <= alu_ctrl_in;
            alu_src_sel <= alu_src_sel_in;
            wb_sel      <= wb_sel_in;
            reg_we      <= reg_we_in;
            mem_we      <= mem_we_in;
            zero_we     <= zero_we_in;
            carry_we    <= carry_we_in;
            is_jmp      <= is_jmp_in;
            is_jz       <= is_jz_in;
            rd          <= rd_in;
            rs          <= rs_in;
            imm         <= imm_in;
            pc          <= pc_in;
            valid       <= valid_in;
            instr       <= instr_in;
        end
    end

endmodule