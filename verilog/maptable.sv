`timescale 1ns/100ps

module Maptable (
    input reset,
    input clock,
    //from decoder     enable
    input logic [`WIDTH-1:0] write_en, 
    input logic [`WIDTH-1:0] [$clog2(`RF_SIZE)-1:0] destreg,
    //from rs   regsiter name 
    input logic [`WIDTH-1:0] [$clog2(`RF_SIZE)-1:0] reg1,
    input logic [`WIDTH-1:0] [$clog2(`RF_SIZE)-1:0] reg2,
    //from free list 
    input logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] T,
    //from cdb
    input CDB [`WIDTH-1:0] cdb,
    //from rob (retire)
    //input retire_packet [`WIDTH-1:0] retirepack,
    //input ROB_MT_packet [`WIDTH-1:0] rob_pack,

    input logic [31:0] [$clog2(`PRF_SIZE)-1:0] rec_tag,
    input rollback_en,
    input logic [$clog2(`RF_SIZE)-1:0] rollback_reg,
    input logic [$clog2(`PRF_SIZE)-1:0] rollback_tag,
    input exception_en,
    //to architeture reg file
    //output MapT_ARF_packet [`WIDTH-1:0]  retire_toarf,

    //to ROB
    output logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] T_hold,
    //to RS
    output MapT_RS_packet [`WIDTH-1:0] map_rs
);

 Maptable1 [`RF_SIZE-1:0] entry;
 Maptable1 [`RF_SIZE-1:0] nentry;
    logic  retirectr;
  
  
  
    //t_hold to rob
 always_comb begin 
    if(write_en[0]) begin
        T_hold[0] = entry[destreg[0]].tag;
    end
    else begin
        T_hold[0] = 0;
    end
 end
 always_comb begin
    if(write_en[1]) begin
        if(destreg[1] == destreg[0])  begin
            if(write_en[0]) begin
                T_hold[1] = T[0];
            end
            else begin
                T_hold[1] = entry[destreg[1]].tag;
            end
        end
        else begin
            T_hold[1] = entry[destreg[1]].tag;
            end
    end
    else begin
        T_hold[1] = 0;
    end
 end


    // to RS
 always_comb begin
        if(write_en[0]) begin
            map_rs[0].t1 = entry[reg1[0]].tag;
            map_rs[0].t2 = entry[reg2[0]].tag;
            if((cdb[0].complete && (entry[reg1[0]].tag == cdb[0].p)) || (cdb[1].complete && (entry[reg1[0]].tag == cdb[1].p))) begin
                map_rs[0].t1_enable = 1;
            end
            else begin
                map_rs[0].t1_enable = entry[reg1[0]].ready;
            end
            if((cdb[0].complete && (entry[reg2[0]].tag == cdb[0].p)) || (cdb[1].complete && (entry[reg2[0]].tag == cdb[1].p))) begin
                map_rs[0].t2_enable = 1;
            end
            else begin
                map_rs[0].t2_enable = entry[reg2[0]].ready;
            end            
        end
        else begin
            map_rs[0] = 0;
        end
 end
 always_comb begin

        if(write_en[1]) begin
            if(write_en[0]) begin
                if(reg1[1] == destreg[0]) begin
                    map_rs[1].t1 = T[0];
                    if(reg1[1] == `ZERO_REG) begin
                    map_rs[1].t1_enable = 1; 
                    end
                    else begin                       
                    map_rs[1].t1_enable = 0;
                    end
                    if(reg2[1] == destreg[0]) begin
                        map_rs[1].t2 = T[0];
                        if(reg2[1] == `ZERO_REG) begin
                        map_rs[1].t2_enable = 1;
                        end
                        else begin
                        map_rs[1].t2_enable = 0;
                        end
                    end
                    else begin
                        map_rs[1].t2 = entry[reg2[1]].tag;
                        if((cdb[0].complete && (entry[reg2[1]].tag == cdb[0].p)) || (cdb[1].complete && (entry[reg2[1]].tag == cdb[1].p))) begin
                            map_rs[1].t2_enable = 1;
                        end
                        else begin
                            map_rs[1].t2_enable = entry[reg2[1]].ready;
                        end            
                    end                        
                    end
                
                else begin
                    map_rs[1].t1 = entry[reg1[1]].tag;
                        if((cdb[0].complete && (entry[reg1[1]].tag == cdb[0].p)) || (cdb[1].complete && (entry[reg1[1]].tag == cdb[1].p))) begin
                            map_rs[1].t1_enable = 1;
                        end
                        else begin
                            map_rs[1].t1_enable = entry[reg1[1]].ready;
                        end            
                    if(reg2[1] == destreg[0]) begin
                        map_rs[1].t2 = T[0];
                        if(reg2[1] == `ZERO_REG) begin
                        map_rs[1].t2_enable = 1;
                        end
                        else begin
                        map_rs[1].t2_enable = 0;
                        end
                    end
                    else begin
                        map_rs[1].t2 = entry[reg2[1]].tag;
                        if((cdb[0].complete && (entry[reg2[1]].tag == cdb[0].p)) || (cdb[1].complete && (entry[reg2[1]].tag == cdb[1].p))) begin
                            map_rs[1].t2_enable = 1;
                        end
                        else begin
                            map_rs[1].t2_enable = entry[reg2[1]].ready;
                        end            
                    end
                end
            end
            else begin
                    map_rs[1].t1 = entry[reg1[1]].tag;           
                    map_rs[1].t2 = entry[reg2[1]].tag;
                if((cdb[0].complete && (entry[reg1[1]].tag == cdb[0].p)) || (cdb[1].complete && (entry[reg1[1]].tag == cdb[1].p))) begin
                    map_rs[1].t1_enable = 1;
                end
                else begin
                    map_rs[1].t1_enable = entry[reg1[1]].ready;
                end
                if((cdb[0].complete && (entry[reg2[1]].tag == cdb[0].p)) || (cdb[1].complete && (entry[reg2[1]].tag == cdb[1].p))) begin
                    map_rs[1].t2_enable = 1;
                end
                else begin
                    map_rs[1].t2_enable = entry[reg2[0]].ready;
                end      
            end
        end
        else begin
            map_rs[1] = 0;
        end       
 end

