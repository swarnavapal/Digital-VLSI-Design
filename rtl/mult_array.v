module mult_array (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [7:0] p
);
    reg  [3:0] a_reg;
    reg  [3:0] b_reg;

    wire [3:0] pp0, pp1, pp2, pp3;
    wire [3:0] r0, r1, r2;
    wire [3:0] s1, s2, s3;
    wire [4:0] c1, c2, c3;
    wire [7:0] product_comb;
    genvar j;

    // Partial-product rows: pp_i[j] = a_reg[j] AND b_reg[i].
    assign pp0 = a_reg & {4{b_reg[0]}};
    assign pp1 = a_reg & {4{b_reg[1]}};
    assign pp2 = a_reg & {4{b_reg[2]}};
    assign pp3 = a_reg & {4{b_reg[3]}};

    // Row 0 
    assign r0 = {1'b0, pp0[3], pp0[2], pp0[1]};

    // Row 1: pp1 + r0
    assign c1[0] = 1'b0;
    generate
        for (j = 0; j < 4; j = j + 1) begin : gen_row1
            full_adder fa (
                .a(pp1[j]), .b(r0[j]), .cin(c1[j]),
                .sum(s1[j]), .cout(c1[j+1])
            );
        end
    endgenerate
    assign r1 = {c1[4], s1[3], s1[2], s1[1]};

    // Row 2: pp2 + r1.
    assign c2[0] = 1'b0;
    generate
        for (j = 0; j < 4; j = j + 1) begin : gen_row2
            full_adder fa (
                .a(pp2[j]), .b(r1[j]), .cin(c2[j]),
                .sum(s2[j]), .cout(c2[j+1])
            );
        end
    endgenerate
    assign r2 = {c2[4], s2[3], s2[2], s2[1]};

    // Row 3: pp3 + r2. 
    assign c3[0] = 1'b0;
    generate
        for (j = 0; j < 4; j = j + 1) begin : gen_row3
            full_adder fa (
                .a(pp3[j]), .b(r2[j]), .cin(c3[j]),
                .sum(s3[j]), .cout(c3[j+1])
            );
        end
    endgenerate

    // p[0] comes from row 0; p[1:3] are the low sums of rows 1:3.
    // The remaining row-3 bits form p[7:4].
    assign product_comb = {c3[4], s3[3:1], s3[0], s2[0], s1[0], pp0[0]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0000;
            b_reg <= 4'b0000;
            p     <= 8'b00000000;
        end else begin
            a_reg <= a;
            b_reg <= b;
            p     <= product_comb;
        end
    end
endmodule

