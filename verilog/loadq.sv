module loadqueue(
    input clock,
    input reset,
    input rollback,
    //from decode
    input logic [`WIDTH-1:0] storeen,
    input logic [`WIDTH-1:0] loaden,
    input logic [`WIDTH-1:0] [`XLEN-1:0] ldpc,
    //from ex
    input logic [`WIDTH-1:0] sten,
    input logic [`WIDTH-1:0][$clog2(`LQ_SIZE)-1:0] store_lqp,
    input logic [`WIDTH-1:0] [`XLEN-1:0] storeaddress,
    //input logic [`WIDTH-1:0] [`XLEN-1:0] storedata,

    input logic [$clog2(`LQ_SIZE)-1:0] update_lqp,
    input logic [`XLEN-1:0] loadaddress,
    input logic lden,
    //from rob
    input logic [`WIDTH-1:0] retireld,
    input logic [`WIDTH-1:0][$clog2(`ROB_SIZE)-1:0] robnum,


    output logic [`WIDTH-1:0][$clog2(`LQ_SIZE)-1:0] lqp,
    output logic [`WIDTH-1:0] full,
    output logic [`LQ_SIZE-1:0][$clog2(`ROB_SIZE)-1:0] torobnum,
    output logic [`LQ_SIZE-1:0] [`XLEN-1:0] torobldpc,
    output logic [`LQ_SIZE-1:0] ldexception

);

