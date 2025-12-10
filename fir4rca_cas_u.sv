// ECE260A Lab 3
// keep the same input and output and the same input and output registers
// change the combinational addition part to something more optimal
// refer to Fig. 11.42(a) in W&H 
// cascade of three ripple carry adders
module fir4rca_cas_u #(parameter w=16)(
  input                      clk, 
                             reset,
  input         [w-1:0] a,
  output logic  [w+1:0] s);
// delay pipeline for input a
  logic         [w-1:0] ar, br, cr, dr;

// RIPPLE CARRY ADDER LOGIC 

  logic         [w-1:0] rca1_s;
  logic         [w  :0] rca2_s; 
  logic         [w+1:0] rca3_s;
  logic         [w  :0] rc1;
  logic         [w  :0] cr2;
  logic         [w+1:0] rc2;
  logic         [w+1:0] dr3;
  logic         [w  :0] rca1_co;
  logic         [w+1:0] rca2_co;
  logic         [w+2:0] rca3_co;

  logic         [w+1:0] sum;

  always_comb begin
    rca1_co[0] = 0;
    for(int i=0; i<w; i++)
      {rca1_co[i+1],rca1_s[i]} = ar[i] + br[i] + rca1_co[i];
	rc1 = {rca1_co[w],rca1_s};
  end
  always_comb begin
    rca2_co[0] = 0;
	cr2        = {1'b0,cr};
    for(int i=0; i<w+1; i++)
      {rca2_co[i+1],rca2_s[i]} = rc1[i] + cr2[i] + rca2_co[i];
	rc2 = {rca2_co[w+1],rca2_s};
  end
  always_comb begin    
    rca3_co[0] = 0;
	dr3        = {2'b0,dr};
    for(int i=0; i<w+2; i++)
      {rca3_co[i+1],rca3_s[i]} = rc2[i] + dr3[i] + rca3_co[i];
  end
  always_comb
    sum = rca3_s;
 
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
