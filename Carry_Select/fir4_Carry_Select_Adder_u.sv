
// FIR module with Carry Select Adder replacing Ripple Carry
module fir4csa_u #(parameter w=16)(
  input                     clk,
                            reset,
  input         [w-1:0]    a,
  output logic  [w+1:0]    s
);

  // Delay pipeline for input a
  logic [w-1:0] ar, br, cr, dr;

  // ==========================
  // CARRY SELECT ADDER
  // ==========================
  // Stage 1: ar + br
  // Stage 2: cr + dr
  // Precompute sum for Cin=0 and Cin=1 in each block
  // Select based on carry-out of previous block
  // ==========================

  localparam int B = 4; // block size
  localparam int NB = (w + B - 1)/B; // number of blocks

  logic [w-1:0] sum1, sum2;
  logic [w:0]   c1, c2;       // bit-level carry for each stage
  logic [w:0]   c1_block, c2_block; // block-level carry
  logic [w:0]   sum0_1, sum1_1, sum0_2, sum1_2;
  logic [w+1:0] sum_comb;

  always_comb begin
    // -------------------------
    // Stage 1: ar + br
    // -------------------------
    c1[0] = 1'b0;
    for (int b = 0; b < NB; b++) begin
      // Precompute block sums
      for (int i = 0; i < B; i++) begin
        int idx = b*B + i;
        if (idx < w) begin
          sum0_1[idx] = ar[idx] + br[idx] + 1'b0; // Cin=0
          sum1_1[idx] = ar[idx] + br[idx] + 1'b1; // Cin=1
        end
      end
      // Select sum based on previous block carry
      if (b==0)
        c1_block[b] = 1'b0;
      else
        c1_block[b] = c1_block[b-1][w%B-1]; // carry-out of previous block
      for (int i = 0; i < B; i++) begin
        int idx = b*B + i;
        if (idx < w) begin
          {c1[idx+1], sum1[idx]} = c1_block[b] ? sum1_1[idx] : sum0_1[idx];
        end
      end
    end

    // -------------------------
    // Stage 2: cr + dr
    // -------------------------
    c2[0] = 1'b0;
    for (int b = 0; b < NB; b++) begin
      for (int i = 0; i < B; i++) begin
        int idx = b*B + i;
        if (idx < w) begin
          sum0_2[idx] = cr[idx] + dr[idx] + 1'b0;
          sum1_2[idx] = cr[idx] + dr[idx] + 1'b1;
        end
      end
      if (b==0)
        c2_block[b] = 1'b0;
      else
        c2_block[b] = c2_block[b-1][w%B-1];
      for (int i = 0; i < B; i++) begin
        int idx = b*B + i;
        if (idx < w) begin
          {c2[idx+1], sum2[idx]} = c2_block[b] ? sum1_2[idx] : sum0_2[idx];
        end
      end
    end

    // -------------------------
    // Final addition: stage1 + stage2
    // -------------------------
    sum_comb = {c1[w], sum1} + {c2[w], sum2};
  end

  // Sequential logic (unchanged)
  always_ff @(posedge clk) begin
    if(reset) begin
      ar <= 'b0;
      br <= 'b0;
      cr <= 'b0;
      dr <= 'b0;
      s  <= 'b0;
    end
    else begin
      ar <= a;
      br <= ar;
      cr <= br;
      dr <= cr;
      s  <= sum_comb;
    end
  end

endmodule
