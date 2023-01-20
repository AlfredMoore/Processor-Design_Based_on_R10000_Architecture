/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench.v                                         //
//                                                                     //
//  Description :  Testbench module for the verisimple pipeline;       //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

import "DPI-C" function void print_header(string str);
import "DPI-C" function void print_cycles();
import "DPI-C" function void print_stage(string div, int inst, int npc, int valid_inst);
import "DPI-C" function void print_reg(int wb_reg_wr_data_out_hi, int wb_reg_wr_data_out_lo,
                                       int wb_reg_wr_idx_out, int wb_reg_wr_en_out);
import "DPI-C" function void print_membus(int proc2mem_command, int mem2proc_response,
                                          int proc2mem_addr_hi, int proc2mem_addr_lo,
						 			     int proc2mem_data_hi, int proc2mem_data_lo);
import "DPI-C" function void print_close();


module testbench;
	logic [63:0] tb_mem [`MEM_64BIT_LINES-1:0];
	// variables used in the testbench
	logic        clock;
	logic        reset;
	logic  		waitforone;
	
	
	logic [`XLEN-1:0] proc2mem_addr;
	logic [3:0]  mem2proc_tag;
	logic [3:0] mem2proc_response;
	logic [63:0] mem2proc_data;
	logic [1:0] proc2mem_command;
	logic [63:0] proc2mem_data;

	
	//logic [`WIDTH-1:0][`XLEN-1:0] if_NPC_out;
	//logic [`WIDTH-1:0][31:0] if_IR_out;
	//logic   [`WIDTH-1:0]     if_valid_inst_out;
	logic [`CACHE_LINES-1:0]empty;
	logic clean;
    //counter used for when pipeline infinite loops, forces termination
	logic [31:0] clock_count;
	logic [31:0] instr_count;
	logic  [1:0] pipeline_completed_insts;
	EXCEPTION_CODE  [`WIDTH-1:0] pipeline_error_status;
    logic [63:0] debug_counter;
	int          wb_fileno;
	// Instantiate the Pipeline
	pipeline pipeline(
		// Inputs
		.clock             (clock),
		.reset             (reset),
	
		.mem2proc_data     (mem2proc_data),
		.Imem2proc_tag		(mem2proc_tag),
		.Imem2proc_response (mem2proc_response),
		.proc2mem_data   (proc2mem_data),
		// Outputs
		.proc2Imem_command (proc2mem_command),
		.proc2mem_addr     (proc2mem_addr),
		.pipeline_error_status(pipeline_error_status),
		.pipeline_completed_insts(pipeline_completed_insts),
		.clean(clean),
		.empty(empty)

		
	);
	mem memory (
		// Inputs
		.clk               (clock),
		.proc2mem_command  (proc2mem_command),
		.proc2mem_addr     (proc2mem_addr),
		.proc2mem_data     (proc2mem_data),
`ifndef CACHE_MODE
		.proc2mem_size     (proc2mem_size),
`endif

		// Outputs

		.mem2proc_response (mem2proc_response),
		.mem2proc_data     (mem2proc_data),
		.mem2proc_tag      (mem2proc_tag)
	);
	//assign mem2proc_data = tb_mem[proc2mem_addr[`XLEN-1:3]];

	// Generate System Clock
	always begin
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock;
	end

		// Count the number of posedges and number of instructions completed
	// till simulation ends
	always @(posedge clock) begin
		
		if(reset) begin
			clock_count <=  0;
			instr_count <=  0;
		
		end else begin
			clock_count <=  (clock_count + 1);
			instr_count <=  (instr_count + pipeline_completed_insts);
		end
	end  
	
		// Task to display # of elapsed clock edges
	task show_clk_count;
		real cpi;
		
		begin
			cpi = (clock_count + 1.0) / instr_count;
			$display("@@  %0d cycles / %0d instrs = %f CPI\n@@",
			          clock_count+1, instr_count, cpi);
			$display("@@  %4.2f ns total time to execute\n@@\n",
			          clock_count*`VERILOG_CLOCK_PERIOD);
		end
	endtask  // task show_clk_count 
		// Show contents of a range of Unified Memory, in both hex and decimal
	task show_mem_with_decimal;
		input [31:0] start_addr;
		input [31:0] end_addr;
		int showing_data;
		begin
			$display("@@@");
			showing_data=0;
			for(int k=start_addr;k<=end_addr; k=k+1)
				if (memory.unified_memory[k] != 0) begin
					$display("@@@ mem[%5d] = %x : %0d", k*8, memory.unified_memory[k], 
				                                            memory.unified_memory[k]);
					showing_data=1;
				end else if(showing_data!=0) begin
					$display("@@@");
					showing_data=0;
				end
			$display("@@@");
		end
	endtask  // task show_mem_with_decimal
	always@(posedge clock) begin
		if(clean && !empty) begin
			waitforone <= 1;
		end
		else begin
			waitforone <= 0;
		end
	end
	always @(negedge clock) begin
        if(reset) begin
			$display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
			         $realtime);
            debug_counter <= 0;
        end else begin
			
			if(clean && !empty && waitforone) begin
				$display("@@@ Unified Memory contents hex on left, decimal on right: ");
				show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
				$display("@@  %t : System halted\n@@", $realtime);
				$display("@@@ System halted on WFI instruction");
				$display("@@@\n@@");
				show_clk_count;
				print_close(); // close the pipe_print output file
				$fclose(wb_fileno);
				#100 $finish;
			end
			// deal with any halting conditions
			else if(pipeline_error_status[0] != NO_ERROR && pipeline_error_status[0] !=HALTED_ON_WFI) begin
				//$display("@@@ Unified Memory contents hex on left, decimal on right: ");
				//show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
				// 8Bytes per line, 16kB total
				$display("@@@ Unified Memory contents hex on left, decimal on right: ");
				show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
				$display("@@  %t : System halted\n@@", $realtime);
				
				case(pipeline_error_status[0])
					//LOAD_ACCESS_FAULT:  
					//	$display("@@@ System halted on memory error");
					HALTED_ON_WFI:          
						$display("@@@ System halted on WFI instruction");
					ILLEGAL_INST:
						$display("@@@ System halted on illegal instruction");
					default: 
						$display("@@@ System halted on unknown error code %x", 
							pipeline_error_status[0]);
				endcase
				$display("@@@\n@@");
				show_clk_count;
				print_close(); // close the pipe_print output file
				$fclose(wb_fileno);
				#100 $finish;
			end
			else if(pipeline_error_status[1] != NO_ERROR && pipeline_error_status[1] !=HALTED_ON_WFI) begin
				//$display("@@@ Unified Memory contents hex on left, decimal on right: ");
				//show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
				// 8Bytes per line, 16kB total
				$display("@@@ Unified Memory contents hex on left, decimal on right: ");
				show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
				$display("@@  %t : System halted\n@@", $realtime);
				
				case(pipeline_error_status[1])
					//LOAD_ACCESS_FAULT:  
					//	$display("@@@ System halted on memory error");
					HALTED_ON_WFI:          
						$display("@@@ System halted on WFI instruction");
					ILLEGAL_INST:
						$display("@@@ System halted on illegal instruction");
					default: 
						$display("@@@ System halted on unknown error code %x", 
							pipeline_error_status[1]);
				endcase
				$display("@@@\n@@");
				show_clk_count;
				print_close(); // close the pipe_print output file
				$fclose(wb_fileno);
				#100 $finish;
			end
			else if(debug_counter > 5000000) begin
				//$display("@@@ Unified Memory contents hex on left, decimal on right: ");
				//show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
				// 8Bytes per line, 16kB total
				$display("@@@ Unified Memory contents hex on left, decimal on right: ");
				show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
				$display("@@  %t : System halted\n@@", $realtime);
				$display("@@@ System halted on unknown error code " 
							);
		
				$display("@@@\n@@");
				show_clk_count;
				print_close(); // close the pipe_print output file
				$fclose(wb_fileno);
				#100 $finish;
			end

            debug_counter <= debug_counter + 1;
		end  // if(reset)   
	end 

initial begin
		//$dumpvars;
	
		clock = 1'b0;
		reset = 1'b0;
		
		// Pulse the reset signal
		$display("@@\n@@\n@@  %t  Asserting System reset......", $realtime);
		reset = 1'b1;
		@(posedge clock);
		@(posedge clock);
		
	    $readmemh("program.mem", memory.unified_memory);
		
		@(posedge clock);
		@(posedge clock);
		
		// This reset is at an odd time to avoid the pos & neg clock edges
		
		reset = 1'b0;
		$display("@@  %t  Deasserting System reset......\n@@\n@@", $realtime);
		
		wb_fileno = $fopen("writeback.out");
		
		//Open header AFTER throwing the reset otherwise the reset state is displayed
		//print_header("                                                                            D-MEM Bus &\n");
	//	print_header("Cycle:      IF      |     ID      |     EX      |     MEM     |     WB      Reg Result");
	end
	

endmodule  // module testbench
