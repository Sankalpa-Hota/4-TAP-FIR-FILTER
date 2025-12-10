// ECE260A Lab 3
// keep the same input and output and the same input and output registers
// change the combinational addition part to something more optimal
// refer to Fig. 11.42(a) in W&H 
module fir4_CLA_u #(parameter w=16)(
  input                      clk, 
                             reset,
  input         [w-1:0] a,
  output logic  [w+1:0] s);
// delay pipeline for input a
  logic         [w-1:0] ar, br, cr, dr;

// ==========================
// CARRY LOOKAHEAD ADDER
// ==========================
// Uses propagate/generate logic to reduce carry chain depth
// aster than RCA by constant factor, not asymptotic improvement.

logic [w-1:0] p1, g1, p2, g2;
logic [w  :0] c1, c2;
logic [w+1:0] sum;

always_comb begin
  // Generate & propagate for ar + br
  for (int i = 0; i < w; i++) begin
    p1[i] = ar[i] ^ br[i];
    g1[i] = ar[i] & br[i];
  end

  c1[0] = 1'b0;
  for (int i = 0; i < w; i++)
    c1[i+1] = g1[i] | (p1[i] & c1[i]);

  // Generate & propagate for cr + dr
  for (int i = 0; i < w; i++) begin
    p2[i] = cr[i] ^ dr[i];
    g2[i] = cr[i] & dr[i];
  end

  c2[0] = 1'b0;
  for (int i = 0; i < w; i++)
    c2[i+1] = g2[i] | (p2[i] & c2[i]);

  // Final sum
  sum = {c1[w], p1 ^ c1[w-1:0]} + {c2[w], p2 ^ c2[w-1:0]};
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
