


module icache(
    input clock,
    input reset,
    input rollback,
    // from memory
    input [3:0]  Imem2proc_response,
    input [63:0] Imem2proc_data,
    input [3:0]  Imem2proc_tag,
    //form vcache
    input vcachehit,
    // from fetch stage
    input [`XLEN-1:0] proc2Icache_addr,
    input logic [1:0] proc2Dmem_command,
    // to memory
    output logic [1:0] proc2Imem_command,
    output logic [`XLEN-1:0] proc2Imem_addr,

    // to fetch stage
    output logic [63:0] Icache_data_out, // value is memory[proc2Icache_addr]
    output logic Icache_valid_out,       // when this is high

    //to vcache
    output logic victimen,
    output logic [`CACHE_LINE_BITS - 1:0] victimidx,
    output ICACHE_PACKET  icache_vdata
    );

    ICACHE_PACKET [`CACHE_LINES-1:0] icache_data;
    logic rollbackadd1;
    logic [15:0] cycles_left;
    logic [`CACHE_LINE_BITS - 1:0] current_index, last_index;
    logic [12 - `CACHE_LINE_BITS:0] current_tag, last_tag; // 12 since only 16 bits of address is used - thus 0 to 15 -> 3 bits block offset
    logic [2:0] current_two, last_two;
    assign {current_tag, current_index} = proc2Icache_addr[15:3];
    assign current_two  =  proc2Icache_addr[2:0];
    logic [3:0] current_mem_tag;
    logic miss_outstanding;

    logic data_write_enable;
    assign data_write_enable = (current_mem_tag == Imem2proc_tag) && (current_mem_tag != 0) && (cycles_left == 0);

    logic changed_addr;
    assign changed_addr = (current_index != last_index) || (current_tag != last_tag) || (current_two != last_two) || (rollbackadd1);

    logic update_mem_tag;
    assign update_mem_tag = changed_addr || miss_outstanding || data_write_enable;

    logic unanswered_miss; // no found 
    assign unanswered_miss = changed_addr ? !Icache_valid_out && !vcachehit:
                                            miss_outstanding && ((Imem2proc_response == 0) || (proc2Dmem_command != BUS_NONE));

    assign proc2Imem_addr    = {proc2Icache_addr[31:3],3'b0};
    assign proc2Imem_command = (miss_outstanding && !changed_addr && !rollback) ?  BUS_LOAD : BUS_NONE;

    assign Icache_data_out = icache_data[current_index].data;
    assign Icache_valid_out = icache_data[current_index].valids && (icache_data[current_index].tags == current_tag);

    always_comb begin
        if(data_write_enable) begin
            icache_vdata = icache_data[current_index];
            victimen = 1;
            victimidx = current_index;
        end
        else begin
            icache_vdata = 0;
            victimen = 0;
            victimidx = 0;
        end
    end


    // synopsys sync_set_reset "reset"
    always_ff @(posedge clock) begin
        if(reset) begin
            last_index       <= -1;   // These are -1 to get ball rolling when
            last_tag         <= -1;   // reset goes low because addr "changes"
            current_mem_tag  <=  0;
            miss_outstanding <=  0;
            icache_data      <=  0; 
            cycles_left      <=  0; 
            rollbackadd1     <= 0;
            last_two      <= -1;
        end else begin
            last_index              <=  current_index;
            last_tag                <=  current_tag;
            miss_outstanding        <=  unanswered_miss;
            last_two                <=  current_two;
            if(rollback) begin
                cycles_left <= `MEM_LATENCY_IN_CYCLES;
                rollbackadd1 <= 1;
                miss_outstanding    <= 0;
                current_mem_tag  <=  0;

            end
            else if(cycles_left > 0) begin
                rollbackadd1 <= 0;
                cycles_left <= cycles_left - 1;
            end

            if(update_mem_tag) begin
                current_mem_tag     <=  Imem2proc_response;
            end

            if(data_write_enable) begin // If data came from memory, meaning tag matches
                icache_data[current_index].data     <=  Imem2proc_data;
                icache_data[current_index].tags     <=  current_tag;
                icache_data[current_index].valids   <=  1;
            end
        end
    end

endmodule