// This rank-order filter accepts a stream of data and sorts the 5 most recent values in
//   ascending sequence. Each time a new value is accepted, the oldest value in the sorted
//   queue is eliminated, and the new value takes its appropriate position among the four
//   remaining stored values.
// The concept is easily parameterized and extended to any number of samples of any bit width.
// J. Eldon   2007.05.12    SystemVerilog version
// Note loop indices w/ C-type ++; note new variable types; note VHDL time constants; note assertions

module medianFiltBench;	   // test bench presents random data sequence

bit      clk,
         rst_n;   			   // start in reset mode
bit[7:0] dI;
bit[8:0] ctr; 
bit[7:0] Hist[7];  	   // keep history of most recent inputs for verification purposes
bit[7:0] sortedHist[6];
wire[7:0]  tap;            // median of most recent 5 data inputs

medianFilt mf(.*);		   // .* means "hook up each port to same-named bus in bench"
medianFiltSB mfb(.*);

initial begin
  #30ns rst_n = 1'b1;           // release reset
  #8000ns $stop;
end  

always begin : clkGenLoop
//  $strobe(dI,,,,mf.sd[1],,mf.sd[2],,mf.sd[3],,mf.sd[4],,mf.sd[5],,,,
//                mf.no[1],,mf.no[2],,mf.no[3],,mf.no[4],,mf.no[5],,,mf.oi[1]);
  #5ns clk = 1'b1;
  #5ns clk = 1'b0;
  if(rst_n==1'b1) begin
	ctr++;
	if(ctr==50)
	  dI = 255;
	else
	  dI = ctr[7:0];   
  end
//    assert(dataIn.randomize());    
//    dI = $random;          // also try $random<<4 to increase the number of equal entries
end : clkGenLoop 

always @(posedge clk) begin
  Hist[0:5] <= {dI,Hist[0:4]};
  #1ns;
  sortedHist[0:4] <= Hist[0:4];
  #1ns;
  sortedHist.sort;//rsort;//(Hist[0:5]); 
  #1ns;
// make sure no value exceeds the one to its right
//  if((mf.sd[5]<mf.sd[4]) || (mf.sd[4]<mf.sd[3]) || (mf.sd[3]<mf.sd[2]) || (mf.sd[2]<mf.sd[1]))
  seqCheck: assert(mf.sd[5]>=mf.sd[4] && mf.sd[4]>=mf.sd[3] && mf.sd[3]>=mf.sd[2] && mf.sd[2]>=mf.sd[1]) else
    $display("*****sequence error*****!!!!");
// make sure the total of the last 4 inputs = the total of the current sorted stack
  histCheck: assert ((mf.sd[5]+mf.sd[4]+mf.sd[3]+mf.sd[2]+mf.sd[1])==(Hist[4]+Hist[3]+Hist[2]+Hist[1]+Hist[0])) else
    $display("****history error sv*****",Hist[4],,Hist[3],,Hist[2],,Hist[1],,Hist[0],,
       ,,mf.sd[1],,mf.sd[2],,mf.sd[3],,mf.sd[4],,mf.sd[5],,,,$time);  
  if ((mf.sd[5]+mf.sd[4]+mf.sd[3]+mf.sd[2]+mf.sd[1])!=(Hist[4]+Hist[3]+Hist[2]+Hist[1]+Hist[0]))
    $display("****history error*****",Hist[4],,Hist[3],,Hist[2],,Hist[1],,Hist[0],,
       ,,mf.sd[1],,mf.sd[2],,mf.sd[3],,mf.sd[4],,mf.sd[5],,,,$time);  
  $display("%p     %p",sortedHist[0:4],Hist[0:4]);
end  
/*
genvar ixd;			        // advance the record of previous values
generate
for(ixd=0;ixd<6;ixd++) begin :propHist
  always @(posedge clk) 
    Hist[ixd+1] <= Hist[ixd];
end
endgenerate */
endmodule

module medianFiltSB(
 input       clk,
             rst_n,          // reset (active low)
 input[7:0]  dI,
 output[7:0] tap);     // can select any value in stack; choose median, sd[3]

logic[7:0]   dff[0:5], dffSort[0:4];
logic        lt01 = dff[0]<dff[1];
logic        lt02 = dff[0]<dff[2];
logic        lt03 = dff[0]<dff[3];
logic        lt04 = dff[0]<dff[4];
logic        lt12 = dff[1]<dff[2];
logic        lt13 = dff[1]<dff[3];
logic        lt14 = dff[1]<dff[4];
logic        lt23 = dff[2]<dff[3];
logic        lt24 = dff[2]<dff[4];
logic        lt34 = dff[3]<dff[4];
logic[2:0]   p[0:4];

always_ff @(posedge clk, negedge rst_n) 
  if(!rst_n)
    foreach(dff[i])
      dff[i] <= 0;
  else  
    dff[0:5] <= {dI,dff[0:4]}; 

always_comb begin
  p[0] = !lt01 + !lt02 + !lt03 + !lt04;
  p[1] = lt01 + !lt12 + !lt13 + !lt14;
  p[2] = lt02 + lt12 + !lt23 + !lt24;
  p[3] = lt03 + lt13 + lt23 + !lt34;   
  p[4] = lt04 + lt14 + lt24 + lt34;
end  

endmodule

module medianFilt(
 input       clk,
             rst_n,          // reset (active low)
 input[7:0]  dI,
 output[7:0] tap);     // can select any value in stack; choose median, sd[3]

logic[7:0]   dff[0:5];

always_ff @(posedge clk, negedge rst_n) 
  if(!rst_n)
    foreach(dff[i])
      dff[i] <= 0;
  else  
    dff[0:5] <= {dI,dff[0:4]};
   
logic[7:0] oi[0:5],      // old data to each cell
           ni[0:5], 	 // new data to each cell
           nd[0:5], 	 // value in cell to right
           oo[0:5], 	 // pass-through of oi
           no[0:5], 	 // value to push to right (either sd or ni)
           sd[0:5];      // sorted data 

genvar px;
generate
  for(px=1;px<5;px++) begin :px_loop
    mFcell mF(.clk(clk),.rst_n(rst_n),.oi(oi[px]),.ni(ni[px]),.nd(nd[px]),
     .oo(oo[px]),.no(no[px]),.sd(sd[px]));
  end :px_loop
endgenerate  
//mFcell  mF1 (clk,rst_n,oi[1],ni[1],nd[1],oo[1],no[1],sd[1]);
//mFcell  mF2 (clk,rst_n,oi[2],ni[2],nd[2],oo[2],no[2],sd[2]);
//mFcell  mF3 (clk,rst_n,oi[3],ni[3],nd[3],oo[3],no[3],sd[3]);
//mFcell  mF4 (clk,rst_n,oi[4],ni[4],nd[4],oo[4],no[4],sd[4]);
mFcellL mF5 (clk,rst_n,oi[5],ni[5],nd[5],oo[5],no[5],sd[5]);	  // special final (largest content) cell
 
assign no[0] = dI; 	         // fresh data to sorting stack
assign oo[0] = dff[4];	     // 4-cycle delay; old data to be removed from sorting stack
assign nd[5] = oo[5]; 	     // special end case 
assign tap   = sd[3];	     // output median of the 5 most recent samples
 
genvar kx; 
generate
  for(kx=1;kx<6;kx++) begin :hookup_loop
    assign oi[kx] = oo[kx-1];  // old data stream
    assign ni[kx] = no[kx-1];  // new data stream
    assign nd[kx-1] = sd[kx];  // contents to cell on left
  end
endgenerate

endmodule

// special last (largest contents) cell
module mFcellL(
  input clk,
  input rst_n,
  input[7:0] oi,             // expiring data
  input[7:0] ni,             // data from left (value or new data)
  input[7:0] nd,             // value in cell to right
  output[7:0] oo,            // expiring data (pass-through)
  output[7:0] no,            // push to right (value or new data)
  output logic[7:0] sd);     // current value; push to left

logic[7:0] od;				 // next value of stored
assign no = 8'b0;
assign oo = oi;

always_comb case ({(oi==sd),(ni<sd)})
  2'b00: 
    od = ni;                 // new data input to ranked value
  2'b01: 
    od = sd;                 // hold current ranked value
  2'b10,2'b11: 
    od = ni;
endcase

always_ff @(posedge clk, negedge rst_n)
  if(!rst_n)
    sd <= 0;  		         
  else 
    sd <= od;				 // update stored value
endmodule   

// all of the other cells
module mFcell(
  input clk,
  input rst_n,
  input[7:0] oi,             // expiring data
  input[7:0] ni,             // data from left (value or new data)
  input[7:0] nd,             // value in cell to right
  output[7:0] oo,            // expiring data (pass-through)
  output logic[7:0] no,      // push to right (value or new data)
  output logic[7:0] sd);     // current value; push to left

logic[7:0] od;

assign oo = oi;

always_comb case ({(oi>sd),(ni<sd),(ni<nd)})
  3'b110,3'b111: begin
    od = ni;			     // new data to this sorting cell
    no = sd;				 // this cell's data goes right
  end
  3'b001,3'b011: begin
    od = ni;                 // 
    no = nd;
  end
  3'b100,3'b101: begin			     
    od = sd;				 // hold sorted value
    no = ni;				 // new incoming data goes right
  end
  3'b000,3'b010: begin
    od = nd;			     // replace own stored value with stored on right
    no = ni;				 // send incoming data rightward
  end
endcase

always_ff @(posedge clk, negedge rst_n)
  if(!rst_n)
    sd <= 0;
  else 
	sd <= od;
          
endmodule