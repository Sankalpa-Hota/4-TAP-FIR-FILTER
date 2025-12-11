`timescale 1ns/1ps

module fir4_Carry_Select_Adder_u #(parameter w = 16)(
    input  logic                  clk,
    input  logic                  reset,
    input  logic signed [w-1:0]   a,
    output logic signed [w+1:0]   s
);

    // pipeline regs
    logic signed [w-1:0] ar, br, cr, dr;

    // CSA params
    localparam int B  = 4;
    localparam int NB = (w + B - 1) / B;

    // intermediate partial sums (w+1 bits each)
    logic signed [w:0] sum1; // ar+br result (w+1 bits)
    logic signed [w:0] sum2; // cr+dr result (w+1 bits)
    logic signed [w+1:0] sum_final; // final (w+2 bits)

    // temporaries used in combinational CSA
    logic [B:0] blk_r0; // result for block with cin=0 (B+1 bits)
    logic [B:0] blk_r1; // result for block with cin=1 (B+1 bits)
    logic [B-1:0] A_blk, B_blk;
    logic carry;

    // ----------------------------
    // combinational CSA (block-wise using vector add)
    // ----------------------------
    always_comb begin
        // Initialize to avoid X propagation
        sum1 = '0;
        sum2 = '0;
        sum_final = '0;

        // -------------------- compute sum1 = ar + br --------------------
        carry = 1'b0;
        for (int b = 0; b < NB; b++) begin
            int base = b * B;
            int len = (w - base >= B) ? B : (w - base); // number of valid bits in this block

            // zero-extend A_blk/B_blk and copy len bits into LSBs
            A_blk = '0;
            B_blk = '0;
            if (len > 0) begin
                A_blk[0 +: len] = ar[base +: len];
                B_blk[0 +: len] = br[base +: len];
            end

            // compute block results as small integer additions (width = len, but we'll compute on B)
            // form operands as (B+1)-bit unsigned for addition: {1'b0, A_blk} + {1'b0, B_blk} + cin
            // Note: we compute full B+1 width results and then take LSB len bits to place
            blk_r0 = {1'b0, A_blk} + {1'b0, B_blk} + 1'b0;
            blk_r1 = {1'b0, A_blk} + {1'b0, B_blk} + 1'b1;

            // select based on carry (carry is 0 or 1)
            if (len > 0) begin
                // place only len LSBs into sum1
                sum1[base +: len] = (carry == 1'b0) ? blk_r0[0 +: len] : blk_r1[0 +: len];
            end
            // update carry = chosen block's MSB (blk_rX[B])
            carry = (carry == 1'b0) ? blk_r0[B] : blk_r1[B];
        end
        // top carry becomes MSB of sum1
        sum1[w] = carry;

        // -------------------- compute sum2 = cr + dr --------------------
        carry = 1'b0;
        for (int b = 0; b < NB; b++) begin
            int base = b * B;
            int len = (w - base >= B) ? B : (w - base);

            A_blk = '0;
            B_blk = '0;
            if (len > 0) begin
                A_blk[0 +: len] = cr[base +: len];
                B_blk[0 +: len] = dr[base +: len];
            end

            blk_r0 = {1'b0, A_blk} + {1'b0, B_blk} + 1'b0;
            blk_r1 = {1'b0, A_blk} + {1'b0, B_blk} + 1'b1;

            if (len > 0) begin
                sum2[base +: len] = (carry == 1'b0) ? blk_r0[0 +: len] : blk_r1[0 +: len];
            end
            carry = (carry == 1'b0) ? blk_r0[B] : blk_r1[B];
        end
        sum2[w] = carry;

        // -------------------- final signed addition --------------------
        // sign-extend each (they are w+1 bits) into w+2 and add signed
        sum_final = $signed({ sum1[w], sum1 }) + $signed({ sum2[w], sum2 });
    end

    // ----------------------------
    // pipeline registers (single driver for 's')
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

            // register final sum, single driver
            s <= sum_final;
        end
    end

endmodule

