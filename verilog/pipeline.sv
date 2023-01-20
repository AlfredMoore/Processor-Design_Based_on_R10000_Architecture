/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.v                                          //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline togeather.                      //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __PIPELINE_V__
`define __PIPELINE_V__

`timescale 1ns/100ps

module pipeline (

	input         clock,                    // System clock
	input         reset,                    // System reset
	//input [3:0]   mem2proc_response,        // Tag from memory about current request
	input [63:0]  mem2proc_data,            // Data coming back from memory
	//input [3:0]   mem2proc_tag,              // Tag from memory about current reply
	input  logic [3:0]  Imem2proc_tag,
	input  logic [3:0] Imem2proc_response,
//	output logic [1:0]  proc2mem_command,    // command sent to memory
	output logic [`XLEN-1:0] proc2mem_addr,      // Address sent to memory
	output logic [63:0] proc2mem_data,      // Data sent to memory
//	output MEM_SIZE proc2mem_size,          // data size sent to memory
	output logic [1:0] proc2Imem_command,
	/*output logic [3:0]  pipeline_completed_insts,
	output EXCEPTION_CODE   pipeline_error_status,
	output logic [4:0]  pipeline_commit_wr_idx,
	output logic [`XLEN-1:0] pipeline_commit_wr_data,
	output logic        pipeline_commit_wr_en,
	output logic [`XLEN-1:0] pipeline_commit_NPC,*/
	
	
	// testing hooks (these must be exported so we can test
	// the synthesized version) data is tested by looking at
	// the final values in memory
	
	
	// Outputs from IF-Stage 
	//output logic [`WIDTH-1:0][`XLEN-1:0] if_NPC_out,
	//output logic [`WIDTH-1:0][31:0] if_IR_out,
	//output logic  [`WIDTH-1:0]      if_valid_inst_out,

	
	// Outputs from IF/ID Pipeline Register
	//output logic [`XLEN-1:0] if_id_NPC,
	//output logic [31:0] if_id_IR,
	//output logic        if_id_valid_inst,
	
	
	// Outputs from ID/EX Pipeline Register
	//output logic [`XLEN-1:0] id_ex_NPC,
	//output logic [31:0] id_ex_IR,
	//output logic        id_ex_valid_inst,
	
	
	// Outputs from EX/MEM Pipeline Register
	//output logic [`XLEN-1:0] ex_mem_NPC,
	//output logic [31:0] ex_mem_IR,
	//output logic        ex_mem_valid_inst,
	
	
	// Outputs from MEM/WB Pipeline Register
	//output logic [`XLEN-1:0] mem_wb_NPC,
	//output logic [31:0] mem_wb_IR,
	//output logic        mem_wb_valid_inst
	output logic  [1:0] pipeline_completed_insts,
	output  EXCEPTION_CODE 	[`WIDTH-1:0]  pipeline_error_status,
	output logic clean,
	output logic [`CACHE_LINES-1:0]empty

);

	// Pipeline register enables
	logic   if_id_enable, issue_ex_enable, complete_enable;
	
	// Outputs from IF-Stage
	logic [`XLEN-1:0] proc2Imem_addr;
	IF_ID_PACKET [`WIDTH-1:0] if_packet;

	// Outputs from IF/ID Pipeline Register
	IF_ID_PACKET [`WIDTH-1:0] if_id_packet;

	// Outputs from ID stage
	ID_PACKET [`WIDTH-1:0] id_packet;

	// Outputs from ID/EX Pipeline Register
	logic [`XLEN-1:0] proc2Icache_addr;
	//logic [1:0] proc2Imem_command;
	//logic [`XLEN-1:0] proc2Imem_addr;
	logic [63:0] Icache_data_out;
	logic Icache_valid_out;
	logic [`WIDTH-1:0] [`XLEN-1:0] val1;
	logic [`WIDTH-1:0] [`XLEN-1:0] val2;
	logic [`WIDTH-1:0] [`XLEN-1:0] ret;
	logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] t_retire;
	logic [`WIDTH-1:0] retire_en;
	CDB [`WIDTH-1:0] cdb;
	logic [`WIDTH-1:0] [`XLEN-1:0] val;
	logic [`WIDTH-1:0] branchornot;
	logic [`WIDTH-1:0] uncond;
	logic [`WIDTH-1:0] [`XLEN-1:0]pc_btb;
	logic [`WIDTH-1:0] [11:0]npc_btb;
	logic [`WIDTH-1:0] disp_enable;
	logic [`WIDTH-1:0] [$clog2(`RF_SIZE)-1:0] destreg;
	logic [`WIDTH-1:0] [$clog2(`RF_SIZE)-1:0] rs1;
	logic [`WIDTH-1:0] [$clog2(`RF_SIZE)-1:0] rs2;
	toissue_packet [`WIDTH-1:0] iss;
	logic [$clog2(`RF_SIZE)-1:0] rollback_reg;
	logic    [`WIDTH-1:0]    full_rs;
	logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] t1;
	logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] t2;
	I_EX_packet  [`WIDTH-1:0] issue_packet;
	EX_C_packet [`WIDTH-1:0] c_packet;
	EX_ROB_packet [`WIDTH-1:0]  to_rob;
	//EX_RS_packet [`WIDTH-1:0] free_packet;
	//	MapT_ARF_packet [`WIDTH-1:0]  retire_toarf;
	logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] T_hold;
	MapT_RS_packet [`WIDTH-1:0] map_rs;
    logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0]freeT;
	ROB_BTB_packet [`WIDTH-1:0] tobtb_packet;
	ROB_FL_packet [`WIDTH-1:0] tofl_packet;
	ROB_PRF_packet [`WIDTH-1:0] toprf_packet;
	logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] thold_retire;
	logic rollback_en;
	logic [$clog2(`ROB_SIZE)-1:0] recover_head;
	logic [`XLEN-1:0]  exception_pc;
	logic [`WIDTH-1:0] full_rob;
	logic [`WIDTH-1:0][`XLEN-1:0] tpc;
	logic [`WIDTH-1:0] hit;
    logic [`WIDTH-1:0][4:0]  wr_idx;
	logic [`WIDTH-1:0]     wr_en;
	logic [31:0] [$clog2(`PRF_SIZE)-1:0] recover_tag;
	// Outputs from MEM-Stage
	logic [`XLEN-1:0] Icache2mem_addr;
	logic [1:0] Icache2mem_command;


	logic [1:0]  proc2Dmem_command;
	//MEM_SIZE proc2Dmem_size;


	

	logic [1:0] spare1;
	logic [1:0] spare2;
	logic [1:0] spare;
	

	logic [`WIDTH-1:0] illegal;
	logic [`WIDTH-1:0]	halt;
	logic [`WIDTH-1:0] robretire_halt;
	logic [`WIDTH-1:0] robretire_illegal;
	logic [`XLEN-1:0] forwarddata;
logic forwarden;
logic [`XLEN-1:0] wrdata;
logic [`XLEN-1:0] wraddress;
logic [1:0] sqfull;
	logic [`WIDTH-1:0][$clog2(`LQ_SIZE)-1:0] lqp;
	logic [`WIDTH-1:0][$clog2(`SQ_SIZE)-1:0] sqp;
			logic [`WIDTH-1:0][$clog2(`ROB_SIZE)-1:0] robnum;
		logic [`WIDTH-1:0] loadretire;
		logic storeretire;
			logic [`LQ_SIZE-1:0] ldexception;
	logic [`LQ_SIZE-1:0][$clog2(`ROB_SIZE)-1:0] torobnum;
logic [`LQ_SIZE-1:0] [`XLEN-1:0] torobldpc;
logic [`WIDTH-1:0] storeen;
logic [`WIDTH-1:0] loaden;
logic [`WIDTH-1:0] sten;
logic lden;
logic [`WIDTH-1:0] [`XLEN-1:0] ldpc;
logic [1:0] lqfull;
logic [`WIDTH-1:0][$clog2(`LQ_SIZE)-1:0] store_lqp;
logic [`WIDTH-1:0][$clog2(`SQ_SIZE)-1:0] store_sqp;
 logic [`WIDTH-1:0] [`XLEN-1:0] storeaddress;
logic [`WIDTH-1:0] [`XLEN-1:0] storedata;
logic [$clog2(`LQ_SIZE)-1:0] load_lqp;
 logic [$clog2(`SQ_SIZE)-1:0] load_sqp;
logic [`XLEN-1:0] loadaddress;
logic loading;
logic storeing;
//logic [`XLEN-1:0] dcache2procdata;
logic [2:0] wrmemsize;
logic [`WIDTH-1:0] [2:0] st_memsize;
logic cleancache;
 logic [63:0] proc2Dmem_data;
 logic [`XLEN-1:0] proc2Dmem_addr;
CACHE_BLOCK Dcache_data_out;
 logic Dcache_valid_out;
 logic [1:0] clean_command;
logic [63:0] clean_data;
logic [`XLEN-1:0] clean_addr;
logic [$clog2(`PRF_SIZE)-1:0] rollback_tag;
ICACHE_PACKET  icache_vdata;
logic victimen;
logic [`CACHE_LINE_BITS - 1:0] victimidx;
logic  [63:0] Vcache_data_out;
logic Vcache_valid_out;
	logic icachevalid;
	logic [63:0] cacheinst;
	//assign pipeline_completed_insts = {3'b0, mem_wb_valid_inst};
	always_comb begin
			pipeline_error_status[0] =  NO_ERROR;
			pipeline_error_status[1] =  NO_ERROR;
			cleancache = 0;
		for(int k = 0; k<`WIDTH; k++) begin
			if(robretire_illegal[k]) begin
				 pipeline_error_status[k] =  ILLEGAL_INST;
			end
			else if(robretire_halt[k]) begin
				//pipeline_error_status[k] = HALTED_ON_WFI;
				cleancache = 1;
			end
			else begin
				pipeline_error_status[k] = NO_ERROR;
			end
		end
	end
	 
	//assign pipeline_commit_wr_idx = wb_reg_wr_idx_out;
	//assign pipeline_commit_wr_data = wb_reg_wr_data_out;
	//assign pipeline_commit_wr_en = wb_reg_wr_en_out;
	//assign pipeline_commit_NPC = mem_wb_NPC;
	always_comb begin
		if(clean_command != BUS_NONE) begin
			proc2mem_addr = clean_addr;
			proc2mem_data = clean_data;
			proc2Imem_command = clean_command;
		end
		else if(proc2Dmem_command != BUS_NONE) begin
			proc2mem_addr = proc2Dmem_addr;
			proc2mem_data = proc2Dmem_data;
			proc2Imem_command = proc2Dmem_command;
		end
		else if(Icache2mem_command != BUS_NONE)  begin
			proc2mem_addr = Icache2mem_addr;
			proc2Imem_command = Icache2mem_command;
			proc2mem_data = 0;
		end
		else begin
			proc2mem_addr = 0;
			proc2Imem_command = BUS_NONE;
			proc2mem_data = 0;
		end
	end


	//assign proc2mem_command =
	 //    (proc2Dmem_command == BUS_NONE) ? BUS_LOAD : proc2Dmem_command;
	//assign proc2mem_addr = proc2Imem_addr;
	   //  (proc2Dmem_command == BUS_NONE) ?  : proc2Dmem_addr;
	//if it's an instruction, then load a double word (64 bits)
//	assign proc2mem_size =
	//     (proc2Dmem_command == BUS_NONE) ? DOUBLE : proc2Dmem_size;
	//assign proc2mem_data = {32'b0, proc2Dmem_data};
	assign spare1 = full_rob & full_rs;
	assign spare2 = sqfull & lqfull;
	assign spare = spare1 & spare2;
	always_comb begin
		if(tofl_packet[0].retire_en && tofl_packet[1].retire_en) begin
			if(robretire_halt) begin
				pipeline_completed_insts = 2'b01;
			end
			else begin
			pipeline_completed_insts = 2'b10;
			end
		end
		else if(tofl_packet[0].retire_en || tofl_packet[1].retire_en) begin
			if(robretire_halt) begin
			pipeline_completed_insts = 2'b0;
			end
			else
			pipeline_completed_insts = 2'b01;
		end
		else begin
			pipeline_completed_insts = 2'b00;
		end
	end
			
	//assign pipeline_completed_insts = toprf_packet[0].retire_en + toprf_packet[1].retire_en;

	assign icachevalid = Icache_valid_out || Vcache_valid_out;
	
	always_comb begin
		if(Icache_valid_out) begin
			cacheinst = Icache_data_out;
		end
		else if(Vcache_valid_out) begin
			cacheinst = Vcache_data_out;
		end
		else cacheinst = 0;
	end
//////////////////////////////////////////////////
//                                              //
//                  IF-Stage                    //
//                                              //
//////////////////////////////////////////////////

	//these are debug signals that are now included in the packet,
	//breaking them out to support the legacy debug modes


		fetch fetch (
		// Inputs
		.clock (clock),
		.reset (reset),
		.rollback(rollback_en),
		.exception(exception_pc),
		.spare(spare),
		.Imem2proc_data(cacheinst), //data come from icache and vcache
		.tpc_btb(tpc),
		.hit(hit),
		.icachevalid(icachevalid),
		//.lden(lden),
		.Dcache2memcommond(proc2Dmem_command),
		// Outputs
		.branch(branchornot),
		.uncond(uncond),
		.pc_btb(pc_btb),
		.npc_btb(npc_btb),
		
		.proc2Imem_addr(proc2Icache_addr),
		.if_packet_out(if_packet)
	);

//////////////////////////////////////////////////
//                                              //
//                  Icache                      //
//                                              //
//////////////////////////////////////////////////
 icache icache(
    .clock(clock),
    .reset(reset),
	.rollback(rollback_en),
    // from memory
	.Imem2proc_response(Imem2proc_response),
    .Imem2proc_data(mem2proc_data),
    .Imem2proc_tag(Imem2proc_tag),
	.vcachehit(Vcache_valid_out),
    // from fetch stage
    .proc2Icache_addr(proc2Icache_addr),
    .proc2Dmem_command(proc2Dmem_command),
    // to memory
    .proc2Imem_command(Icache2mem_command),
    .proc2Imem_addr(Icache2mem_addr),

    // to fetch stage
    .Icache_data_out(Icache_data_out), // value is memory[proc2Icache_addr]
    .Icache_valid_out(Icache_valid_out),    // when this is high

	//to vcache
	.victimen(victimen),
	.victimidx(victimidx),
	.icache_vdata(icache_vdata)
    );
	
	//logic [63:0] Imem2proc_data;
//////////////////////////////////////////////////
//                                              //
//                  Vcache                      //
//                                              //
//////////////////////////////////////////////////
victimcache vcache (
    .clock(clock),
    .reset(reset),
    .icache_vdata(icache_vdata),
    .victimen(victimen),
    .victimidx(victimidx),
    .proc2Vcache_addr(proc2Icache_addr),


    .Vcache_data_out(Vcache_data_out), // value is memory[proc2Icache_addr]
    .Vcache_valid_out(Vcache_valid_out) 
);

//////////////////////////////////////////////////
//                                              //
//                  Dcache                      //
//                                              //
//////////////////////////////////////////////////
 dcache dcache(
    .clock(clock),
    .reset(reset),
    .rollback(rollback_en),
    .lden(lden),
    .retirest(storeretire),
    .storeing(storeing),
    .Dmem2proc_response(Imem2proc_response),
    .Dmem2proc_data(mem2proc_data),
    .Dmem2proc_tag(Imem2proc_tag),
	.forwarden(forwarden),
	.cleancache(cleancache),

    .loadaddress(loadaddress),
    .storeaddress(wraddress),
    .storedata(wrdata),
    .storememsize(wrmemsize),
    //to mem
    .proc2Dmem_command(proc2Dmem_command),
    .proc2Dmem_data(proc2Dmem_data),
    .proc2Dmem_addr(proc2Dmem_addr),

    //to ex
    .Dcache_data_out(Dcache_data_out),
    .Dcache_valid_out(Dcache_valid_out),
	.clean(clean),
	.empty(empty),
	 .clean_command(clean_command),
    .clean_data(clean_data),
    .clean_addr(clean_addr)
);

//////////////////////////////////////////////////
//                                              //
//            IF/ID Pipeline Register           //
//                                              //
//////////////////////////////////////////////////


	assign if_id_enable = 1'b1; // always enabled
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset) begin 
			if_id_packet <= 0;
		end else begin// if (reset)
			if (if_id_enable) begin
				if_id_packet <=  if_packet; 
			end // if (if_id_enable)	
		end
	end // always

   
//////////////////////////////////////////////////
//                                              //
//                  ID-Stage                    //
//                                              //
//////////////////////////////////////////////////
	
	id_stage id_stage_0 (// Inputs
		.clock(clock),
		.reset(reset),
		.rollback(rollback_en),
		//.spare(),
		.if_id_packet_in(if_id_packet),

		// Outputs
		.disp_enable(disp_enable),
		.destreg(destreg),
		.id_out(id_packet),
		.loaden(loaden),
		.storeen(storeen)
	);

	always_comb begin
		for(int g = 0; g<`WIDTH; g++) begin
				illegal[g] = id_packet[g].illegal;
				halt[g] = id_packet[g].halt;
		end
	end
//////////////////////////////////////////////////
//                                              //
//                  RS                		   	//
//                                              //
//////////////////////////////////////////////////
		rs rs(
		.clock(clock),
		.reset(reset),
		.mapt(map_rs),
		.rollback(rollback_en),
		.t(freeT),
		.id_packet(id_packet),
		.write_en(disp_enable),
		//.freepack(free_packet),
		.cdb(cdb),
		.lqp(lqp),
		.sqp(sqp),
		.loading(loading),
		.storeing(storeing),
		.storeretire(storeretire),
		

		//.rs1(rs1),
		//.rs2(rs2),
		.iss(iss),
		.full(full_rs)
		);
	






//////////////////////////////////////////////////
//                                              //
//                  FL                		   	//
//                                              //
//////////////////////////////////////////////////
	freelist freelist(
		.clock(clock),
		.reset(reset),
		.disp_en(disp_enable),
		.rob_pack(tofl_packet),
		.rollback_en(rollback_en),
		.recover_head(recover_head),

		
		.freeT(freeT)
	);
	
//////////////////////////////////////////////////
//                                              //
//                  LQ                		   	//
//                                              //
//////////////////////////////////////////////////
	loadqueue loadqueue (
		.clock(clock),
		.reset(reset),
		.rollback(rollback_en),
		.storeen(storeen),
		.loaden(loaden),
		.ldpc(ldpc),
		.sten(sten),
		.store_lqp(store_lqp),
		.storeaddress(storeaddress),
		.update_lqp(load_lqp),
		.loadaddress(loadaddress),
		.lden(lden),
		.retireld(loadretire),
		.robnum(robnum),

		.lqp(lqp),
		.full(lqfull),
		.torobnum(torobnum),
		.torobldpc(torobldpc),
		.ldexception(ldexception)
	);

 assign ldpc[0] = id_packet[0].PC;
 assign ldpc[1] = id_packet[1].PC;

//////////////////////////////////////////////////
//                                              //
//                  SQ                		   	//
//                                              //
//////////////////////////////////////////////////
	storequeue storequeue(
	.clock(clock),
    .reset(reset),
    .rollback(rollback_en),
    //from decode
    .storeen(storeen),
    .loaden(loaden),
	.st_memsize(st_memsize),
    //from ex
    .sten(sten),
    .update_sqp(store_sqp),
    .storeaddress(storeaddress),
    .storedata(storedata),
	.storecomplete(Dcache_valid_out),
    //input logic [`WIDTH-1:0]
    .load_sqp(load_sqp),
    .loadaddress(loadaddress),
    .lden(lden),
    //from rob
    .retireen(storeretire),
    //to ex ld  
    .forwarddata(forwarddata),
    .forwarden(forwarden),

	.storeing(storeing),
    .wrdata(wrdata),
    .wraddress(wraddress),
	.wrmemsize(wrmemsize),
    .sqp(sqp),

    .full(sqfull)
	);

//////////////////////////////////////////////////
//                                              //
//            ID/issue Pipeline Register        //
//                                              //
//////////////////////////////////////////////////

	always_comb begin
		for(int l = 0; l<`WIDTH; l++) begin
				t1[l] = iss[l].T1;
				t2[l] = iss[l].T2;
		end
	end
	assign issue_ex_enable = 1'b1; // always enabled
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset || rollback_en) begin
			issue_packet <= 0;
		end else begin // if (reset)
			if (issue_ex_enable) begin
				for(int m = 0; m<`WIDTH;  m++) begin
					issue_packet[m].T <= iss[m].T;
					issue_packet[m].decode_packet <= iss[m].rspack1;
					issue_packet[m].lqp <= iss[m].lqp;
					issue_packet[m].sqp <= iss[m].sqp;
					issue_packet[m].value1 <= val1[m];
					issue_packet[m].value2 <= val2[m];
					
			end // if
		end // else: !if(reset)
		else begin
			issue_packet <= 0;
		end
	end // always
	end

//////////////////////////////////////////////////
//                                              //
//                  EX-Stage                    //
//                                              //
//////////////////////////////////////////////////
	ex_stage ex_stage_0 (
		// Inputs
		.clock(clock),
		.reset(reset),
		.issue_packet(issue_packet),
		.rollback(rollback_en),
		.dcachevalid(Dcache_valid_out),
		.dcache2procdata(Dcache_data_out),
		.forwarddata(forwarddata),
		.forwarden(forwarden),
		// Outputs
		.c_packet(c_packet),
		.to_rob(to_rob),
		.sten(sten),
		.store_lqp(store_lqp),
		.store_sqp(store_sqp),
		.storeaddress(storeaddress),
		.storedata(storedata),
		.load_lqp(load_lqp),
		.load_sqp(load_sqp),
		.loadaddress(loadaddress),
		.lden(lden),
		.loading(loading),
		.st_memsize(st_memsize)
		//.free_packet(free_packet)
	);


//////////////////////////////////////////////////
//                                              //
//           complete                           //
//                                              //
//////////////////////////////////////////////////
	


	assign complete_enable = 1'b1; // always enabled
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset || rollback_en) begin
			cdb <= 0;
			val <= 0;
		end else begin
			if (complete_enable)   begin
				// these are forwarded directly from ID/EX registers, only for debugging purposes
			for(int s = 0; s<`WIDTH; s++) begin
				cdb[s] <= c_packet[s].cdb_pack;
				val[s] <= c_packet[s].value_complete;
				//free_packet[s].free <=  c_packet[s].cdb_pack.complete;
				//free_packet[s].T <= c_packet[s].cdb_pack.p;
			end // if
		end // else: !if(reset)
	end // always
	end



//////////////////////////////////////////////////
//                                              //
//           PRF                                //
//                                              //
//////////////////////////////////////////////////
	PRF PRF(
		.clock(clock),
		.reset(reset),
		.t1(t1),
		.t2(t2),
		.cdb(cdb),
		.val(val),
		.retire_en(retire_en),
		.t_retire(t_retire),
		.thold_retire(thold_retire),
		.val1(val1),
		.val2(val2),
		.ret(ret)
	);

		always_comb begin
			for(int n = 0; n<`WIDTH; n++) begin
				t_retire[n] = toprf_packet[n].t;
				thold_retire[n] = tofl_packet[n].t_hold;
				retire_en[n] = toprf_packet[n].retire_en;
			end
		end
   
