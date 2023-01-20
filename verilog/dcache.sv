



module dcache(
    input clock,
    input reset,
    input rollback,
    input lden,
    input retirest,
    input storeing,
    input forwarden,
    input [3:0] Dmem2proc_response,
    input [63:0] Dmem2proc_data,
    input [3:0]  Dmem2proc_tag,
    input cleancache,

    input [`XLEN-1:0] loadaddress,
    input [`XLEN-1:0] storeaddress,
    input [`XLEN-1:0] storedata,
    input [2:0] storememsize,
    //to mem
    output logic [1:0] proc2Dmem_command,
    output logic [63:0] proc2Dmem_data,
    output logic [`XLEN-1:0] proc2Dmem_addr,
    output logic [1:0] clean_command,
    output logic [63:0] clean_data,
    output logic [`XLEN-1:0] clean_addr,
    //to ex
    output CACHE_BLOCK Dcache_data_out,
    output logic Dcache_valid_out,
    output logic clean,
    output logic [`CACHE_LINES-1:0]empty
);
DCACHE_PACKET [`CACHE_LINES-1:0] dcache_data;
logic [`CACHE_LINE_BITS - 1:0] current_index, last_index;
logic [28 - `CACHE_LINE_BITS:0] current_tag, last_tag; // 12 since only 16 bits of address is used - thus 0 to 15 -> 3 bits block offset
logic [31:0] address;
logic [15:0] cycles_left;
logic [3:0] current_mem_tag;
logic miss_outstanding;
logic changed_addr;
logic data_write_enable;
logic unanswered_miss; // no found 
logic update_mem_tag;
logic [`CACHE_LINE_BITS-1:0] cleannum;
assign {current_tag, current_index} = loadaddress[31:3] | storeaddress[31:3];
assign address   = {loadaddress[31:3],3'b0} | {storeaddress[31:3],3'b0};


//logic storemiss;
//logic loadmiss;

assign update_mem_tag = (changed_addr && (lden || retirest)) || miss_outstanding || data_write_enable ;

assign changed_addr = (current_index != last_index) || (current_tag != last_tag);

assign data_write_enable = (current_mem_tag == Dmem2proc_tag) && (current_mem_tag != 0) && (cycles_left == 0);

assign unanswered_miss = (lden||retirest) ? !Dcache_valid_out && ((lden&&(!forwarden)) || retirest):
                                            miss_outstanding && (Dmem2proc_response == 0);
assign Dcache_data_out = dcache_data[current_index].data;
assign Dcache_valid_out = dcache_data[current_index].valids && (dcache_data[current_index].tags == current_tag);


