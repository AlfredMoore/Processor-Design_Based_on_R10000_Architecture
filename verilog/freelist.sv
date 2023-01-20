`timescale 1ns/100ps

module freelist(
    input clock,
    input reset,
    input logic [`WIDTH-1:0] disp_en,
    input ROB_FL_packet [`WIDTH-1:0] rob_pack,
    input rollback_en,
    input logic [$clog2(`ROB_SIZE)-1:0] recover_head,
    output logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] freeT

    
);

logic [`FL_SIZE-1 :0] [$clog2(`PRF_SIZE)-1:0] entry, nentry;
logic [$clog2(`FL_SIZE)-1:0]  head, tail;
logic [$clog2(`FL_SIZE)-1:0]  nhead, ntail; 

always_comb begin
    ntail = tail;
    
    nentry = entry;

    //retire
    for(int b = 0; b<`WIDTH; b++) begin
        if(rob_pack[b].retire_en) begin
            nentry[ntail] = rob_pack[b].t_hold;
            if(ntail == `FL_SIZE-1) begin
                ntail = 0;
            end
            else begin
            ntail = ntail + 1;
            end
        end
    end
end
always_comb begin
    //dispatch
    nhead = head;
    for(int c = 0; c<`WIDTH; c++)begin
        if(disp_en[c]) begin
            freeT[c] = entry[nhead];
            if(nhead == `FL_SIZE-1) begin
                nhead = 0;
            end
            else begin
            nhead = nhead + 1;
            end
        end
    end
end

    always_ff@(posedge clock) begin
        if(reset) begin
            for(int i = 0; i<`FL_SIZE; i++) begin
                entry[i] <= i + `FL_SIZE;
            end
            head <= 0;
            tail <= 0;
        end
        else if(rollback_en)begin
            head <= recover_head;
            tail <= tail;
        end
        else begin
            head <= nhead;
            tail <= ntail;
            entry <= nentry;
        end
    end
    

endmodule