//////////////////////////////////////////////////
//                                              //
//       btb with 2bit                          //
//                                              //
//////////////////////////////////////////////////

		BTB BTB(
		.clock(clock),
		.reset(reset),
		.rob_packet(tobtb_packet),
		.branch_en(branchornot),
		.uncond_en(uncond),
		.pc(pc_btb),
		.npc(npc_btb),


		.tpc(tpc),
		.hit(hit)
		);
	

//////////////////////////////////////////////////
//                                              //
//      ARF                                     //
//                                              //
//////////////////////////////////////////////////
		regfile regfile(
			.wr_clk(clock),
			.reset(reset),
			.wr_idx(wr_idx),
			.wr_en(wr_en),
			.wr_data(ret),
			.retire_tag(t_retire),

			.recover_tag(recover_tag)
		);
		
		always_comb begin
			for(int w = 0; w<`WIDTH; w++) begin
					wr_idx[w] = toprf_packet[w].regnum;
					wr_en[w] = toprf_packet[w].retire_en;
			end
		end


//////////////////////////////////////////////////
//                                              //
//                  ROB                		   	//
//                                              //
//////////////////////////////////////////////////
		ROB ROB(
		.clock(clock),
		.reset(reset),
		.dispatch_en(disp_enable),
		.tag_old(T_hold),
		.free_reg(freeT),
		.cdb(cdb),
		.ex_packet(to_rob),
		.destreg(destreg),
		.illegal(illegal),
		.halt(halt),
		.storeen(storeen),
		.loaden(loaden),
		.ldqrobnum(torobnum),
		.ldexception(ldexception),
		.ldexpc(torobldpc),
		.clean(clean),

		.loading(loading),
		.storeing(storeing),


		.loadretire(loadretire),
		.storeretire(storeretire),
		.robnum(robnum),
		.tobtb_packet(tobtb_packet),
		.tofl_packet(tofl_packet),
		.toprf_packet(toprf_packet),
		.rollback_en(rollback_en),
		.exception_en(exception_en),
		.rollback_reg(rollback_reg),
		.rollback_tag(rollback_tag),
		.recover_head(recover_head),
		.exception_pc(exception_pc),
		.full(full_rob),
		.robretire_halt(robretire_halt),
		.robretire_illegal(robretire_illegal)
		);

//////////////////////////////////////////////////
//                                              //
//                  MT                		   	//
//                                              //
//////////////////////////////////////////////////
	Maptable Maptable(
		.clock(clock),
		.reset(reset),
		.write_en(disp_enable),
		.destreg(destreg),
		.reg1(rs1),
		.reg2(rs2),
		.T(freeT),
		.cdb(cdb),
		//.rob_pack(tomt_packet),
		.rec_tag(recover_tag),
		.rollback_en(rollback_en),
		.rollback_reg(rollback_reg),
		.rollback_tag(rollback_tag),
		.exception_en(exception_en),



		//.retire_toarf(retire_toarf),
		.T_hold(T_hold),
		.map_rs(map_rs)
	);

always_comb begin
 for(int b = 0; b <`WIDTH; b++ ) begin
	rs1[b] = id_packet[b].inst.r.rs1;
	rs2[b] = id_packet[b].inst.r.rs2;
 end
end




endmodule  // module verisimple
`endif // __PIPELINE_V__
