// ECE260A Lab 3
// keep the same input and output and the same input and output registers
// change the combinational addition part to something more optimal
// refer to Fig. 11.42(a) in W&H 
module fir4rca_u #(parameter w=16)(
  input                      clk, 
                             reset,
  input         [w-1:0] a,
  output logic  [w+1:0] s);
// delay pipeline for input a
  logic         [w-1:0] ar, br, cr, dr;

// RIPPLE CARRY ADDER LOGIC 

  logic         [w-1:0] rca1_s,  rca2_s; 
  logic         [w  :0] rca1_co, rca2_co;

  logic         [w+1:0] sum;

  always_comb begin
    rca1_co[0] = 0;
    for(int i=0; i<w; i++)
      {rca1_co[i+1],rca1_s[i]} = ar[i]+br[i]+rca1_co[i];
  end
  always_comb begin
    rca2_co[0] = 0;
    for(int i=0; i<w; i++)
      {rca2_co[i+1],rca2_s[i]} = cr[i]+dr[i]+rca2_co[i];
  end
  always_comb
    sum = {rca1_co[w],rca1_s} + {rca2_co[w],rca2_s};
 
// END OF RIPPLE CARRY ADDER

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
