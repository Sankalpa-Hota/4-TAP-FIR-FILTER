`timescale 1ns/1ps

module fir4_wta_u #(parameter w=16)(
    input  logic                clk,
    input  logic                reset,
    input  signed [w-1:0]      a,
    output logic signed [w+1:0] s
);

    // ---------------------------
    // Pipeline registers
    // ---------------------------
    logic signed [w-1:0] ar, br, cr, dr;

    // ---------------------------
    // Wallace Tree intermediates
    // ---------------------------
    logic [w-1:0] sum_row;
    logic [w-1:0] carry_row;
    logic signed [w:0] sum1, sum2;
    logic signed [w+1:0] sum_comb;

    // declare all temporaries at top of always_comb
    logic [w-1:0] carry_next;
    logic fa_sum, fa_carry, fa2_sum, fa2_carry;

    always_comb begin
        // Initialize arrays
        for(int i=0; i<w; i=i+1) begin
            sum_row[i]   = 0;
            carry_row[i] = 0;
            carry_next[i] = 0;
        end
        sum1 = '0;
        sum2 = '0;
        sum_comb = '0;

        // ---------------------------
        // Level 1: Reduce 4 operands to 2 rows
        // ---------------------------
        for(int i=0; i<w; i=i+1) begin
            // First FA: sum of ar,br,cr
            fa_sum   = ar[i] ^ br[i] ^ cr[i];
            fa_carry = (ar[i]&br[i]) | (br[i]&cr[i]) | (ar[i]&cr[i]);

            // Second FA: add dr + previous column carry
            fa2_sum   = fa_sum ^ dr[i] ^ carry_next[i];
            fa2_carry = (fa_sum & dr[i]) | (fa_sum & carry_next[i]) | (dr[i] & carry_next[i]);

            // Store sum row and carry row
            sum_row[i]   = fa2_sum;
            carry_row[i] = fa_carry | fa2_carry;

            // propagate carry to next column
            if(i < w-1)
                carry_next[i+1] = fa2_carry;
        end

        // ---------------------------
        // Level 2: Final two-row addition
        // ---------------------------
        for(int i=0; i<w; i=i+1) begin
            sum1[i] = sum_row[i];
            sum2[i] = carry_row[i];
        end
        sum1[w] = carry_next[w-1];        // top carry
        sum2 = {sum2[w-2:0],1'b0};        // shift carry row left by 1

        sum_comb = $signed(sum1) + $signed(sum2);
    end

    // ---------------------------
    // Pipeline registers
    // ---------------------------
    always_ff @(posedge clk) begin
        if(reset) begin
            ar <= 0; br <= 0; cr <= 0; dr <= 0;
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

