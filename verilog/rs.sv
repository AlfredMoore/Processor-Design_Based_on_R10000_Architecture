`timescale 1ns/100ps

module rs(
    input clock,
    input reset,
    //input from map table, preg tags for input regs
    input MapT_RS_packet [`WIDTH-1:0] mapt,
    //rollback
    input logic rollback,

    //input from free list, new preg for output reg 
    input logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0]  t,

    //input from lq and sq
    input logic [`WIDTH-1:0] [$clog2(`LQ_SIZE)-1:0] lqp,
    input logic [`WIDTH-1:0] [$clog2(`SQ_SIZE)-1:0] sqp,
    //input from decoder
    input ID_PACKET [`WIDTH-1:0] id_packet,
    input logic [`WIDTH-1:0] write_en,  
    //input from ex
    //input EX_RS_packet [`WIDTH-1:0] freepack,
    //input from cdb
    input CDB [`WIDTH-1:0] cdb,


    input logic loading,
    input storeing,
    input storeretire,
    //to maptable
   // output logic [`WIDTH-1:0] [$clog2(`RF_SIZE)-1:0] rs1,
    //output logic [`WIDTH-1:0] [$clog2(`RF_SIZE)-1:0] rs2,

    output toissue_packet [`WIDTH-1:0] iss,//issue packet
    output logic    [`WIDTH-1:0]    full //to decoder 
  //  output RS_entry [(`RS_SIZE)-1:0] testentry
);

RS_entry [(`RS_SIZE)-1:0] entry ;
//logic   [`RS_SIZE-1:0]  fill = 8'b00000000;
logic [$clog2(`RS_SIZE):0]     num;
logic [$clog2(`RS_SIZE):0]     nnum;
logic [1:0] emptynum;
//logic [1:0] nemptynum;
logic [`WIDTH-1:0][$clog2(`RS_SIZE):0] emptyp;
//logic [`WIDTH-1:0][$clog2(`RS_SIZE):0] nemptyp;
logic [(`RS_SIZE)-1:0] update;
logic [(`RS_SIZE)-1:0] is;
logic isload;
//logic   add;
logic   issnum;
logic   reorder;
//logic [1:0] iss_num;
RS_entry [(`RS_SIZE)-1:0] nentry ;
//int     r;
//logic [(`RS_SIZE)-1:0] issue_complete;
//logic [(`RS_SIZE)-1:0] nissue_complete;

