`timescale 1ns/1ps
module fir4_Carry_Skip_Adder_u #(parameter w=16)(
    input  logic              clk,
    input  logic              reset,
    input  logic [w-1:0]      a,
    output logic [w+1:0]      s
);

    // -------------------------------------
    // Pipeline registers for input delay
    // -------------------------------------
    logic [w-1:0] ar, br, cr, dr;

    // =====================================
    // TRUE CARRY SKIP ADDER PARAMETERS
    // =====================================
    localparam int B  = 4;               // block size
    localparam int NB = (w + B - 1) / B; // number of blocks

    logic [w-1:0] p;          // bit propagate
    logic [w-1:0] g;          // bit generate
    logic [w  :0] c;          // carry chain
    logic [NB-1:0] bp;        // block propagate
    logic [w-1:0] sum_ab;     // sum of ar + br
    logic [w+1:0] sum;        // final sum

    // Temporary variables (declared outside always block for simulator safety)
    logic carry_in_bit;
    integer i, b, idx, base, next_boundary;

    // -------------------------------------
    // Combinational Carry-Skip Logic
    // -------------------------------------
    always_comb begin
        // Generate bit propagate and generate
        for (i = 0; i < w; i=i+1) begin
            p[i] = ar[i] ^ br[i];
            g[i] = ar[i] & br[i];
        end

        // Initialize carry
        c[0] = 1'b0;

        // Carry-Skip per block
        for (b = 0; b < NB; b=b+1) begin
            base = b * B;

            // 1. Compute block propagate
            bp[b] = 1'b1;
            for (i = 0; i < B; i=i+1) begin
                idx = base + i;
                if (idx < w)
                    bp[b] = bp[b] & p[idx];
            end

            // 2. Ripple inside block
            carry_in_bit = c[base];  // incoming carry to block
            for (i = 0; i < B; i=i+1) begin
                idx = base + i;
                if (idx < w) begin
                    sum_ab[idx] = p[idx] ^ carry_in_bit;
                    carry_in_bit = g[idx] | (p[idx] & carry_in_bit);
                    c[idx+1] = carry_in_bit;
                end
            end

            // 3. Skip logic at block boundary
            next_boundary = base + B;
            if (next_boundary < w) begin
                c[next_boundary] = bp[b] ? c[base] : carry_in_bit;
            end
        end

        // 4. Final sum including cr + dr pipeline stages
        sum = {c[w], sum_ab} + cr + dr;  // <-- key update
    end

    // -------------------------------------
    // Pipeline Registers
    // -------------------------------------
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
            s  <= sum;
        end
    end

endmodule

