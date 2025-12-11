`timescale 1ns/1ps
module fir4_CLA_u #(parameter w=16)(
    input  signed [w-1:0] a,
    input                 clk,
    input                 reset,
    output logic signed [w+1:0] s
);

    // pipeline delay registers: 4 last inputs
    logic signed [w-1:0] ar, br, cr, dr;

    // partial sums (signed)
    logic signed [w:0] sum1, sum2;

    // propagate/generate
    logic p1 [w:0], g1 [w:0];
    logic p2 [w:0], g2 [w:0];

    // carries
    logic c1 [w:0], c2 [w:0];

    // final adder (signed, w+2 bits)
    logic signed [w+1:0] sum1_ext, sum2_ext;
    logic p3 [w+1:0], g3 [w+1:0];
    logic c3 [w+1:0];
    logic signed [w+1:0] sum_comb;

    // -----------------------------------------
    // Combinational: perform (ar+br) + (cr+dr)
    // -----------------------------------------
    always_comb begin

        // ------------------------
        // First CLA: sum1 = ar + br
        // ------------------------
        c1[0] = 1'b0;
        for(int i=0; i<w; i++) begin
            p1[i] = ar[i] ^ br[i];
            g1[i] = ar[i] & br[i];
            c1[i+1] = g1[i] | (p1[i] & c1[i]);
            sum1[i] = p1[i] ^ c1[i];
        end
        sum1[w] = c1[w]; // sign extension bit from CLA

        // ------------------------
        // Second CLA: sum2 = cr + dr
        // ------------------------
        c2[0] = 1'b0;
        for(int i=0; i<w; i++) begin
            p2[i] = cr[i] ^ dr[i];
            g2[i] = cr[i] & dr[i];
            c2[i+1] = g2[i] | (p2[i] & c2[i]);
            sum2[i] = p2[i] ^ c2[i];
        end
        sum2[w] = c2[w];

        // ------------------------------------
        // SIGN-EXTEND BOTH partial sums to w+2
        // ------------------------------------
        sum1_ext = { sum1[w], sum1 };
        sum2_ext = { sum2[w], sum2 };

        // ------------------------------------
        // Final CLA: (w+2)-bit signed add
        // ------------------------------------
        c3[0] = 1'b0;
        for(int i=0; i<w+2; i++) begin
            p3[i] = sum1_ext[i] ^ sum2_ext[i];
            g3[i] = sum1_ext[i] & sum2_ext[i];
            c3[i+1] = g3[i] | (p3[i] & c3[i]);
            sum_comb[i] = p3[i] ^ c3[i];
        end
        sum_comb[w+1] = c3[w+1];
    end

    // -----------------------------------------
    // Registers (pipeline of 4 inputs)
    // -----------------------------------------
    always_ff @(posedge clk) begin
        if(reset) begin
            ar <= 0;
            br <= 0;
            cr <= 0;
            dr <= 0;
            s  <= 0;
        end else begin
            ar <= a;
            br <= ar;
            cr <= br;
            dr <= cr;
            s  <= sum_comb;
        end
    end

endmodule