//update entry
always_comb begin
    nentry = entry;
    //rollback

    //dispatch
    for(int o = 0; o <`WIDTH; o++) begin
        if(write_en[o]) begin
            nentry[destreg[o]].tag = T[o];
            if(destreg[o] == `ZERO_REG) begin
            nentry[destreg[o]].ready = 1;
            end
            else begin
            nentry[destreg[o]].ready = 0;
            end
        end
    end
    //cdb
    for(int k =0; k <`WIDTH; k++) begin
        if(cdb[k].complete) begin
            for(int q = 0; q<`RF_SIZE; q++) begin
                if(nentry[q].tag == cdb[k].p) begin
                    nentry[q].ready = 1;
                end
            end
        end
    end
end

always_ff@(posedge clock) begin
    if(reset) begin
        for(int s = 0; s<`RF_SIZE; s++ ) begin
            entry[s].tag <= s;
            entry[s].ready <= 1;
         //   nentry[s].ready <= 1;
         //   nentry[s].tag <= s;

        end
    end
    else if(rollback_en)begin
        if(exception_en) begin
           for(int h = 0; h<`RF_SIZE; h++ ) begin
            entry[h].tag <=rec_tag[h];
            entry[h].ready <= 1;
            end
           end
        else begin 
        for(int h = 0; h<`RF_SIZE; h++ ) begin
            if(h != rollback_reg) begin
            entry[h].tag <=rec_tag[h];
            entry[h].ready <= 1;
            end
            else begin
            entry[h].tag <=rollback_tag;
            entry[h].ready <= 1;
            end
          //  nentry[h].tag <=rec_tag[h];
          //  nentry[h].ready <= 1;
        end
    end
    end
    else begin
        entry <= nentry;
    end
end

endmodule 
            











    