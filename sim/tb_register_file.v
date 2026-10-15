`timescale 1ns / 1ps

// ==============================================================
// TESTBENCH: tb_register_file.v
// Module-level verification for Register File (R0-R3)
// ==============================================================
module tb_register_file;
    reg clk = 0;
    reg rst = 1;
    reg [1:0] ra = 0, rb = 0, wa = 0;
    reg [3:0] wd = 0;
    reg we = 0;
    wire [3:0] qa, qb;
    integer errors = 0;
    integer tests  = 0;

    always #5 clk = ~clk;

    // Instantiate Register File
    register_file DUT (
        .clk(clk),
        .rst(rst),
        .ra(ra),
        .rb(rb),
        .wa(wa),
        .wd(wd),
        .we(we),
        .qa(qa),
        .qb(qb)
    );

    // Verify 4-bit output
    task check;
        input [8*26:1] name;
        input [3:0]    actual;
        input [3:0]    expected;
        begin
            tests = tests + 1;
            if (actual == expected)
                $display("PASS %0s = %b", name, actual);
            else begin
                $display("FAIL %0s = %b (expected %b)", name, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    // Synchronous write task
    task write_reg;
        input [1:0] addr;
        input [3:0] data;
        begin
            wa = addr; wd = data; we = 1;
            @(posedge clk);
            #1;
            we = 0;
        end
    endtask

    initial begin
        $display("\n=======================================================");
        $display("   Student name: Lam Duy Loc");
        $display("   Student ID:   SE190907");
        $display("=======================================================\n");

        $display("\n===== tb_register_file: register file test =====");
        // 1. Reset check
        @(posedge clk); #1;
        rst = 0;
        ra = 0; rb = 3; #1;
        check("after reset R0 (port A)", qa, 4'b0000);
        check("after reset R3 (port B)", qb, 4'b0000);

        // 2. Write unique values into R0-R3
        write_reg(2'd0, 4'b0001);
        write_reg(2'd1, 4'b0101);
        write_reg(2'd2, 4'b1010);
        write_reg(2'd3, 4'b1111);

        // 3. Dual-port read verification
        ra = 0; rb = 1; #1;
        check("R0 on port A", qa, 4'b0001);
        check("R1 on port B", qb, 4'b0101);
        ra = 2; rb = 3; #1;
        check("R2 on port A", qa, 4'b1010);
        check("R3 on port B", qb, 4'b1111);
        ra = 1; rb = 1; #1;
        check("R1 on both ports (A)", qa, 4'b0101);
        check("R1 on both ports (B)", qb, 4'b0101);

        // 4. we = 0 must block writing
        wa = 2; wd = 4'b0000; we = 0;
        @(posedge clk); #1;
        ra = 2; #1;
        check("R2 unchanged when we = 0", qa, 4'b1010);

        // 5. Secondary reset verification
        rst = 1; @(posedge clk); #1; rst = 0;
        ra = 3; rb = 2; #1;
        check("R3 after second reset", qa, 4'b0000);
        check("R2 after second reset", qb, 4'b0000);

        if (errors == 0)
            $display("tb_register_file PASSED: %0d of %0d checks OK\n", tests, tests);
        else
            $display("tb_register_file FAILED: %0d of %0d checks failed\n", errors, tests);
        $finish;
    end
endmodule