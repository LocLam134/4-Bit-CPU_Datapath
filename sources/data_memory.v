// ==============================================================
// MODULE: data_memory.v
// Description: 16-word x 4-bit Data RAM for LOAD and STORE operations
// ==============================================================
module data_memory (
    input        clk,        // System clock
    input  [3:0] address,    // Data RAM address (from ALU result)
    input  [3:0] write_data, // Data to write (from register Rd)
    input        mem_we,     // Memory write enable
    output [3:0] read_data   // Read data output (for LOAD operation)
);

    // 16-word x 4-bit RAM storage array
    reg [3:0] mem [0:15];
    integer k;

    // Clear RAM to zero during initialization to prevent unknown (X) states
    initial begin
        for (k = 0; k < 16; k = k + 1)
            mem[k] = 4'b0000;
    end

    // Synchronous memory write on rising clock edge
    always @(posedge clk) begin
        if (mem_we)
            mem[address] <= write_data;
    end

    // Asynchronous / combinational memory read
    assign read_data = mem[address];

endmodule