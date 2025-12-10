// ECE260A Fall 2022 Lab 3
// sample 4-input carry save adder, based on W&H Fig. 11.42 (p. 459) 
// always keep the same inputs and outputs and the same input and output registers
// try various versions of the combinational part, which executes sum = ar + br + cr + dr
module fir4csa #(parameter w=16)(
  input                       clk, 
                              reset,
  input        [w-1:0] a, 		// serial input -- filter will sum 4 consecutive values
  output logic [w+1:0] s);		// sum of 4 most recent values of a

  logic        signed [w-1:0] ar, br, cr, dr;
// combinational adder array -- this is what you should customize/optimize
// CSA version
  logic         [w-1:0] csa4_s;   // from w-bit top CSA
  logic         [w  :0] csa4_c;
  logic         [w  :0] csa5_s;   // from w+1-bit bottom CSA
  logic         [w+1:0] csa5_c;
  logic         [w+1:0] sum;	  // from final ripple adder
  logic         [w+1:0] p;
  logic         [w+1:0] g;
  logic         [w+1:0] c;

  always_comb begin
    csa4_c[0] = 0;                // carry runs from [w:1], not [w-1:0]
    csa5_c[0] = 0; 
    for(int i=0; i<w; i++)
      {csa4_c[i+1],csa4_s[i]} = ar[i]+br[i]+cr[i];
    for(int i=0; i<w+1; i++)
      {csa5_c[i+1],csa5_s[i]} = csa4_c[i]+csa4_s[i]+dr[i];
//    csa5_s[w] = csa4_c[w];	      // don't even need top FA
//    csa5_c[w+1] = 0;
//    sum = csa5_c + csa5_s;        // final CPA or ripple adder (behavioral statement here)    

//CLA for last stage
    for(int i=0; i<w; i++) begin
      p[i]=csa5_s[i]^csa5_c[i];
      g[i]=csa5_s[i]&csa5_c[i];
      c[0]=g[0]|(p[0]&csa5_c[0]);
      c[i+1]=g[i]|(p[i]&c[i]);
      sum[0]=p[0]^csa5_c[0];
      sum[i]=p[i]^c[i];
    end
  end

//  wire         signed [16:0] sum1 = ar + br;
//  wire         signed [16:0] sum2 = cr + dr;
//  wire         signed [17:0] sum = sum1 + sum2; 
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
	  ar <= a;
	  br <= ar;
	  cr <= br;
	  dr <= cr;
	  s  <= sum; 
	end

endmodule
