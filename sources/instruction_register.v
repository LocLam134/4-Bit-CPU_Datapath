// ==============================================================
// MODULE: instruction_register.v
// Description: IF/ID Pipeline Register between Fetch and Decode stages
// ==============================================================
module instruction_register (
    input             clk,             // System clock
    input             rst,             // Synchronous reset
    input             ir_load,         // Load enable (held at 1'b1)
    input             flush,           // Pipeline flush signal (from Branch Unit)
    input      [3:0]  pc_in,           // Program counter of the fetched instruction
    input      [11:0] instruction_in,  // Fetched 12-bit instruction word
    output reg [11:0] instruction_out, // Latched instruction for Decode stage
    output reg [3:0]  pc_out,          // Latched instruction address
    output reg        valid_out        // Valid instruction indicator (0 = bubble)
);

    always @(posedge clk) begin
        if (rst || flush) begin
            // Insert NOP (reserved opcode C00) and invalidate slot
            instruction_out <= 12'hC00;
            pc_out          <= 4'd0;
            valid_out       <= 1'b0;
        end else if (ir_load) begin
            instruction_out <= instruction_in;
            pc_out          <= pc_in;
            valid_out       <= 1'b1;
        end
    end

endmodule