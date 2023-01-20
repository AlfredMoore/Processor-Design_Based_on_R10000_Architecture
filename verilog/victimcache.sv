module victimcache (
    input clock,
    input reset,
    input ICACHE_PACKET  icache_vdata,
    input victimen,
    input [`CACHE_LINE_BITS - 1:0] victimidx,
    input [`XLEN-1:0] proc2Vcache_addr,


    output logic [63:0] Vcache_data_out, // value is memory[proc2Icache_addr]
    output logic Vcache_valid_out 
);
VCACHE_PACKET [3:0] vcache;
logic [`CACHE_LINE_BITS - 1:0] current_index;
logic [12 - `CACHE_LINE_BITS:0] current_tag;

assign {current_tag, current_index} = proc2Vcache_addr[15:3];
assign Vcache_valid_out = vcache[current_index[1:0]].valids && (vcache[current_index[1:0]].tags == current_tag) && (vcache[current_index[1:0]].idx == current_index);
assign Vcache_data_out = vcache[current_index[1:0]].data;
always_ff@(posedge clock) begin
    if(reset) begin
        vcache <= 0;
    end
    else begin
        if(victimen) begin
            vcache[victimidx[1:0]].data <= icache_vdata.data;
            vcache[victimidx[1:0]].valids <= icache_vdata.valids;
            vcache[victimidx[1:0]].tags <= icache_vdata.tags;
            vcache[victimidx[1:0]].idx <= victimidx;
        end
    end
end
endmodule