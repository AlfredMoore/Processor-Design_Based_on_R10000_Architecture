`timescale 1ns/100ps

module fetch(
    input   clock,
    input   reset,
    input   rollback,
    input  [`XLEN-1:0]  exception,
	input  logic [`WIDTH-1:0] spare, //rs and rob structural harzard 
    input  [63:0] Imem2proc_data,          // Data coming back from instruction-memory
    input   [1:0] Dcache2memcommond,
   // input   lden,
    //from i cache
    input logic icachevalid,
   //from btb
    input logic [`WIDTH-1:0][`XLEN-1:0] tpc_btb,
    input logic [`WIDTH-1:0] hit,

    output logic [`WIDTH-1:0] branch, //to btb, branch or not
    output logic [`WIDTH-1:0] uncond,
    output logic [`WIDTH-1:0] [`XLEN-1:0] pc_btb,
    output logic [`WIDTH-1:0] [11:0] npc_btb,

   // output logic [`XLEN-1:0] jump, //to btb, jump or not
	output logic [`XLEN-1:0] proc2Imem_addr,    // Address sent to Instruction memory
	output IF_ID_PACKET [`WIDTH-1:0] if_packet_out         // Output data packet from IF going to ID,
);

   // logic   icachevalid_record;
	logic    [`XLEN-1:0] PC_reg;             // PC we are currently fetching
	//logic    [`WIDTH-1:0]  fetch_num; 
	//logic    [`XLEN-1:0] PC_plus_4;
	logic    [`XLEN-1:0] next_PC;
    IF_ID_PACKET [`WIDTH-1:0] temp_inst;
  //  logic   rollback_rec;
	//logic           PC_enable;
	
	assign proc2Imem_addr = PC_reg;
    always_comb begin
        if_packet_out = 0;
        if_packet_out[0].targetpc = tpc_btb[0];
        if_packet_out[1].targetpc = tpc_btb[1];
        if(rollback)begin
            next_PC = exception;
            if_packet_out[0] = 0;
            if_packet_out[1] = 0;
        end
        else if (spare[1])begin //fetch 2 
            if(!PC_reg[2]) begin // 2 inst
            
            if(branch[0]) begin
                if(hit[0]) begin // 0 take
                    
                    if(tpc_btb[0] == PC_reg + 4) begin //branch to inst 2
                        if_packet_out[0] = temp_inst[0];
                        if_packet_out[0].take = 1;
                        if_packet_out[1] = temp_inst[1];
                        if(branch[1] && hit[1]) begin // 2is branch and take
                        next_PC = tpc_btb[1];
                        if_packet_out[1].take = 1;
                        end
                        else begin // 2 no branch  or no take
                        next_PC = tpc_btb[0] + 4;
                        if_packet_out[1].take = 0;
                        end
                    end
                    else begin //clean inst 1 
                        if_packet_out[0] = temp_inst[0];
                        if_packet_out[0].take = 1;
                        if_packet_out[1] = 0;
                        next_PC = tpc_btb[0];
                    end
                end
                else begin // 0 not take
                    if_packet_out[0] = temp_inst[0];
                    if(branch[1]) begin
                        if(hit[1]) begin //1 take
                            next_PC = tpc_btb[1];
                            if_packet_out[1] = temp_inst[1];
                            if_packet_out[1].take = 1;
                        end
                        else begin // 1 not take
                            next_PC = PC_reg + 8;
                            if_packet_out[1] = temp_inst[1];
                        end
                    end
                    else begin // 1 no branch
                            next_PC = PC_reg + 8;
                            if_packet_out[1] = temp_inst[1];
                    end
                end
            end
            else begin // 0 no branch
                if_packet_out[0] = temp_inst[0];
                if(branch[1]) begin // 1 branch
                    if(hit[1]) begin // 1 take
                        next_PC = tpc_btb[1];
                        if_packet_out[1] = temp_inst[1];
                        if_packet_out[1].take = 1;
                    end
                    else begin // 1 not take
                        next_PC = PC_reg + 8;
                        if_packet_out[1] = temp_inst[1];                        
                    end
                end
                else begin // 1 not branch
                        next_PC = PC_reg + 8;
                        if_packet_out[1] = temp_inst[1];
                end
            end
        end
        else begin // fetch 2; pcreg[2] =1  ; inst1
             if(branch[0]) begin
                if(hit[0]) begin // 0 take
                if_packet_out[0] = temp_inst[0];
                if_packet_out[0].take = 1;
                next_PC = tpc_btb[0];
                end
                else begin
                if_packet_out[0] = temp_inst[0];
                if_packet_out[0].take = 0;
                next_PC = PC_reg + 4;
                end
             end
             else begin
                if_packet_out[0] = temp_inst[0];
                if_packet_out[0].take = 0;
                next_PC = PC_reg + 4; 
             end
        end 
                    
        end

        else if(spare[0])begin // only fetch 1 inst
            if_packet_out[0] = temp_inst[0];
            if_packet_out[1] = 0;
            if(branch[0]) begin // 0 branch
                if(hit[0]) begin // 0 take
                    next_PC = tpc_btb[0];
                    if_packet_out[0].take = 1;

                end
                else begin // 0 not take
                    next_PC = PC_reg + 4;
                    end
            end
            else begin // 0 not branch
                    next_PC = PC_reg + 4;
            end
        end
        else begin // fetch 0 inst
            next_PC = PC_reg;
            if_packet_out[0] = 0;
            if_packet_out[1] = 0;
        end
    end
    
    always_comb begin // temp inst
    temp_inst[0].take = 0;
    temp_inst[1].take = 0;
    if(Dcache2memcommond != BUS_NONE) begin
        temp_inst = 0;
    end
    else begin
    if(icachevalid)begin
        if(spare[1]) begin
            if(PC_reg[2]) begin
            temp_inst[1].inst = 0;
            temp_inst[1].valid = 0;
            temp_inst[1].PC = 0;
            temp_inst[1].NPC = 0;

            temp_inst[0].inst = Imem2proc_data[63:32];
            temp_inst[0].valid = 1;
            temp_inst[0].PC = PC_reg ;
            temp_inst[0].NPC = PC_reg + 4;
            end
            else begin
            temp_inst[0].inst = Imem2proc_data[31:0];
            temp_inst[0].valid = 1;
            temp_inst[0].PC = PC_reg ;
            temp_inst[0].NPC = PC_reg + 4;
            temp_inst[1].inst = Imem2proc_data[63:32];
            temp_inst[1].valid = 1;
            temp_inst[1].PC = PC_reg +4;
            temp_inst[1].NPC = PC_reg + 8;
            end   

        end
        else if(spare[0]) begin
            if(PC_reg[2]) begin
            temp_inst[0].inst = Imem2proc_data[63:32];
            temp_inst[0].valid = 1;
            temp_inst[0].PC = PC_reg;
            temp_inst[0].NPC = PC_reg + 4;

            temp_inst[1].inst = 0;
            temp_inst[1].valid = 0;
            temp_inst[1].PC = 0;   
            temp_inst[1].NPC = 0;
            end
            else begin
            temp_inst[0].inst = Imem2proc_data[31:0];
            temp_inst[0].valid = 1;
            temp_inst[0].PC = PC_reg;
            temp_inst[0].NPC = PC_reg + 4;

            temp_inst[1].inst = 0;
            temp_inst[1].valid = 0;
            temp_inst[1].PC = 0;   
            temp_inst[1].NPC = 0;  
            end 
        end
        else begin
            temp_inst[0].inst = 0;
            temp_inst[0].valid = 0;
            temp_inst[0].PC = 0;
            temp_inst[0].NPC = 0;

            temp_inst[1].inst = 0;
            temp_inst[1].valid = 0;
            temp_inst[1].PC = 0;
            temp_inst[1].NPC = 0;

        end
    end
    else begin
        temp_inst = 0;
    end
    end
    end


    always_comb begin
        branch = 0;
        uncond = 0;
        pc_btb = 0;
        npc_btb = 0;
        for(int p = 0; p<`WIDTH; p++)begin
            if(temp_inst[p].valid) begin
                if((temp_inst[p].inst[6:0] == `RV32_JALR_OP) || (temp_inst[p].inst[6:0] ==  `RV32_BRANCH) || (temp_inst[p].inst[6:0] == `RV32_JAL_OP)) begin
                    branch[p] = 1;
                    pc_btb[p] = temp_inst[p].PC;
                    npc_btb[p] = temp_inst[p].NPC[13:2];
                    if((temp_inst[p].inst[6:0] == `RV32_JAL_OP) || (temp_inst[p].inst[6:0] == `RV32_JALR_OP)) begin //uncond
                        uncond[p] = 1;
                    end
                    else begin
                        uncond[p] = 0;
                    end
                end
                else begin //no branch
                    branch[p] = 0;
                    pc_btb[p] = 0;
                    npc_btb[p] = 0;
                    uncond[p] = 0;

                end
            end
            else begin // no valid
                branch[p] = 0;
                pc_btb[p] = 0;
                npc_btb[p] = 0;
                uncond[p] = 0;
            end
            
        end
    end




    always_ff @(posedge clock) begin
		if (reset) begin
			PC_reg <=  0;  // must start with something
           // fetch_num <= 2'b11;
           //icachevalid_record <= 0;
        end
        else if(rollback) begin
            PC_reg <=  next_PC;
            //icachevalid_record <= 0;
        end
        else if(Dcache2memcommond != BUS_NONE) begin
            PC_reg <= PC_reg;
        end
        else if(icachevalid) begin
            PC_reg <= next_PC;
        end
           // rollback_rec <= 0;

	end

endmodule