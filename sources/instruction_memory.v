// ==============================================================
// MODULE: instruction_memory.v
// Description: 16-word x 12-bit Instruction Memory ROM
// ==============================================================
module instruction_memory #(
    parameter PROGRAM_FILE = "program.mem" // Hex file containing the target machine code
)(
    input  [3:0]  address,    // Instruction address input from PC
    output [11:0] instruction // 12-bit instruction word output
);

    // 16-word memory array (identifier 'mem' preserved for testbench $readmemh override)
    reg [11:0] mem [0:15];
    integer idx;

    initial begin
        // Preset all memory locations with NOP instructions (reserved opcode C00)
        for (idx = 0; idx < 16; idx = idx + 1)
            mem[idx] = 12'hC00;

        // Load machine code from file
        $readmemh(PROGRAM_FILE, mem);
    end

    // Combinational instruction lookup
    assign instruction = mem[address];

endmodule