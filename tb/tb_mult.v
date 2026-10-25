`timescale 1ns/1ps

module tb_mult;
    reg        clk;
    reg        rst_n;
    reg  [3:0] a;
    reg  [3:0] b;
    wire [7:0] p;

    integer ai, bi;
    integer errors;
    integer checked;
    integer expected;

    mult_array dut (
        .clk(clk), .rst_n(rst_n), .a(a), .b(b), .p(p)
    );

    // 10 ns clock period.
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        rst_n  = 1'b0;
        a      = 4'd0;
        b      = 4'd0;
        errors = 0;
        checked = 0;

        // Hold asynchronous reset low for the first two rising clock edges.
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;


        for (ai = 0; ai < 16; ai = ai + 1) begin
            for (bi = 0; bi < 16; bi = bi + 1) begin
                @(negedge clk);
                a = ai[3:0];
                b = bi[3:0];
                expected = ai * bi; 

                @(posedge clk); // operand registers capture a and b
                @(posedge clk); // output register captures their product
                #3;
                checked = checked + 1;

                if (p !== expected[7:0]) begin
                    errors = errors + 1;
                    $display("MISMATCH: a=%0d b=%0d expected=%0d (0x%02h) got=%0d (0x%02h)",
                             ai, bi, expected, expected[7:0], p, p);
                end
            end
        end

        if (errors == 0)
            $display("PASS: 256 vectors checked, 0 errors");
        else
            $display("FAIL: 256 vectors checked, %0d errors", errors);

        $finish;
    end
endmodule

