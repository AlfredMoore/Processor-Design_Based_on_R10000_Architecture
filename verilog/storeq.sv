module storequeue(
    input clock,
    input reset,
    input rollback,
    //from decode
    input logic [`WIDTH-1:0] storeen,

    input logic [`WIDTH-1:0] loaden,

    //from ex
    input logic [`WIDTH-1:0] sten,
    input logic [`WIDTH-1:0][$clog2(`SQ_SIZE)-1:0] update_sqp,
    input logic [`WIDTH-1:0] [`XLEN-1:0] storeaddress,
    input logic [`WIDTH-1:0] [`XLEN-1:0] storedata,
    input logic [`WIDTH-1:0] [2:0] st_memsize,
    //input logic [`WIDTH-1:0]
    input logic [$clog2(`SQ_SIZE)-1:0] load_sqp,
    input logic [`XLEN-1:0] loadaddress,
    input logic lden,
    //from rob
    input logic retireen,
    input storecomplete,

    //to ex ld  
    output logic [`XLEN-1:0] forwarddata,
    output logic forwarden,

    output logic storeing,
    output logic [`XLEN-1:0] wrdata,
    output logic [`XLEN-1:0] wraddress,
    output logic [2:0] wrmemsize,

    output logic [`WIDTH-1:0][$clog2(`SQ_SIZE)-1:0] sqp,

    output logic [`WIDTH-1:0] full
);

sq [`SQ_SIZE-1:0] entry;
sq [`SQ_SIZE-1:0] nentry;
logic [$clog2(`SQ_SIZE)-1:0] head_pointer;
logic [$clog2(`SQ_SIZE)-1:0] tail_pointer;
logic [$clog2(`SQ_SIZE)-1:0] nhead_pointer;
logic [$clog2(`SQ_SIZE)-1:0] ntail_pointer;
logic [$clog2(`SQ_SIZE)-1:0] htdistance;



always_comb begin
		htdistance = head_pointer - tail_pointer;
        full = 2'b11;
		if(tail_pointer < head_pointer) begin
			if(htdistance == 1) begin
                if((storeing && storecomplete) || (retireen && storecomplete)&& !storeen) begin
                    full = 2'b01;
                end
                else begin
				    full = 2'b0;
                end
			end
			else if(htdistance == 2) begin
                if(storeen[0] && storeen [1]) begin
                    full = 2'b00;
                end
                else if(storeen[0] || storeen[1]) begin
                    if((storeing && storecomplete) || (retireen && storecomplete)) begin
                        full = 2'b01;
                    end
                    else begin
                        full = 2'b00;
                    end
                end
                else if(!storeen)begin
                    if((storeing && storecomplete) || (retireen && storecomplete)) begin
				        full =  2'b11;
                    end
                    else begin
                        full = 2'b01;
                    end
                end
			end
			else if(htdistance == 3) begin
                if(storeen[0] && storeen[1]) begin
                    if((storeing && storecomplete) || (retireen && storecomplete)) begin
                        full = 2'b01;
                    end
                    else begin
                        full = 2'b0;
                    end
                end
                else if(storeen[0] || storeen[1]) begin
                    if((storeing && storecomplete) || (retireen && storecomplete)) begin
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
		end
		else  begin
            if(tail_pointer == `SQ_SIZE-1) begin
                if(head_pointer == 0) begin
                    if((storeing && storecomplete) || (retireen && storecomplete))begin
                        if(storeen) begin
                            full = 2'b00;
                        end
                        else begin
                            full = 2'b01;
                        end
                    end
                    else begin
                        full = 2'b00;
                    end
                end
                else if( head_pointer == 1) begin
                    if((storeing && storecomplete) || (retireen && storecomplete)) begin
                        if(storeen[0] && storeen[1]) begin
                            full = 2'b00;
                        end
                        else if(storeen) begin
                            full = 2'b01;
                        end
                        else begin
                            full = 2'b11;
                        end
                    end
                    else begin
                        if(storeen) begin
                            full = 2'b00;
                        end
                        else begin
                            full = 2'b01;
                        end
                    end
                end
                else if(head_pointer == 2) begin
                    if((storeing && storecomplete) || (retireen && storecomplete)) begin
                        if(storeen[0] && storeen[1]) begin
                            full = 2'b01;
                        end
                        else begin
                            full = 2'b11;
                        end
                    end
                    else begin
                        if(storeen[0] && storeen[1]) begin
                            full =2'b0;
                        end
                        else if(storeen) begin
                            full = 2'b01;
                        end
                        else begin
                            full = 2'b11;
                        end
                    end
                end
                else full = 2'b11;
            end
            else if(tail_pointer == `SQ_SIZE-2) begin
                if(head_pointer == 0) begin
                    if((storeing && storecomplete) || (retireen && storecomplete)) begin
                        if(storeen == 2'b11) begin
                            full = 2'b00;
                        end
                        else if(storeen ) begin
                            full = 2'b01;
                        end
                        else full = 2'b11;
                    end
                    else begin
                        if(storeen) begin
                            full = 2'b0;
                        end
                        else begin
                            full = 2'b01;
                        end
                    end
                end
                else if(head_pointer == 1) begin
                    if((storeing && storecomplete) || (retireen && storecomplete)) begin
                        if(storeen == 2'b11) begin
                            full = 2'b01;
                        end
                        else full = 2'b11;
                    end
                    else begin
                        if(storeen == 2'b11) begin
                            full = 2'b00;
                        end
                        else if(storeen) begin
                            full = 2'b01;
                        end
                        else full =2'b11;
                    end
                end
                else full =2'b11;
            end
            else if(tail_pointer == `SQ_SIZE-3) begin
                if(head_pointer == 0) begin
                    if((storeing && storecomplete) || (retireen && storecomplete)) begin
                        if(storeen == 2'b11) begin
                            full = 2'b01;
                        end
                        else full = 2'b11;
                    end
                    else begin
                        if(storeen == 2'b11) begin
                            full = 2'b00;
                        end
                        else if(storeen) begin
                            full = 2'b01;
                        end
                        else full = 2'b11;
                    end
                end
                else if(head_pointer == 1) begin
                    if((storeing && storecomplete) || (retireen && storecomplete)) begin
                        full = 2'b11;
                    end
                    else begin
                        if(storeen == 2'b11) begin
                            full =2'b01;
                        end
                        else full = 2'b11;
                    end
                end
            end
                else full = 2'b11;
        end
    end

//forward
always_comb begin
    forwarden = 0;
    forwarddata = 0;
    if(lden) begin
        if(sten[0]) begin
        if(loadaddress == storeaddress[0]) begin
            forwarddata = storedata[0];
            forwarden = 1;
        end
        else begin
            if(load_sqp > head_pointer) begin
                for(int q = 0; q<`SQ_SIZE; q++) begin
                    if(q >=head_pointer && q < load_sqp && entry[q].address == loadaddress && entry[q].valid) begin
                        forwarddata = entry[q].data;
                        forwarden = 1;
                    end
                end
            end
            else if(load_sqp < head_pointer) begin
                for(int q = 0;q<`SQ_SIZE; q++) begin
                    if((q>=head_pointer || q < load_sqp) && entry[q].address == loadaddress && entry[q].valid) begin
                        forwarddata = entry[q].data;
                        forwarden = 1;
                    end
                end
            end
            else if(load_sqp == head_pointer) begin
                forwarddata = 0;
                forwarden = 0;
            end
        end
        end
        else begin
            if(load_sqp > head_pointer) begin
                for(int q = 0; q<`SQ_SIZE; q++) begin
                    if(q >=head_pointer && q < load_sqp && entry[q].address == loadaddress && entry[q].valid) begin
                        forwarddata = entry[q].data;
                        forwarden = 1;
                    end
                end
            end
            else if(load_sqp < head_pointer) begin
                for(int q = 0;q<`SQ_SIZE; q++) begin
                    if((q>=head_pointer || q < load_sqp) && entry[q].address == loadaddress && entry[q].valid) begin
                        forwarddata = entry[q].data;
                        forwarden = 1;
                    end
                end
            end
            else if(load_sqp == head_pointer) begin
                forwarddata = 0;
                forwarden = 0;
            end
        end
    end
    else begin // no load
        forwarddata = 0;
        forwarden = 0;
    end
end

                    


always_comb begin
    nentry =entry;
    //update
    if(storeing && storecomplete || (retireen && storecomplete)) begin // retire 
        nentry[head_pointer] =0;
        if(head_pointer == `SQ_SIZE-1) begin
            nhead_pointer = 0;
        end
        else begin
            nhead_pointer = head_pointer +1;
        end
    if(sten[1] && sten[0]) begin
        nentry[update_sqp[0]].address = storeaddress[0];
        nentry[update_sqp[0]].valid = 1;
        nentry[update_sqp[0]].data = storedata[0];
        nentry[update_sqp[0]].st_memsize = st_memsize[0];

        nentry[update_sqp[1]].address = storeaddress[1];
        nentry[update_sqp[1]].valid = 1;
        nentry[update_sqp[1]].data = storedata[1];
        nentry[update_sqp[1]].st_memsize = st_memsize[1];
    end
    else if(sten[0]) begin
        nentry[update_sqp[0]].address = storeaddress[0];
        nentry[update_sqp[0]].valid = 1;
        nentry[update_sqp[0]].data = storedata[0];
        nentry[update_sqp[0]].st_memsize = st_memsize[0];
    end
    else if(sten[1]) begin
        nentry[update_sqp[1]].address = storeaddress[1];
        nentry[update_sqp[1]].valid = 1;
        nentry[update_sqp[1]].data = storedata[1];
        nentry[update_sqp[1]].st_memsize = st_memsize[1];
    end
    end
    else begin // no retire 
        nhead_pointer = head_pointer;
        if(sten[1] && sten[0]) begin
        nentry[update_sqp[0]].address = storeaddress[0];
        nentry[update_sqp[0]].valid = 1;
        nentry[update_sqp[0]].data = storedata[0];
        nentry[update_sqp[0]].st_memsize = st_memsize[0];
        nentry[update_sqp[1]].address = storeaddress[1];
        nentry[update_sqp[1]].valid = 1;
        nentry[update_sqp[1]].data = storedata[1];
        nentry[update_sqp[1]].st_memsize = st_memsize[1];
    end
    else if(sten[0]) begin
        nentry[update_sqp[0]].address = storeaddress[0];
        nentry[update_sqp[0]].valid = 1;
        nentry[update_sqp[0]].data = storedata[0];
        nentry[update_sqp[0]].st_memsize = st_memsize[0];
    end
    else if(sten[1]) begin
        nentry[update_sqp[1]].address = storeaddress[1];
        nentry[update_sqp[1]].valid = 1;
        nentry[update_sqp[1]].data = storedata[1];
        nentry[update_sqp[1]].st_memsize = st_memsize[1];
    end
    end

end

//retire store
always_comb begin 
    if(retireen || storeing) begin
        wrdata = entry[head_pointer].data;
        wraddress = entry[head_pointer].address;
        wrmemsize = entry[head_pointer].st_memsize;
    end
    else begin
        wrdata = 0;
        wraddress = 0;
        wrmemsize = 0;
    end
end


always_comb begin
    //add
    sqp=0;
    if(storeen[0] && storeen[1]) begin //2 str
        if(tail_pointer == `SQ_SIZE-2) begin
            sqp[0] = tail_pointer;
            sqp[1] = tail_pointer + 1;
            ntail_pointer = 0;
        end
        else if(tail_pointer == `SQ_SIZE-1) begin
            ntail_pointer = 1;
            sqp[0] = tail_pointer;
            sqp[1] = 0;
        end
        else begin
            ntail_pointer = tail_pointer + 2;
            sqp[0] = tail_pointer;
            sqp[1] = tail_pointer + 1;
        end
    end
    else if(storeen[0] && !storeen[1]) begin // str 1st
        sqp[0] = tail_pointer;
        if(loaden[1]) begin
        if(tail_pointer == `SQ_SIZE-1) begin
            ntail_pointer = 0;
            sqp[1] = 0;
        end
        else begin
            ntail_pointer = tail_pointer +1;
            sqp[1] = tail_pointer + 1;
        end
        end
        else begin
        sqp[1] = 0;
        if(tail_pointer == `SQ_SIZE-1) begin
            ntail_pointer = 0;
        end
        else begin
            ntail_pointer = tail_pointer +1;
        end

    end
    end
    else if(storeen[1] && !storeen[0]) begin //str 2nd
        sqp[1] = tail_pointer;
        if(loaden[0]) begin
            sqp[0] = tail_pointer;
        if(tail_pointer == `SQ_SIZE-1) begin
            ntail_pointer = 0;
        end
        else begin
            ntail_pointer = tail_pointer +1;
        end
        end
        else begin
            sqp[0] = 0;
        if(tail_pointer == `SQ_SIZE-1) begin
            ntail_pointer = 0;
        end
        else begin
            ntail_pointer = tail_pointer +1;
        end
        end
    end
    else begin //str none
        ntail_pointer = tail_pointer;
        if(loaden[0] && loaden[1]) begin
            sqp[0] = tail_pointer;
            sqp[1] = tail_pointer;
        end
        else if(loaden[0] && !loaden[1]) begin
            sqp[0] = tail_pointer;
            sqp[1] = 0;
        end
        else if(!loaden[0] && loaden[1])begin
            sqp[1] = tail_pointer;
            sqp[0] = 0;
        end
    end

end


//
always_ff@(posedge clock) begin
    if(reset || rollback) begin
        entry <= 0;
        head_pointer <= 0;
        tail_pointer <= 0;
        storeing <= 0;
    end
    else begin
        entry <= nentry;
        head_pointer <= nhead_pointer;
        tail_pointer <= ntail_pointer;
    end
    if(retireen && !storecomplete) begin
        storeing <= 1;
    end
    else if(storeing && storecomplete) begin
        storeing <= 0;
    end
end
endmodule







