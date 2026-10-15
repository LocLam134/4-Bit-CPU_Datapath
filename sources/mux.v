// ==============================================================
// MODULE: mux.v (mux2)
// Description: 2-to-1 4-bit Multiplexer
// ==============================================================
module mux2 (
    input  [3:0] d0,  // Data input 0 (selected when sel = 0)
    input  [3:0] d1,  // Data input 1 (selected when sel = 1)
    input        sel, // Multiplexer select line
    output [3:0] y    // Data output
);

    assign y = sel ? d1 : d0;

endmodule