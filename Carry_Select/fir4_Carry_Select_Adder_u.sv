`timescale 1ns/1ps

module fir4_Carry_Select_Adder_u #(parameter w = 16)(
    input  logic                clk,
    input  logic                reset,
    input  logic signed [w-1:0] a,
    output logic signed [w+1:0] s
);

    // pipeline regs
    logic signed [w-1:0] ar, br, cr, dr;

    // intermediate (w+1)-bit partial sums and final (w+2)
    logic signed [w:0]   sum1;
    logic signed [w:0]   sum2;
    logic signed [w+1:0] sum_final;

    // ----------------------------
    // simple, robust combinational arithmetic
    // ----------------------------
    always_comb begin
        // compute partial sums directly (signed arithmetic)
        // These are combinational and driven entirely here (no partial-slice pitfalls)
        sum1      = $signed(ar) + $signed(br);    // (w bits) -> w+1 bits
        sum2      = $signed(cr) + $signed(dr);    // (w bits) -> w+1 bits
        sum_final = $signed(sum1) + $signed(sum2);// (w+1 bits) -> w+2 bits
    end

    // ----------------------------
    // pipeline registers (single driver for s)
    // ----------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            ar <= '0;
            br <= '0;
            cr <= '0;
            dr <= '0;
            s  <= '0;
        end else begin
            ar <= a;
            br <= ar;
            cr <= br;
            dr <= cr;

            // single registered assignment to output
            s <= sum_final;
        end
    end

endmodule

