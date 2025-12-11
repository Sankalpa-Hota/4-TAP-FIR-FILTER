`timescale 1ns/1ps

module fir4_CLA_u #(parameter w = 16)(
    input  logic                 clk,
    input  logic                 reset,
    input  logic signed [w-1:0] a,
    output logic signed [w+1:0] s
);

    // pipeline registers for input staging
    logic signed [w-1:0] ar, br, cr, dr;

    // intermediate sums
    logic signed [w:0] sum1;
    logic signed [w:0] sum2;
    logic signed [w+1:0] sum_final;

    // -------------------------
    // Carry Look-Ahead Adder function
    // -------------------------
    function automatic logic [w:0] CLA_adder(input logic signed [w-1:0] x, input logic signed [w-1:0] y);
        logic [w-1:0] G; // generate
        logic [w-1:0] P; // propagate
        logic [w:0] C;   // carries
        logic [w-1:0] S; // sum bits
        begin
            // compute bitwise generate and propagate
            for (int i = 0; i < w; i++) begin
                G[i] = x[i] & y[i];
                P[i] = x[i] ^ y[i];
            end

            // initial carry
            C[0] = 1'b0;

            // compute all carries in parallel using generate/propagate
            for (int i = 0; i < w; i++) begin
                C[i+1] = G[i] | (P[i] & C[i]);
            end

            // compute sum bits
            for (int i = 0; i < w; i++) begin
                S[i] = P[i] ^ C[i];
            end

            CLA_adder = {C[w], S}; // sum + final carry
        end
    endfunction

    // -------------------------
    // combinational sum computation
    // -------------------------
    always_comb begin
        sum1 = CLA_adder(ar, br);
        sum2 = CLA_adder(cr, dr);
        sum_final = $signed({sum1[w], sum1}) + $signed({sum2[w], sum2});
    end

    // -------------------------
    // pipeline registers
    // -------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            ar <= '0; br <= '0; cr <= '0; dr <= '0;
            s  <= '0;
        end else begin
            ar <= a;
            br <= ar;
            cr <= br;
            dr <= cr;
            s <= sum_final;
        end
    end

endmodule

