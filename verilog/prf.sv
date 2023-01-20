`timescale 1ns/100ps

module PRF(
    input clock,
    input reset,
    //from issue
    input logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] t1,
    input logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] t2,
    //from FU
    input CDB [`WIDTH-1:0] cdb,
    input logic [`WIDTH-1:0] [`XLEN-1:0] val,
    //from retire
    input logic [`WIDTH-1:0] retire_en,
    input logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] t_retire,
    input logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] thold_retire,
    //to FU
    output logic [`WIDTH-1:0] [`XLEN-1:0] val1,
    output logic [`WIDTH-1:0] [`XLEN-1:0] val2,
    //to retire
    output logic [`WIDTH-1:0] [`XLEN-1:0] ret

);

logic [(`PRF_SIZE)-1:0] [`XLEN-1:0] PR;
//logic [(`PRF_SIZE)-1:0] [`XLEN-1:0] pPR;
logic cdb_forward1;
logic cdb_forward2;


 always_comb begin
  //  PR = pPR;
  // retire
    for(int b = 0; b<`WIDTH; b++) begin
        if(retire_en[b]) begin
            ret[b] = PR[t_retire[b]];
        end
    end
 end
//issue
always_comb begin
    for(int c=0; c<`WIDTH; c++)begin
        cdb_forward1 = 0;
        for(int d=0; d<`WIDTH; d++)begin
            if(!cdb_forward1) begin
            if(cdb[d].complete && (cdb[d].p == t1[c]) ) begin
                val1[c] = val[d];
                cdb_forward1 = 1;
            end
            else begin
                val1[c] = PR[t1[c]];
            end
        end
        end
    end
end
always_comb begin
    for(int e=0; e<`WIDTH; e++)begin
        cdb_forward2 = 0;
        for(int f=0; f<`WIDTH; f++)begin
            if(!cdb_forward2) begin
            if(cdb[f].complete && (cdb[f].p == t2[e]) ) begin
                val2[e] = val[f];
                cdb_forward2 = 1;
            end
            else begin
                val2[e] = PR[t2[e]];
            end
        end
        end
    end

 end
      



always_ff@(posedge clock) begin
    if(reset) begin
        PR <= 0;
    end
    else begin
        for(int a = 0; a<`WIDTH; a++) begin
          if(cdb[a].complete) begin
            PR[cdb[a].p] <= val[a];
          end
          if(retire_en[a]) begin
            PR[thold_retire[a]] <= 0;
          end
    end
    end
end


endmodule   
