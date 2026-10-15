// ==============================================================
// MODULE: alu.v
// Description: 4-bit Arithmetic Logic Unit (ALU)
// ==============================================================
module alu (
    input  [3:0] a,          // Operand A (from register Rd)
    input  [3:0] b,          // Operand B (from register Rs or Immediate)
    input  [2:0] alu_ctrl,   // ALU operation control code
    output reg [3:0] result, // 4-bit ALU result
    output reg carry,        // Carry / No-borrow flag
    output zero              // Zero flag (asserted when result is 0000)
);

    // Combinational evaluation of arithmetic and logic operations
    always @(*) begin
        case (alu_ctrl)
            3'd0: begin // ADD: 4-bit addition with carry-out
                {carry, result} = {1'b0, a} + {1'b0, b};
            end
            3'd1: begin // SUB: 4-bit subtraction; carry = 1 indicates no-borrow (a >= b)
                result = a - b;
                carry  = (a >= b) ? 1'b1 : 1'b0;
            end
            3'd2: begin // Bitwise AND
                result = a & b;
                carry  = 1'b0;
            end
            3'd3: begin // Bitwise OR
                result = a | b;
                carry  = 1'b0;
            end
            3'd4: begin // Bitwise XOR
                result = a ^ b;
                carry  = 1'b0;
            end
            3'd5: begin // Bitwise NOT (operates on operand A only)
                result = ~a;
                carry  = 1'b0;
            end
            3'd6: begin // PASS: direct transfer of operand B
                result = b;
                carry  = 1'b0;
            end
            default: begin
                result = 4'b0000;
                carry  = 1'b0;
            end
        endcase
    end

    // Zero flag detection using unary reduction NOR operator
    assign zero = ~|result;

endmodule