lq [`LQ_SIZE-1:0] entry;
lq [`LQ_SIZE-1:0] nentry;
logic [$clog2(`LQ_SIZE)-1:0] head_pointer;
logic [$clog2(`LQ_SIZE)-1:0] tail_pointer;
logic [$clog2(`LQ_SIZE)-1:0] nhead_pointer;
logic [$clog2(`LQ_SIZE)-1:0] ntail_pointer;
logic [$clog2(`LQ_SIZE)-1:0] htdistance;

always_comb begin
		htdistance = head_pointer - tail_pointer;
		if(tail_pointer < head_pointer) begin
			if(htdistance == 1) begin
                if(retireld[0] && retireld[1] && !loaden) begin
                    full = 2'b11;
                end
                else if((retireld[0] || retireld[1]) && !loaden) begin
                    full = 2'b01;
                end
                else begin
				    full = 2'b0;
                end
			end
			else if(htdistance == 2) begin
                if(loaden[0] && loaden [1]) begin
                    full = 2'b00;
                end
                else if(loaden[0] || loaden[1]) begin
                    if(retireld[0] && retireld[1]) begin
                        full = 2'b11;
                    end
                    else if(retireld[0] || retireld[1]) begin
                        full = 2'b01;
                    end
                    else begin
                        full = 2'b0;
                    end
                end
                else if(!loaden)begin
                    if(retireld) begin
				        full =  2'b11;
                    end
                    else begin
                        full = 2'b01;
                    end
                end
			end
			else if(htdistance == 3) begin
                if(loaden[0] && loaden[1]) begin
                    if(retireld[0] && retireld[1]) begin
                        full = 2'b11;
                    end
                    else if(retireld[0] || retireld[1]) begin
                        full = 2'b01;
                    end
                    else begin
                        full = 2'b0;
                    end
                end
                else if(loaden[0] || loaden[1]) begin
                    if(retireld) begin
                        full = 2'b11;
                    end
                    else begin
                        full = 2'b01;
                    end
                end
                else begin
				    full = 2'b11;
                end
			end
            else begin
                full = 2'b11;
            end
		end
		else  begin
            if(tail_pointer == `LQ_SIZE-1) begin
                if(head_pointer == 0) begin
                    if(loaden == 2'b11) begin
                        full = 2'b00;
                    end
                    else if(loaden) begin
                        if(retireld == 2'b11) begin
                            full = 2'b01;
                        end
                        else full = 2'b00;
                    end
                    else begin
                        if(retireld == 2'b11) begin
                            full = 2'b11;
                        end
                        else if(retireld) begin
                            full = 2'b01;
                        end
                        else full = 2'b00;
                    end
                end
                if(head_pointer == 1) begin
                    if(loaden == 2'b11) begin
                        if(retireld == 2'b11) begin
                            full =2'b01;
                        end
                        else full =2'b00;
                    end
                    else if(loaden) begin
                        if(retireld == 2'b11) begin
                            full = 2'b11;
                        end
                        else if(retireld) begin
                            full = 2'b01;
                        end
                        else full = 2'b0;
                    end
                    else begin
                        if(retireld == 2'b11) begin
                            full = 2'b11;
                        end
                        else if(retireld) begin
                            full = 2'b11;
                        end
                        else full = 2'b01;
                    end
                end
                else if(head_pointer == 2) begin
                    if(loaden == 2'b11 && !retireld) begin
                        full = 2'b00;
                    end
                    else full = 2'b11;
                end
                else if(head_pointer == 3) begin
                    if(loaden == 2'b11 && !retireld) begin
                        full = 2'b01;
                    end
                    else full = 2'b11;
                end
            end
            else if(tail_pointer == `LQ_SIZE-2) begin
                if(head_pointer == 0) begin
                    if(loaden == 2'b11) begin
                        if(retireld == 2'b11)begin
                        full = 2'b01;
                        end
                        else full =2'b00;
                    end
                    else if(loaden) begin
                        if(retireld == 2'b11)begin
                        full = 2'b11;
                        end
                        else full =2'b01;
                    end
                    else begin
                        full =2'b01;
                    end
                end
                else if(head_pointer == 1) begin
                    if(loaden == 2'b11) begin
                        if(retireld == 2'b11)begin
                        full = 2'b11;
                        end
                        else full =2'b00;
                    end
                    else if(loaden) begin
                        if(retireld)begin
                        full = 2'b11;
                        end
                        else full =2'b01;
                    end
                    else begin
                        full =2'b11;
                    end
                end
                else if(head_pointer == 2) begin
                    if(loaden == 2'b11 && !retireld) begin
                        full = 2'b01;
                    end
                    else full =2'b11;
                end
                else full =2'b11;
            end
            else full =2'b11;

		end		
	end
//add and update retire
always_comb begin
    nentry =entry;
    //update
    if(retireld[0] && retireld[1]) begin // 2 retire 
        nentry[head_pointer] =0;
        if(head_pointer == `SQ_SIZE-2) begin
            nentry[`SQ_SIZE-1] = 0;
            nhead_pointer = 0;
        end
        else if(head_pointer == `SQ_SIZE-1) begin
            nentry[0] = 0;
            nhead_pointer = 1;
        end
        else begin
            nentry[head_pointer+1] = 0;
            nhead_pointer = head_pointer +2;
        end
    
    end
    else if(retireld[0] || retireld[1]) begin // 1 retire
        nentry[head_pointer] = 0;
        if(head_pointer == `SQ_SIZE-1) begin
            nhead_pointer = 0;
        end
        else begin
            nhead_pointer = head_pointer + 1;
        end
    end
    else begin
        nhead_pointer = head_pointer;
    end

    if(lden) begin
        nentry[update_lqp].valid = 1;
        nentry[update_lqp].address = loadaddress;
    end

    if(loaden[0] && loaden[1]) begin
        if(tail_pointer == `LQ_SIZE - 2)begin
            nentry[tail_pointer].pc = ldpc[0];
            nentry[tail_pointer].robnum = robnum[0];
            nentry[tail_pointer+1].pc = ldpc[1];
            nentry[tail_pointer+1].robnum = robnum[1];
            ntail_pointer = 0;
        end
        else if(tail_pointer == `LQ_SIZE -1)begin
            nentry[tail_pointer].pc = ldpc[0];
            nentry[tail_pointer].robnum = robnum[0];
            nentry[0].pc = ldpc[1];
            nentry[0].robnum = robnum[1];
            ntail_pointer = 1;
        end
        else begin
            nentry[tail_pointer].pc = ldpc[0];
            nentry[tail_pointer].robnum = robnum[0];
            nentry[tail_pointer+1].pc = ldpc[1];
            nentry[tail_pointer+1].robnum = robnum[1];
            ntail_pointer = tail_pointer + 2;
        end
    end
    else if(loaden[0] && !loaden[1]) begin
        nentry[tail_pointer].pc = ldpc[0];
        nentry[tail_pointer].robnum = robnum[0];
        if(tail_pointer == `LQ_SIZE -1) begin           
            ntail_pointer = 0;
        end
        else begin
            ntail_pointer = tail_pointer + 1;
        end
    end
    else if(!loaden[0] && loaden[1]) begin
        nentry[tail_pointer].pc = ldpc[1];
        nentry[tail_pointer].robnum = robnum[1];
        if(tail_pointer == `LQ_SIZE -1) begin           
            ntail_pointer = 0;
        end
        else begin
            ntail_pointer = tail_pointer + 1;
        end
    end
    else begin
        ntail_pointer = tail_pointer;
    end
end

always_comb begin
    torobnum = 0;
    ldexception = 0;
    torobldpc = 0;
    for(int a = 0; a<`WIDTH; a++) begin
        if(sten[a]) begin
            if(store_lqp[a]<tail_pointer)begin
            for(int b = 0; b <`LQ_SIZE; b++) begin
                if(b<tail_pointer && b>=store_lqp[a] && entry[b].valid && entry[b].address == storeaddress[a])begin
                    torobnum[b] = entry[b].robnum;
                    ldexception[b] = 1;
                    torobldpc[b] = entry[b].pc;
                end
            end
            end
            else if(store_lqp[a]>tail_pointer) begin
                for(int b = 0; b <`LQ_SIZE; b++) begin
                    if((b<tail_pointer || b>=store_lqp[a]) && entry[b].valid && entry[b].address == storeaddress[a])begin
                        torobnum[b] = entry[b].robnum;
                        ldexception[b] = 1;
                        torobldpc[b] = entry[b].pc;
                    end
                end
            end
            else if(store_lqp[a] == tail_pointer)begin
                if(entry[tail_pointer].valid && entry[tail_pointer].address == storeaddress[a])begin
                torobnum[tail_pointer] = entry[tail_pointer].robnum;
                ldexception[tail_pointer] = 1;
                torobldpc[tail_pointer] = entry[tail_pointer].pc;
                end
            end
        end
    end
end

always_comb begin
    lqp = 0;
    if(loaden[1] && loaden[0]) begin
        if(tail_pointer == `LQ_SIZE-1) begin
            lqp[0] = tail_pointer;
            lqp[1] = 0;
        end
        else begin
            lqp[0] = tail_pointer;
            lqp[1] = tail_pointer + 1;
        end
    end
    else if(loaden[0] && !loaden[1]) begin
        lqp[0] = tail_pointer;
        if(storeen[1]) begin
            if(tail_pointer == `LQ_SIZE-1) begin
            lqp[1] = 0;
            end
            else begin
                lqp[1] = tail_pointer + 1;
            end
        end
        else lqp[1] = 0;
    end
    else if(!loaden[0] && loaden[1])begin
        lqp[1] = tail_pointer;
        if(storeen[0]) begin
            lqp[0] = tail_pointer;
        end
        else begin
            lqp[0] = 0;
        end
    end
    else begin
        if(storeen[0] && storeen[1]) begin
            lqp[0] = tail_pointer;
            lqp[1] = tail_pointer;
        end
        else if(storeen[0] && !storeen[1]) begin
            lqp[0] = tail_pointer;
            lqp[1] = 0;
        end
        else if(!storeen[0] && storeen[1]) begin
            lqp[1] = tail_pointer;
            lqp[0] = 0;
        end
        else begin
            lqp = 0;
        end
    end
end

always_ff@(posedge clock) begin
    if(reset || rollback) begin
        entry <= 0;
        head_pointer <= 0;
        tail_pointer <= 0;
    end
    else begin
        entry <= nentry;
        head_pointer <= nhead_pointer;
        tail_pointer <= ntail_pointer;
    end
end
endmodule






        
            
