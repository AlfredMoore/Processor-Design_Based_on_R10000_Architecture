/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  regfile.v                                           //
//                                                                     //
//  Description :  This module creates the Regfile used by the ID and  // 
//                 WB Stages of the Pipeline.                          //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __REGFILE_V__
`define __REGFILE_V__

`timescale 1ns/100ps

module regfile(
        input   reset,
        input  logic [`WIDTH-1:0][4:0]  wr_idx,    // read/write index
        input  logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] retire_tag,
        input  logic [`WIDTH-1:0] [`XLEN-1:0] wr_data,            // write data
        input  logic [`WIDTH-1:0]     wr_en,     
        input  wr_clk,
     //   input  rollback_en,
        output logic [31:0] [$clog2(`PRF_SIZE)-1:0] recover_tag
          
      );
  
  logic   [31:0] [`XLEN-1:0] registers;   // 32, 64-bit Registers
  logic   [31:0] [$clog2(`PRF_SIZE)-1:0] tag;

  assign recover_tag = tag;
  //
  // Write port
  //
  always_ff @(posedge wr_clk) begin
  if(reset)begin
    registers <= 0;
    for(int b = 0; b<`RF_SIZE; b++) begin
      tag[b] <= b;
      
    end
  end
  else begin 
  for(int a = 0; a<`WIDTH; a++) begin
    if (wr_en[a]) begin
      registers[wr_idx[a]] <=  wr_data[a];
      tag[wr_idx[a]] <= retire_tag[a];
    end
  end
  end
  end

endmodule // regfile
`endif //__REGFILE_V__
