module fir4_CLA_u #(parameter w=16)(
  input                      clk, 
                             reset,
  input         [w-1:0] a,
  output logic  [w+1:0] s);
// delay pipeline for input a
  logic         [w-1:0] ar, br, cr, dr;

// ==========================
// TRUE CARRY LOOKAHEAD ADDER
// ==========================
// Hierarchical CLA with group propagate & generate
// Reduces carry dependency depth vs RCA
// ==========================

localparam int B  = 4;               // block size
localparam int NB = (w + B - 1) / B; // number of blocks

logic [w-1:0] p1, g1, p2, g2;        // bit propagate / generate
logic [NB-1:0] Pg1, Gg1, Pg2, Gg2;   // group propagate / generate
logic [w:0] c1, c2;                 // bit-level carries
logic [NB:0] Cg1, Cg2;              // group-level carries

logic [w-1:0] sum1, sum2;
logic [w+1:0] sum;

always_comb begin
  // --------------------------
  // Bit-level propagate & generate
  // --------------------------
  for (int i = 0; i < w; i++) begin
    p1[i] = ar[i] ^ br[i];
    g1[i] = ar[i] & br[i];
    p2[i] = cr[i] ^ dr[i];
    g2[i] = cr[i] & dr[i];
  end

  // --------------------------
  // Group propagate & generate
  // --------------------------
  for (int b = 0; b < NB; b++) begin
    Pg1[b] = 1'b1;
    Gg1[b] = 1'b0;
    Pg2[b] = 1'b1;
    Gg2[b] = 1'b0;

    for (int i = 0; i < B; i++) begin
      int idx = b*B + i;
      if (idx < w) begin
        Gg1[b] |= g1[idx] & Pg1[b];
        Pg1[b] &= p1[idx];

        Gg2[b] |= g2[idx] & Pg2[b];
        Pg2[b] &= p2[idx];
      end
    end
  end

  // --------------------------
  // Group-level carry lookahead
  // --------------------------
  Cg1[0] = 1'b0;
  Cg2[0] = 1'b0;

  for (int b = 0; b < NB; b++) begin
    Cg1[b+1] = Gg1[b] | (Pg1[b] & Cg1[b]);
    Cg2[b+1] = Gg2[b] | (Pg2[b] & Cg2[b]);
  end

  // --------------------------
  // Bit-level carry resolution
  // --------------------------
  for (int b = 0; b < NB; b++) begin
    c1[b*B] = Cg1[b];
    c2[b*B] = Cg2[b];

    for (int i = 0; i < B; i++) begin
      int idx = b*B + i;
      if (idx < w) begin
        c1[idx+1] = g1[idx] | (p1[idx] & c1[idx]);
        c2[idx+1] = g2[idx] | (p2[idx] & c2[idx]);

        sum1[idx] = p1[idx] ^ c1[idx];
        sum2[idx] = p2[idx] ^ c2[idx];
      end
    end
  end

  // --------------------------
  // Final sum (unchanged intent)
  // --------------------------
  sum = {c1[w], sum1} + {c2[w], sum2};
end

// sequential logic -- standardized for everyone
  always_ff @(posedge clk)			// or just always -- always_ff tells tools you intend D flip flops
    if(reset) begin					// reset forces all registers to 0 for clean start of test
	  ar <= 'b0;
	  br <= 'b0;
	  cr <= 'b0;
	  dr <= 'b0;
	  s  <= 'b0;
    end
    else begin					    // normal operation -- Dffs update on posedge clk
	  ar <= a;						// the chain will always hold the four most recent incoming data samples
	  br <= ar;
	  cr <= br;
	  dr <= cr;
	  s  <= sum; 
	end

endmodule
