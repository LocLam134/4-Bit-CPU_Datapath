// ==============================================================
// MODULE: program_counter.v
// Description: 4-bit Program Counter (PC)
// ==============================================================
module program_counter (
    input            clk,     // System clock
    input            rst,     // Synchronous reset
    input            pc_en,   // Program counter update enable
    input      [3:0] pc_next, // Next program counter value (PC+1 or Jump target)
    output reg [3:0] pc_out   // Current instruction fetch address
);

    always @(posedge clk) begin
        if (rst)
            pc_out <= 4'b0000;
        else if (pc_en)
            pc_out <= pc_next;
    end

endmodule