assign full = (nnum == 8)? 2'b00 :(nnum == 7)? 2'b01 : 2'b11;
//issue
always_comb begin
    iss = 0;
    emptynum =0;
    emptyp = 0;
    is = 0;
    isload = 0;
    if(cdb[0].complete && cdb[1].complete) begin
        for(int q = 0; q<`WIDTH; q++) begin
            issnum = 0;
           
            for(int w = 0; w<`RS_SIZE; w++) begin
                if((entry[w].issue_en || (entry[w].T1_enable && (entry[w].T2 == cdb[0].p || entry[w].T2 == cdb[1].p))
                || (entry[w].T2_enable && (entry[w].T1 == cdb[0].p || entry[w].T1 == cdb[1].p))
                || (entry[w].T1 == entry[w].T2 && (entry[w].T2 == cdb[0].p || entry[w].T2 == cdb[1].p))
                || ((entry[w].T1 == cdb[0].p || entry[w].T1 == cdb[1].p) && (entry[w].T2 == cdb[0].p || entry[w].T2 == cdb[1].p)))
                && (!issnum) && entry[w].busy && !is[w] && !(entry[w].rspack.rd_mem && (loading||storeing||storeretire)) && !(isload && entry[w].rspack.rd_mem)) begin
                    iss[q].T = entry[w].T;
                    iss[q].T1 = entry[w].T1;
                    iss[q].T2 = entry[w].T2;
                    iss[q].rspack1 = entry[w].rspack;
                    iss[q].lqp = entry[w].lqp;
                    iss[q].sqp = entry[w].sqp;
                    emptyp[q] = w;
                    
                    emptynum = emptynum + 1;
                    is[w] = 1;
                    issnum = 1;
                    if(entry[w].rspack.rd_mem) begin
                        isload = 1;
                    end
                end
            end
        end
    end
    else if(cdb[0].complete && !cdb[1].complete) begin
        for(int q = 0; q<`WIDTH; q++) begin
            issnum = 0;
            for(int w = 0; w<`RS_SIZE; w++) begin
                if((entry[w].issue_en || (entry[w].T1_enable && (entry[w].T2 == cdb[0].p ))
                || (entry[w].T2_enable && (entry[w].T1 == cdb[0].p))
                || (entry[w].T1 == entry[w].T2 && (entry[w].T2 == cdb[0].p)))
                && (!issnum) && entry[w].busy && !is[w] && !(entry[w].rspack.rd_mem && (loading||storeing||storeretire)) && !(isload && entry[w].rspack.rd_mem)) begin
                    iss[q].T = entry[w].T;
                    iss[q].T1 = entry[w].T1;
                    iss[q].T2 = entry[w].T2;
                    iss[q].rspack1 = entry[w].rspack;
                    iss[q].lqp = entry[w].lqp;
                    iss[q].sqp = entry[w].sqp;
                    emptyp[q] = w;
                    emptynum = emptynum + 1;
                    is[w] = 1;
                    issnum = 1;
                    if(entry[w].rspack.rd_mem) begin
                        isload = 1;
                    end
                end
            end
        end
    end
    else if(cdb[1].complete && !cdb[0].complete) begin
        for(int q = 0; q<`WIDTH; q++) begin
            issnum = 0;
            for(int w = 0; w<`RS_SIZE; w++) begin
                if((entry[w].issue_en || (entry[w].T1_enable && (entry[w].T2 == cdb[1].p ))
                || (entry[w].T2_enable && (entry[w].T1 == cdb[1].p))
                || (entry[w].T1 == entry[w].T2 && (entry[w].T2 == cdb[1].p)))
                && (!issnum) && entry[w].busy && !is[w] && !(entry[w].rspack.rd_mem && (loading||storeing||storeretire)) && !(isload && entry[w].rspack.rd_mem)) begin
                    iss[q].T = entry[w].T;
                    iss[q].T1 = entry[w].T1;
                    iss[q].T2 = entry[w].T2;
                    iss[q].rspack1 = entry[w].rspack;
                    iss[q].lqp = entry[w].lqp;
                    iss[q].sqp = entry[w].sqp;
                    emptyp[q] = w;
                    emptynum = emptynum + 1;
                    is[w] = 1;
                    issnum = 1;
                    if(entry[w].rspack.rd_mem) begin
                        isload = 1;
                    end
                end
            end
        end
    end
    else begin
        for(int q = 0; q<`WIDTH; q++) begin
            issnum = 0;
            for(int w = 0; w<`RS_SIZE; w++) begin
                if((entry[w].issue_en)
                && (!issnum) && entry[w].busy && !is[w] && !(entry[w].rspack.rd_mem && (loading||storeing||storeretire)) && !(isload && entry[w].rspack.rd_mem)) begin
                    iss[q].T = entry[w].T;
                    iss[q].T1 = entry[w].T1;
                    iss[q].T2 = entry[w].T2;
                    iss[q].rspack1 = entry[w].rspack;
                    iss[q].lqp = entry[w].lqp;
                    iss[q].sqp = entry[w].sqp;
                    emptyp[q] = w;
                    emptynum = emptynum + 1;
                    is[w] = 1;
                    issnum = 1;
                    if(entry[w].rspack.rd_mem) begin
                        isload = 1;
                    end
                end
            end
        end
    end
end

