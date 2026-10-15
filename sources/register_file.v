// ==============================================================
// MODULE: register_file.v
// Description: 4-word x 4-bit General-Purpose Register File (R0 - R3)
// ==============================================================
module register_file (
    input        clk, // System clock
    input        rst, // Synchronous active-high reset
    input  [1:0] ra,  // Read address port A
    input  [1:0] rb,  // Read address port B
    input  [1:0] wa,  // Write address port
    input  [3:0] wd,  // Write data input
    input        we,  // Write enable control
    output [3:0] qa,  // Read data output port A
    output [3:0] qb   // Read data output port B
);

    // Internal 4-bit storage registers (names preserved for hierarchical testbench access)
    reg [3:0] r0, r1, r2, r3;

    // Synchronous clocked write
    always @(posedge clk) begin
        if (rst) begin
            r0 <= 4'b0000;
            r1 <= 4'b0000;
            r2 <= 4'b0000;
            r3 <= 4'b0000;
        end else if (we) begin
            case (wa)
                2'd0: r0 <= wd;
                2'd1: r1 <= wd;
                2'd2: r2 <= wd;
                2'd3: r3 <= wd;
            endcase
        end
    end

    // Asynchronous / combinational dual-port read
    assign qa = (ra == 2'd0) ? r0 :
                (ra == 2'd1) ? r1 :
                (ra == 2'd2) ? r2 : r3;

    assign qb = (rb == 2'd0) ? r0 :
                (rb == 2'd1) ? r1 :
                (rb == 2'd2) ? r2 : r3;

endmodule