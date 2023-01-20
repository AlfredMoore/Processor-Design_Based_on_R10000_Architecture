`timescale 1ns/100ps

module BTB(
    input clock,
    input reset,

    //from rob
    input ROB_BTB_packet [`WIDTH-1:0] rob_packet,
    //from fetch
    input logic [`WIDTH-1:0] branch_en,
    input logic [`WIDTH-1:0] uncond_en,
    input logic [`WIDTH-1:0] [`XLEN-1:0] pc,
    input logic [`WIDTH-1:0] [11:0] npc,

    //to rob
    //output  BTB_ROB_packet [`WIDTH-1:0] btb_rob_pack,

    //to fetch
    output logic [`WIDTH-1:0][`XLEN-1:0] tpc, //target pc
    output logic [`WIDTH-1:0] hit // take or not
   // output logic [`WIDTH-1:0] T // T or N
);
    BTB1 [`BTB_SIZE-1:0] entry;
    BTB1 [`BTB_SIZE-1:0] pentry;



//update btb
    always_comb begin
        entry = pentry;
      //  btb_rob_pack = 0;
     //   T = 0;
     
        for(int b =0; b<`WIDTH; b++) begin
            if(rob_packet[b].isbranch && (rob_packet[b].pc[19:10] == pentry[rob_packet[b].pc[9:2]].tag)) begin
               // entry[opc[b][9:2]].target = targetpc[b][13:2];
               if(rob_packet[b].uncond) begin
                entry[rob_packet[b].pc[9:2]].target = rob_packet[b].targetpc[13:2];
               end
               else begin
                if(rob_packet[b].mispredict) begin
                case(pentry[rob_packet[b].pc[9:2]].direction) 
                    2'b00 : begin entry[rob_packet[b].pc[9:2]].direction = 2'b01;
                                  entry[rob_packet[b].pc[9:2]].target = pentry[rob_packet[b].pc[9:2]].target; 
                                 end  
                    2'b01 : begin entry[rob_packet[b].pc[9:2]].direction = 2'b10;
                                  entry[rob_packet[b].pc[9:2]].target = rob_packet[b].targetpc[13:2]; 
                                 end                              
                    2'b10 : begin entry[rob_packet[b].pc[9:2]].direction = 2'b01;
                                  entry[rob_packet[b].pc[9:2]].target = rob_packet[b].targetpc[13:2]; 
                                 end                                   
                    2'b11 : begin entry[rob_packet[b].pc[9:2]].direction = 2'b10;
                                  entry[rob_packet[b].pc[9:2]].target = pentry[rob_packet[b].pc[9:2]].target; 
                                 end  
                endcase
                end
                else if(!rob_packet[b].mispredict) begin
                case(pentry[rob_packet[b].pc[9:2]].direction) 
                    2'b00 : begin entry[rob_packet[b].pc[9:2]].direction = 2'b00;
                                  entry[rob_packet[b].pc[9:2]].target = pentry[rob_packet[b].pc[9:2]].target; 
                                  end  
                    2'b01 : begin entry[rob_packet[b].pc[9:2]].direction = 2'b00;
                                  entry[rob_packet[b].pc[9:2]].target = pentry[rob_packet[b].pc[9:2]].target;  
                                  end  
                    2'b10 : begin entry[rob_packet[b].pc[9:2]].direction = 2'b11;
                                  entry[rob_packet[b].pc[9:2]].target = pentry[rob_packet[b].pc[9:2]].target;  
                                  end  
                    2'b11 : begin entry[rob_packet[b].pc[9:2]].direction = 2'b11;
                                  entry[rob_packet[b].pc[9:2]].target = pentry[rob_packet[b].pc[9:2]].target; 
                                  end                              
                endcase 
                end
            
            else begin
                entry[rob_packet[b].pc[9:2]] = pentry[rob_packet[b].pc[9:2]];
            end
            end  
            end      
        end

        for(int s = 0; s<`WIDTH; s++) begin //new branch
            if(branch_en[s]) begin
                if(!(pc[s][19:10] == pentry[pc[s][9:2]].tag)) begin
                    entry[pc[s][9:2]].tag = pc[s][19:10];
                    entry[pc[s][9:2]].target = npc[s];
                    if(uncond_en[s]) begin
                        entry[pc[s][9:2]].direction = 2'b11;
                    end
                    else begin
                        entry[pc[s][9:2]].direction = 2'b00;
                    end
                end
            end
        end

    end
    //fetch
    always_comb begin
        hit = 0;
        tpc = 0;
        for(int a = 0; a<`WIDTH; a++) begin
            if(branch_en[a]) begin
                if(pc[a][19:10] == pentry[pc[a][9:2]].tag) begin //no alias
                    for(int c = 0; c<`WIDTH; c++) begin
                    if((pc[a] == rob_packet[c].pc) && rob_packet[c].isbranch) begin // by pass
                        if(rob_packet[c].mispredict) begin
                           case(pentry[rob_packet[c].pc[9:2]].direction) 
                    2'b00 : begin hit[a] = 0;
                                  tpc[a] = {pc[a][31:14],pentry[pc[a][9:2]].target,pc[a][1:0]};  

                                  end  
                    2'b01 : begin hit[a] = 1;
                                  tpc[a] = {pc[a][31:14],rob_packet[c].targetpc[13:2],pc[a][1:0]};  

                                 end                              
                    2'b10 : begin hit[a] = 0;
                                  tpc[a] = {pc[a][31:14],rob_packet[c].targetpc[13:2],pc[a][1:0]};  

                                   end                                   
                    2'b11 : begin hit[a] = 1;
                                  tpc[a] = {pc[a][31:14],pentry[pc[a][9:2]].target,pc[a][1:0]};  

                                  end  
                endcase
                end
                else if(!rob_packet[c].mispredict) begin
                case(pentry[rob_packet[c].pc[9:2]].direction) 
                    2'b00 : begin hit[a] = 0;
                                  tpc[a] = {pc[a][31:14],pentry[pc[a][9:2]].target,pc[a][1:0]}; 
                                  end  
                    2'b01 : begin hit[a] = 0;
                                  tpc[a] = {pc[a][31:14],pentry[pc[a][9:2]].target,pc[a][1:0]}; 
                                  end  
                    2'b10 : begin hit[a] = 1;
                                  tpc[a] = {pc[a][31:14],pentry[pc[a][9:2]].target,pc[a][1:0]}; 
                                   end  
                    2'b11 : begin hit[a] = 1;
                                  tpc[a] = {pc[a][31:14],pentry[pc[a][9:2]].target,pc[a][1:0]}; 
                                 end                              
                    endcase
                    end
                  end
                else begin //no bypass
                    case(pentry[pc[a][9:2]].direction) 
                    2'b00 : begin hit[a] = 0;
                                  tpc[a] = {pc[a][31:14],pentry[pc[a][9:2]].target,pc[a][1:0]}; 
                                  end  
                    2'b01 : begin hit[a] = 0;
                                  tpc[a] = {pc[a][31:14],pentry[pc[a][9:2]].target,pc[a][1:0]}; 
                                  end  
                    2'b10 : begin hit[a] = 1;
                                  tpc[a] = {pc[a][31:14],pentry[pc[a][9:2]].target,pc[a][1:0]}; 
                                   end  
                    2'b11 : begin hit[a] = 1;
                                  tpc[a] = {pc[a][31:14],pentry[pc[a][9:2]].target,pc[a][1:0]}; 
                                 end    
                    endcase 
                end
                    end
                end

                
                else begin //al
                    hit[a] = 0;
                    tpc[a] = {pc[a][31:14],npc[a],pc[a][1:0]};
                end
            end
            else begin
                hit[a] = 0;
                tpc[a] = 0;
            end
        
        end
    end

    always_ff@(posedge clock) begin
        if(reset) begin
            pentry <= 0;
        end
        else begin
            pentry <= entry;
        end
    end

        endmodule