always_comb begin
    nentry = 0;
    update = 0;
    if(!write_en) begin 
            if(emptynum == 2) begin // 2 free
            nnum = num - 2;
              for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && emptyp[0] != b && emptyp[1] != b && !reorder && !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end// free 2 add 0   
            else if(emptynum == 1) begin
                nnum = num -1;
                for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && emptyp[0] != b && !reorder && !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end    
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end//free 1 add 0
            else if(emptynum == 0) begin
                nnum = num;
                for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && !reorder&& !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end//free 0 add 0
    end
    else if(write_en[0] && !write_en[1]) begin
        if(emptynum == 2) begin // 2 free
            nnum = num - 1;
            nentry[num-2].T1 = mapt[0].t1;
            nentry[num-2].T2 = mapt[0].t2;
            nentry[num-2].T1_enable = mapt[0].t1_enable;
            nentry[num-2].T2_enable = mapt[0].t2_enable;
            nentry[num-2].T = t[0];
            nentry[num-2].issue_en = mapt[0].t1_enable && mapt[0].t2_enable;
            nentry[num-2].rspack = id_packet[0];
            nentry[num-2].busy = 1'b1;
            nentry[num-2].lqp = lqp[0];
            nentry[num-2].sqp = sqp[0];
              for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && emptyp[0] != b && emptyp[1] != b && !reorder && !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end// free 2 add 1   
            else if(emptynum == 1) begin
                nnum = num;
                nentry[num-1].T1 = mapt[0].t1;
                nentry[num-1].T2 = mapt[0].t2;
                nentry[num-1].T1_enable = mapt[0].t1_enable;
                nentry[num-1].T2_enable = mapt[0].t2_enable;
                nentry[num-1].T = t[0];
                nentry[num-1].issue_en = mapt[0].t1_enable && mapt[0].t2_enable;
                nentry[num-1].rspack = id_packet[0];
                nentry[num-1].busy = 1'b1;
                nentry[num-1].lqp = lqp[0];
                nentry[num-1].sqp = sqp[0];
                for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && emptyp[0] != b && !reorder && !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end//free 1 add 1
            else if(emptynum == 0) begin
                nnum = num + 1;
                nentry[num].T1 = mapt[0].t1;
                nentry[num].T2 = mapt[0].t2;
                nentry[num].T1_enable = mapt[0].t1_enable;
                nentry[num].T2_enable = mapt[0].t2_enable;
                nentry[num].T = t[0];
                nentry[num].issue_en = mapt[0].t1_enable && mapt[0].t2_enable;
                nentry[num].rspack = id_packet[0];
                nentry[num].busy = 1'b1;
                nentry[num].lqp = lqp[0];
                nentry[num].sqp = sqp[0];
                for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && !reorder && !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end
            end//free 0 add 1
        else if(!write_en[0] && write_en[1]) begin
            if(emptynum == 2) begin // 2 free
            nnum = num - 1;
            nentry[num-2].T1 = mapt[1].t1;
            nentry[num-2].T2 = mapt[1].t2;
            nentry[num-2].T1_enable = mapt[1].t1_enable;
            nentry[num-2].T2_enable = mapt[1].t2_enable;
            nentry[num-2].T = t[1];
            nentry[num-2].issue_en = mapt[1].t1_enable && mapt[1].t2_enable;
            nentry[num-2].rspack = id_packet[1];
            nentry[num-2].busy = 1'b1;
            nentry[num-2].lqp = lqp[1];
            nentry[num-2].sqp = sqp[1];
              for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && emptyp[0] != b && emptyp[1] != b && !reorder && !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end// free 2 add 1   
            else if(emptynum == 1) begin
                nnum = num;
                nentry[num-1].T1 = mapt[1].t1;
                nentry[num-1].T2 = mapt[1].t2;
                nentry[num-1].T1_enable = mapt[1].t1_enable;
                nentry[num-1].T2_enable = mapt[1].t2_enable;
                nentry[num-1].T = t[1];
                nentry[num-1].issue_en = mapt[1].t1_enable && mapt[1].t2_enable;
                nentry[num-1].rspack = id_packet[1];
                nentry[num-1].busy = 1'b1;
                nentry[num-1].lqp = lqp[1];
                nentry[num-1].sqp = sqp[1];
                for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && emptyp[0] != b && !reorder && !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end//free 1 add 1
            else if(emptynum == 0) begin
                nnum = num + 1;
                nentry[num].T1 = mapt[1].t1;
                nentry[num].T2 = mapt[1].t2;
                nentry[num].T1_enable = mapt[1].t1_enable;
                nentry[num].T2_enable = mapt[1].t2_enable;
                nentry[num].T = t[1];
                nentry[num].issue_en = mapt[1].t1_enable && mapt[1].t2_enable;
                nentry[num].rspack = id_packet[1];
                nentry[num].busy = 1'b1;
                nentry[num].lqp = lqp[1];
                nentry[num].sqp = sqp[1];
                for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && !reorder && !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end
        end//free 0 add 1
        else if(write_en[0] && write_en[1]) begin // add 2
            if(emptynum == 2) begin // 2 free
            nnum = num ;
            nentry[num-1].T1 = mapt[1].t1;
            nentry[num-1].T2 = mapt[1].t2;
            nentry[num-1].T1_enable = mapt[1].t1_enable;
            nentry[num-1].T2_enable = mapt[1].t2_enable;
            nentry[num-1].T = t[1];
            nentry[num-1].issue_en = mapt[1].t1_enable && mapt[1].t2_enable;
            nentry[num-1].rspack = id_packet[1];
            nentry[num-1].busy = 1'b1;
            nentry[num-1].lqp = lqp[1];
            nentry[num-1].sqp = sqp[1];
            nentry[num-2].T1 = mapt[0].t1;
            nentry[num-2].T2 = mapt[0].t2;
            nentry[num-2].T1_enable = mapt[0].t1_enable;
            nentry[num-2].T2_enable = mapt[0].t2_enable;
            nentry[num-2].T = t[0];
            nentry[num-2].issue_en = mapt[0].t1_enable && mapt[0].t2_enable;
            nentry[num-2].rspack = id_packet[0];
            nentry[num-2].busy = 1'b1;
            nentry[num-2].lqp = lqp[0];
            nentry[num-2].sqp = sqp[0];
              for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && emptyp[0] != b && emptyp[1] != b && !reorder && !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end// free 2 add 2   
            else if(emptynum == 1) begin
                nnum = num + 1;
            nentry[num].T1 = mapt[1].t1;
            nentry[num].T2 = mapt[1].t2;
            nentry[num].T1_enable = mapt[1].t1_enable;
            nentry[num].T2_enable = mapt[1].t2_enable;
            nentry[num].T = t[1];
            nentry[num].issue_en = mapt[1].t1_enable && mapt[1].t2_enable;
            nentry[num].rspack = id_packet[1];
            nentry[num].busy = 1'b1;
            nentry[num].lqp = lqp[1];
            nentry[num].sqp = sqp[1];
            nentry[num-1].T1 = mapt[0].t1;
            nentry[num-1].T2 = mapt[0].t2;
            nentry[num-1].T1_enable = mapt[0].t1_enable;
            nentry[num-1].T2_enable = mapt[0].t2_enable;
            nentry[num-1].T = t[0];
            nentry[num-1].issue_en = mapt[0].t1_enable && mapt[0].t2_enable;
            nentry[num-1].rspack = id_packet[0];
            nentry[num-1].busy = 1'b1;
            nentry[num-1].lqp = lqp[0];
            nentry[num-1].sqp = sqp[0];
                for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && emptyp[0] != b && !reorder && !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end//free 1 add 2
            else if(emptynum == 0) begin
                nnum = num + 2;
            nentry[num+1].T1 = mapt[1].t1;
            nentry[num+1].T2 = mapt[1].t2;
            nentry[num+1].T1_enable = mapt[1].t1_enable;
            nentry[num+1].T2_enable = mapt[1].t2_enable;
            nentry[num+1].T = t[1];
            nentry[num+1].issue_en = mapt[1].t1_enable && mapt[1].t2_enable;
            nentry[num+1].rspack = id_packet[1];
            nentry[num+1].busy = 1'b1;
            nentry[num+1].lqp = lqp[1];
            nentry[num+1].sqp = sqp[1];
            nentry[num].T1 = mapt[0].t1;
            nentry[num].T2 = mapt[0].t2;
            nentry[num].T1_enable = mapt[0].t1_enable;
            nentry[num].T2_enable = mapt[0].t2_enable;
            nentry[num].T = t[0];
            nentry[num].issue_en = mapt[0].t1_enable && mapt[0].t2_enable;
            nentry[num].rspack = id_packet[0];
            nentry[num].busy = 1'b1;
            nentry[num].lqp = lqp[0];
            nentry[num].sqp = sqp[0];
                for(int a = 0; a <`RS_SIZE; a ++) begin // reorder entry from 0 
                reorder = 0;
                for(int b = 0; b <`RS_SIZE; b ++) begin
                    if(entry[b].busy && !reorder && !update[b]) begin
                        nentry[a] = entry[b];
                        reorder = 1;
                        update[b] = 1;
                        if(cdb[0].complete && cdb[1].complete)begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p || entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p || entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[0].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[0].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[0].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[0].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                        else if(cdb[1].complete) begin
                        if(entry[b].T2 == entry[b].T1 && (entry[b].T2 == cdb[1].p)) begin
                            nentry[a].issue_en = 1;
                        end
                        else if(entry[b].T1 == cdb[1].p) begin
                            nentry[a].T1_enable = 1;
                            nentry[a].issue_en = (entry[b].T2_enable)? 1'b1:1'b0;
                        end
                        else if(entry[b].T2 == cdb[1].p) begin
                            nentry[a].T2_enable = 1;
                            nentry[a].issue_en = (entry[b].T1_enable)? 1'b1:1'b0;
                        end
                        end
                    end
                end
              end
            end
        end//free 0 add 2
end






// synopsys sync_set_reset "reset"
always_ff@(posedge clock) begin 
    if(reset || rollback) begin
        entry <=  0;
        num <= 0;
        //emptynum <= 0;
        //emptyp <= 0;
       // issue_complete <= 0;
    end
    else begin
        entry <=  nentry;
        num <= nnum;
        //emptynum <= nemptynum;
       // emptyp <= nemptyp;
       // issue_complete <= nissue_complete;
end 
end
endmodule






                


