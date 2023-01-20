`ifndef SYNTHESIS

//
// This is an automatically generated file from 
// dc_shell Version T-2022.03-SP3 -- Jul 12, 2022
//

// For simulation only. Do not modify.

module pipeline_svsim (

	input         clock,                    	input         reset,                    		input [63:0]  mem2proc_data,            		input  logic [3:0]  Imem2proc_tag,
	input  logic [3:0] Imem2proc_response,
	output logic [32-1:0] proc2mem_addr,      	output logic [63:0] proc2mem_data,      	output logic [1:0] proc2Imem_command,
	
	
	
				
	
				
	
					
	
					
	
					
	
					output logic  [1:0] pipeline_completed_insts,
	output  EXCEPTION_CODE 	[2-1:0]  pipeline_error_status,
	output logic clean,
	output logic [32-1:0]empty

);

		

  pipeline pipeline( {>>{ clock }}, {>>{ reset }}, {>>{ mem2proc_data }}, 
        {>>{ Imem2proc_tag }}, {>>{ Imem2proc_response }}, 
        {>>{ proc2mem_addr }}, {>>{ proc2mem_data }}, 
        {>>{ proc2Imem_command }}, {>>{ pipeline_completed_insts }}, 
        {>>{ pipeline_error_status }}, {>>{ clean }}, {>>{ empty }} );
endmodule
`endif
