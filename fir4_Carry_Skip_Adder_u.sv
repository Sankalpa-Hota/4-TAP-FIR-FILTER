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
// CARRY SKIP ADDER
// ==========================
// Skips carry across blocks with propagate condition
// Delay ~ w / block_size

localparam B = 4; // block size

logic [w-1:0] p;
logic [w  :0] c;
logic [w+1:0] sum;

always_comb begin
  c[0] = 1'b0;

  for (int i = 0; i < w; i++) begin
    p[i] = ar[i] ^ br[i];
    {c[i+1], sum[i]} = ar[i] + br[i] + c[i];
  end

  // Add remaining two operands
  sum = sum + cr + dr;
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
