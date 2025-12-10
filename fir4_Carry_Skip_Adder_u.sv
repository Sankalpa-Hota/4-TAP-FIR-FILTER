module fir4_CLA_u #(parameter w=16)(
  input                      clk, 
                             reset,
  input         [w-1:0] a,
  output logic  [w+1:0] s
);

// -------------------------------------
// Delay pipeline for input a
// -------------------------------------
logic [w-1:0] ar, br, cr, dr;

// =====================================
// TRUE CARRY SKIP ADDER (ar + br)
// =====================================
// Based on Weste & Harris Fig. 11.42(a)
// Delay ≈ (w / B) + B
// =====================================

localparam int B  = 4;               // block size
localparam int NB = (w + B - 1) / B; // number of blocks

logic [w-1:0] p;          // bit propagate
logic [w-1:0] g;          // bit generate
logic [w  :0] c;          // carry chain
logic [NB-1:0] bp;        // block propagate
logic [w-1:0] sum_ab;     // sum of ar + br

logic [w+1:0] sum;        // final sum

// -------------------------------------
// Combinational adder logic
// -------------------------------------
always_comb begin
  // Generate propagate and generate
  for (int i = 0; i < w; i++) begin
    p[i] = ar[i] ^ br[i];
    g[i] = ar[i] & br[i];
  end

  c[0] = 1'b0;

  // Carry-skip structure
  for (int b = 0; b < NB; b++) begin
    // Block propagate (AND of propagates)
    bp[b] = 1'b1;
    for (int i = 0; i < B; i++) begin
      int idx = b*B + i;
      if (idx < w)
        bp[b] &= p[idx];
    end

    // Ripple inside block
    for (int i = 0; i < B; i++) begin
      int idx = b*B + i;
      if (idx < w) begin
        c[idx+1]   = g[idx] | (p[idx] & c[idx]);
        sum_ab[idx] = p[idx] ^ c[idx];
      end
    end

    // Skip carry across block boundary
    if ((b+1)*B < w)
      c[(b+1)*B] = bp[b] ? c[b*B] : c[(b+1)*B];
  end

  // Final addition (kept identical in intent)
  sum = {c[w], sum_ab} + cr + dr;
end

// -------------------------------------
// Sequential logic (unchanged)
// -------------------------------------
always_ff @(posedge clk)
  if (reset) begin
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
    s  <= sum;
  end

endmodule