//to mem
always_comb begin
    proc2Dmem_addr = 0;
    proc2Dmem_command = BUS_NONE;
    proc2Dmem_data = 0;
    if(retirest) begin
        if(dcache_data[current_index].valids && (dcache_data[current_index].tags != current_tag) ) begin //al
            proc2Dmem_command =  BUS_STORE;
            proc2Dmem_addr = {dcache_data[current_index].tags,current_index,3'b0};
            proc2Dmem_data = dcache_data[current_index].data;
        end
        else begin // no al
            proc2Dmem_command =  BUS_NONE;
        end
    end
    else if(lden && !forwarden) begin
        if(dcache_data[current_index].valids && (dcache_data[current_index].tags != current_tag)) begin
            proc2Dmem_command =  BUS_STORE;
            proc2Dmem_addr = {dcache_data[current_index].tags,current_index,3'b0};
            proc2Dmem_data = dcache_data[current_index].data;
        end
        else begin
            proc2Dmem_command =  BUS_NONE;
        end
    end
    else begin
            proc2Dmem_command = (miss_outstanding && !changed_addr) ?  BUS_LOAD : BUS_NONE;
            proc2Dmem_addr = {address[31:3],3'b0};
    end
end

    always_comb begin
        empty = {(`CACHE_LINES){1'b1}};
        cleannum = 0;
        for(int c = 0; c<`CACHE_LINES; c++) begin
            if( dcache_data[c].valids) begin
                empty[c] = 1;
                cleannum = c;
            end
            else begin
                empty[c] = 0;
                cleannum = cleannum;
            end
        end
    end

            
    // synopsys sync_set_reset "reset"
    always_ff @(posedge clock) begin
        if(reset) begin
            last_index       <= -1;   // These are -1 to get ball rolling when
            last_tag         <= -1;   // reset goes low because addr "changes"
            current_mem_tag  <=  0;
            miss_outstanding <=  0;
            dcache_data      <=  0; 
            cycles_left      <=  0; 
            clean_command   <= BUS_NONE;
            clean <= 0;
        end
        else if(cleancache || clean) begin
            last_index       <= -1;   // These are -1 to get ball rolling when
            last_tag         <= -1;   // reset goes low because addr "changes"
            current_mem_tag  <=  0;
            miss_outstanding <=  0;
            cycles_left      <=  0; 
            clean <=1;
            
                if(empty != 0)begin
                    clean_addr <= {dcache_data[cleannum].tags,cleannum,3'b0};
                    clean_command <= BUS_STORE;
                    clean_data <= dcache_data[cleannum].data;
                    dcache_data[cleannum] <= 0;
                end
                else begin
                    clean_addr <= 0;
                    clean_command <= BUS_NONE;
                    clean_data <= 0;
                end
            end  
     
        else begin
            last_index              <=  current_index;
            last_tag                <=  current_tag;
            miss_outstanding        <=  unanswered_miss;


            if(rollback) begin
                cycles_left <= `MEM_LATENCY_IN_CYCLES;
            end
            else if(cycles_left > 0) begin
                cycles_left <= cycles_left - 1;
            end

            if(update_mem_tag) begin
                current_mem_tag     <=  Dmem2proc_response;
            end


            
            
            if(retirest ) begin
                dcache_data[current_index].valids <=1;
                if(!dcache_data[current_index].valids) begin    
                    dcache_data[current_index].tags   <=current_tag;                
                    case (storememsize)
                    BYTE: dcache_data[current_index].data.bytes[storeaddress[2:0]] <= storedata[7:0];
                    HALF: dcache_data[current_index].data.halves[storeaddress[2:1]] <= storedata[15:0];
                    WORD: dcache_data[current_index].data.words[storeaddress[2]] <= storedata[31:0];
                    default: dcache_data[current_index].data.words[storeaddress[2]] <= storedata[31:0];
                    endcase
                end
                else if(dcache_data[current_index].tags == current_tag) begin
                    case(storememsize)
                    BYTE: dcache_data[current_index].data.bytes[storeaddress[2:0]] <= storedata[7:0];
                    HALF: dcache_data[current_index].data.halves[storeaddress[2:1]] <= storedata[15:0];
                    WORD: dcache_data[current_index].data.words[storeaddress[2]] <= storedata[31:0];
                    default: dcache_data[current_index].data.words[storeaddress[2]] <= storedata[31:0];
                    endcase
                end
            end
            else if(data_write_enable ) begin // If data came from memory, meaning tag matches
                dcache_data[current_index].data     <=  Dmem2proc_data;
                dcache_data[current_index].tags     <=  current_tag;
                dcache_data[current_index].valids   <=  1;
                if(storeing) begin               
                case(storememsize)
                BYTE:  dcache_data[current_index].data.bytes[storeaddress[2:0]] <= storedata[7:0];
                HALF:  dcache_data[current_index].data.halves[storeaddress[2:1]] <= storedata[15:0];
                WORD:  dcache_data[current_index].data.words[storeaddress[2]] <= storedata[31:0];
                default:  dcache_data[current_index].data.words[storeaddress[2]] <= storedata[31:0];
                endcase
            end
            end


        end
        
    end

    endmodule