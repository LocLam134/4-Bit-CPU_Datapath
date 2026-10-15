// ==============================================================
// MODULE: flag_register.v
// Description: Stores Zero and Carry condition flags in EX stage
// ==============================================================
module flag_register (
    input      clk,        // System clock
    input      rst,        // Synchronous reset
    input      zero_we,    // Write enable for Zero flag
    input      carry_we,   // Write enable for Carry flag
    input      zero_in,    // Zero flag input from ALU
    input      carry_in,   // Carry flag input from ALU
    output reg zero_flag,  // Registered Zero flag output
    output reg carry_flag  // Registered Carry flag output
);

    always @(posedge clk) begin
        if (rst) begin
            zero_flag  <= 1'b0;
            carry_flag <= 1'b0;
        end else begin
            if (zero_we)  zero_flag  <= zero_in;
            if (carry_we) carry_flag <= carry_in;
        end
    end

endmodule