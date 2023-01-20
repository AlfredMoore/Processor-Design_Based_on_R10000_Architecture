//////////////////////////////////////////////////////////////////////////
//                                                                      //
//   Modulename :  ex_stage.v                                           //
//                                                                      //
//  Description :  instruction execute (EX) stage of the pipeline;      //
//                 given the instruction command code CMD, select the   //
//                 proper input A and B for the ALU, compute the result,// 
//                 and compute the condition for branches, and pass all //
//                 the results down the pipeline. MWB                   // 
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////
`ifndef __EX_STAGE_V__
`define __EX_STAGE_V__

`timescale 1ns/100ps

//
// The ALU
//
// given the command code CMD and proper operands A and B, compute the
// result of the instruction
//
// This module is purely combinational
//
module alu(
	input [`XLEN-1:0] opa,
	input [`XLEN-1:0] opb,
	ALU_FUNC     func,
    input valid,
    input [$clog2(`PRF_SIZE)-1:0] tagin,
    output [$clog2(`PRF_SIZE)-1:0] tagout,
    output logic done,
	output logic [`XLEN-1:0] result
);
	wire signed [`XLEN-1:0] signed_opa, signed_opb;
	//wire signed [2*`XLEN-1:0] signed_mul, mixed_mul;
	//wire        [2*`XLEN-1:0] unsigned_mul;
	assign signed_opa = opa;
	assign signed_opb = opb;
    assign tagout = tagin;
	//assign signed_mul = signed_opa * signed_opb;
	//assign unsigned_mul = opa * opb;
	//assign mixed_mul = signed_opa * opb;

	always_comb begin

        if(valid) begin
		case (func)
			ALU_ADD:    begin  result = opa + opb; done =1; end
			ALU_SUB:    begin  result = opa - opb; done =1; end
			ALU_AND:    begin  result = opa & opb; done =1; end
			ALU_SLT:    begin  result = signed_opa < signed_opb; done = 1; end
			ALU_SLTU:   begin  result = opa < opb; done =1; end
			ALU_OR:     begin  result = opa | opb; done =1; end
			ALU_XOR:    begin  result = opa ^ opb; done =1; end
			ALU_SRL:    begin  result = opa >> opb[4:0]; done =1; end 
			ALU_SLL:    begin  result = opa << opb[4:0]; done =1; end
			ALU_SRA:    begin  result = signed_opa >>> opb[4:0]; done =1; end// arithmetic from logical shift
			/*ALU_MUL:      result = signed_mul[`XLEN-1:0];
			ALU_MULH:     result = signed_mul[2*`XLEN-1:`XLEN];
			ALU_MULHSU:   result = mixed_mul[2*`XLEN-1:`XLEN];
			ALU_MULHU:    result = unsigned_mul[2*`XLEN-1:`XLEN];*/

			default:   begin  result = `XLEN'hfacebeec;  done =0; end// here to prevent latches
		endcase
        end
        else begin
            result = `XLEN'hfacebeec; 
            done = 0;
        end
	end
endmodule // alu

module mult  (
				input clock, 
				input reset,
				input rollback,
				//input start,
				input ALU_FUNC     func,
				input [`XLEN-1:0] mcand, mplier,
                input [$clog2(`PRF_SIZE)-1:0] t_in,

                output [$clog2(`PRF_SIZE)-1:0] t_out,
				
				output [`XLEN-1:0] product,
				output done			);
	logic [(2*`XLEN)-1:0]  mcand_in, mplier_in;
	logic [`NUM_STAGE:0][2*`XLEN-1:0] internal_mcands, internal_mpliers;
	logic [`NUM_STAGE:0][2*`XLEN-1:0] internal_products;
	logic [`NUM_STAGE:0] internal_dones;
	logic [`NUM_STAGE:0] [$clog2(`PRF_SIZE)-1:0] internal_t;
    logic [1:0] sign;
    logic [(2*`XLEN)-1:0] product1;
    logic start;
    ALU_FUNC func_complete;
    ALU_FUNC [`NUM_STAGE:0] internal_func;

    always_comb begin
        case(func) 
            ALU_MUL:    begin  sign[0] = 1;
            sign[1] = 1;
           // product = product1[`XLEN-1:0];
            start = 1;
            end
			ALU_MULH:   begin sign[0] = 1;
            sign[1] = 1;
          //  product = product1[2*`XLEN-1:`XLEN];
            start = 1;
            end
			ALU_MULHSU: begin sign[0] = 1;
            sign[1] = 0;
           // product = product1[2*`XLEN-1:`XLEN];
            start = 1;
            end
			ALU_MULHU:  begin sign[0] = 0;
            sign[1] = 0;
           // product = product1[2*`XLEN-1:`XLEN];
            start = 1;
            end

            default: begin sign[0] = 0;
            sign[1] = 0;
            start = 0;
            end
        endcase
    end
    assign product = (func_complete == ALU_MUL)? product1[`XLEN-1:0] : product1[2*`XLEN-1:`XLEN];
	assign mcand_in  = sign[0] ? {{`XLEN{mcand[`XLEN-1]}}, mcand}   : {{`XLEN{1'b0}}, mcand} ;
	assign mplier_in = sign[1] ? {{`XLEN{mplier[`XLEN-1]}}, mplier} : {{`XLEN{1'b0}}, mplier};

	assign internal_mcands[0]   = mcand_in;
	assign internal_mpliers[0]  = mplier_in;
	assign internal_products[0] = 'h0;
	assign internal_dones[0]    = start;
    assign internal_func[0] = func; 
    assign internal_t[0] = t_in;
	assign done    = internal_dones[`NUM_STAGE];
	assign product1 = internal_products[`NUM_STAGE];
    assign func_complete = internal_func[`NUM_STAGE];
    assign t_out = internal_t[`NUM_STAGE];

	genvar i;
	for (i = 0; i < `NUM_STAGE; ++i) begin : mstage
		mult_stage  ms (
			.clock(clock),
			.reset(reset),
			.rollback(rollback),
			.product_in(internal_products[i]),
			.mplier_in(internal_mpliers[i]),
			.mcand_in(internal_mcands[i]),
			.start(internal_dones[i]),
            .funcin(internal_func[i]),
            .funcout(internal_func[i+1]),
			.product_out(internal_products[i+1]),
			.mplier_out(internal_mpliers[i+1]),
			.mcand_out(internal_mcands[i+1]),
			.done(internal_dones[i+1]),
            .tin(internal_t[i]),
            .tout(internal_t[i+1])
		);
	end
endmodule

module mult_stage  (
					input clock, reset, start,
					input rollback,
					input [(2*`XLEN)-1:0] mplier_in, mcand_in,
					input [(2*`XLEN)-1:0] product_in,
                    input ALU_FUNC funcin,
                    input logic [$clog2(`PRF_SIZE)-1:0] tin,
                    output logic  [$clog2(`PRF_SIZE)-1:0] tout,
                    output ALU_FUNC funcout,
					output logic done,
					output logic [(2*`XLEN)-1:0] mplier_out, mcand_out,
					output logic [(2*`XLEN)-1:0] product_out
				);

	parameter NUM_BITS = (2*`XLEN)/`NUM_STAGE;

	logic [(2*`XLEN)-1:0] prod_in_reg, partial_prod, next_partial_product, partial_prod_unsigned;
	logic [(2*`XLEN)-1:0] next_mplier, next_mcand;

	assign product_out = prod_in_reg + partial_prod;

	assign next_partial_product = mplier_in[(NUM_BITS-1):0] * mcand_in;

	assign next_mplier = {{(NUM_BITS){1'b0}},mplier_in[2*`XLEN-1:(NUM_BITS)]};
	assign next_mcand  = {mcand_in[(2*`XLEN-1-NUM_BITS):0],{(NUM_BITS){1'b0}}};

	//synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		prod_in_reg      <= product_in;
		partial_prod     <= next_partial_product;
		mplier_out       <= next_mplier;
		mcand_out        <= next_mcand;
		funcout			<= funcin;
		tout   			<= tin;
	end

	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if(reset || rollback) begin
			done     <= 1'b0;
		end else begin
			done     <= start;
		end
	end

endmodule
//
// BrCond module
//
// Given the instruction code, compute the proper condition for the
// instruction; for branches this condition will indicate whether the
// target is taken.
//
// This module is purely combinational
//
module brcond(// Inputs
	input [`XLEN-1:0] rs1,    // Value to check against condition
	input [`XLEN-1:0] rs2,
	input [2:0] func,  // Specifies which condition to check
	//input [$clog2(`PRF_SIZE)-1:0] tag_in;


	//output [$clog2(`PRF_SIZE)-1:0] tag_out;
	output logic cond    // 0/1 condition result (False/True)
);

	logic signed [`XLEN-1:0] signed_rs1, signed_rs2;
	assign signed_rs1 = rs1;
	assign signed_rs2 = rs2;
	//assign tag_out = tag_in;
	always_comb begin
		cond = 0;
		case (func)
			3'b000: cond = signed_rs1 == signed_rs2;  // BEQ
			3'b001: cond = signed_rs1 != signed_rs2;  // BNE
			3'b100: cond = signed_rs1 < signed_rs2;   // BLT
			3'b101: cond = signed_rs1 >= signed_rs2;  // BGE
			3'b110: cond = rs1 < rs2;                 // BLTU
			3'b111: cond = rs1 >= rs2;                // BGEU
		endcase
	end
	
endmodule // brcond


module ex_stage(
	input clock,               // system clock
	input reset,               // system reset
	input I_EX_packet  [`WIDTH-1:0] issue_packet,
	input logic rollback,
	input logic dcachevalid,
	input CACHE_BLOCK dcache2procdata,
	input logic forwarden,
	input logic [`XLEN-1:0] forwarddata,
	output EX_C_packet [`WIDTH-1:0] c_packet,
	output EX_ROB_packet [`WIDTH-1:0]  to_rob,
	output logic [`WIDTH-1:0] sten,
    output logic [`WIDTH-1:0][$clog2(`LQ_SIZE)-1:0] store_lqp,
    output logic [`WIDTH-1:0][$clog2(`SQ_SIZE)-1:0] store_sqp,
    output logic [`WIDTH-1:0] [`XLEN-1:0] storeaddress,
	output logic [`WIDTH-1:0] [`XLEN-1:0] storedata,
	output logic [$clog2(`LQ_SIZE)-1:0] load_lqp,
	output logic [$clog2(`SQ_SIZE)-1:0] load_sqp,
    output logic [`XLEN-1:0] loadaddress,
    output logic lden,
	output logic [`WIDTH-1:0] [2:0] st_memsize,
	output logic loading
	//output EX_RS_packet [`WIDTH-1:0] free_packet
);
	// Pass-throughs
	ex_buffer [`RS_SIZE-1:0] entry;
	ex_buffer [`RS_SIZE-1:0] nentry;
	loadwl1 loadwl;
	loadwl1 nloadwl;
	logic  clean;
	logic [`WIDTH-1:0] [`XLEN-1:0] opa_mux_out, opb_mux_out;
	logic [`WIDTH-1:0] alu_done;
    logic [`WIDTH-1:0] [`XLEN-1:0] alu_result;
    logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] alu_tag;
	logic [`WIDTH-1:0] alu_remain;
	logic [`WIDTH-1:0] [`XLEN-1:0] brrs1, brrs2;
    logic [`WIDTH-1:0] branch_cond;

    logic [`WIDTH-1:0] [$clog2(`PRF_SIZE)-1:0] mult_tag;
	logic [`WIDTH-1:0] [`XLEN-1:0] mult_result;
	logic [`WIDTH-1:0] mult_done;
	logic [`WIDTH-1:0] mult_remain;
	
    always_comb begin
		if(loadwl.busy)begin
			loading = 1;
		end
		else begin
			if(issue_packet[0].decode_packet.rd_mem || issue_packet[1].decode_packet.rd_mem) begin
				loading = 1;
			end
			else loading = 0;
		end
	end
    //
	// ALU opA mux
	//
	always_comb begin
        for(int a = 0; a<`WIDTH; a++) begin
		opa_mux_out[a] = `XLEN'hdeadfbac;
		case (issue_packet[a].decode_packet.opa_select)
			OPA_IS_RS1: begin if(issue_packet[a].decode_packet.regonezero) begin
								opa_mux_out[a] = 0;
							  end
							  else opa_mux_out[a] = issue_packet[a].value1;
			end						   
			OPA_IS_NPC:  opa_mux_out[a] = issue_packet[a].decode_packet.NPC;
			OPA_IS_PC:   opa_mux_out[a] = issue_packet[a].decode_packet.PC;
			OPA_IS_ZERO: opa_mux_out[a] = 0;
		endcase
	end
    end

	 //
	 // ALU opB mux
	 //
	always_comb begin
		// Default value, Set only because the case isnt full.  If you see this
		// value on the output of the mux you have an invalid opb_select
        for(int b = 0; b<`WIDTH; b++) begin
		opb_mux_out[b] = `XLEN'hfacefeed;
		case (issue_packet[b].decode_packet.opb_select)
			OPB_IS_RS2:   begin if(issue_packet[b].decode_packet.regtwozero) begin
								opb_mux_out[b] = 0;
							  end
							  else opb_mux_out[b] = issue_packet[b].value2;
			end						 
			OPB_IS_I_IMM: opb_mux_out[b] = `RV32_signext_Iimm(issue_packet[b].decode_packet.inst);
			OPB_IS_S_IMM: opb_mux_out[b] = `RV32_signext_Simm(issue_packet[b].decode_packet.inst);
			OPB_IS_B_IMM: opb_mux_out[b] = `RV32_signext_Bimm(issue_packet[b].decode_packet.inst);
			OPB_IS_U_IMM: opb_mux_out[b] = `RV32_signext_Uimm(issue_packet[b].decode_packet.inst);
			OPB_IS_J_IMM: opb_mux_out[b] = `RV32_signext_Jimm(issue_packet[b].decode_packet.inst);
		endcase 
	end
    end

	//
	// instantiate the ALU
	//


	always_comb begin
		for(int h = 0; h < `WIDTH; h++) begin
			if(issue_packet[h].decode_packet.regtwozero) begin
				brrs2[h] =0;
			end
			else brrs2[h] = issue_packet[h].value2;
			if(issue_packet[h].decode_packet.regonezero) begin
				brrs1[h] = 0;
			end
			else brrs1[h] = issue_packet[h].value1;
		end
	end



        genvar i;
        generate 
            for(i = 0; i < `WIDTH; i++) begin: gene
            alu alu (
                .opa(opa_mux_out[i]),
                .opb(opb_mux_out[i]),
                .func(issue_packet[i].decode_packet.alu_func),
                .valid(issue_packet[i].decode_packet.valid),
                .done(alu_done[i]),
                .result(alu_result[i]),
                .tagin(issue_packet[i].T),
                .tagout(alu_tag[i])
            );

            brcond brcond(
                .rs1(brrs1[i]),
                .rs2(brrs2[i]),
                .func(issue_packet[i].decode_packet.inst.b.funct3),
                .cond(branch_cond[i])
            );


			mult mult(
				.clock(clock),
				.reset(reset),
				.rollback(rollback),
				.func(issue_packet[i].decode_packet.alu_func),
				.t_in(issue_packet[i].T),
				.mcand(brrs1[i]),
				.mplier(brrs2[i]),
				.t_out(mult_tag[i]),
				.product(mult_result[i]),
				.done(mult_done[i])
			);
			end
		endgenerate
	 
	 //to rob (branch record)
	 always_comb begin
		to_rob = 0;
		for(int u = 0; u<`WIDTH; u++) begin
			if(issue_packet[u].decode_packet.cond_branch ) begin
				to_rob[u].isbranch = 1;
				to_rob[u].T = issue_packet[u].T;
				to_rob[u].mispredict = issue_packet[u].decode_packet.take ^ branch_cond[u];
				to_rob[u].targetpc = (branch_cond[u])? alu_result[u] : issue_packet[u].decode_packet.NPC;
				to_rob[u].pc = issue_packet[u].decode_packet.PC;
				to_rob[u].uncond = issue_packet[u].decode_packet.uncond_branch;
			end
			else if(issue_packet[u].decode_packet.uncond_branch) begin
				to_rob[u].isbranch = 1;
				to_rob[u].T = issue_packet[u].T;
				to_rob[u].mispredict = (issue_packet[u].decode_packet.targetpc != alu_result[u]);
				to_rob[u].targetpc = alu_result[u];
				to_rob[u].pc = issue_packet[u].decode_packet.PC;
				to_rob[u].uncond = issue_packet[u].decode_packet.uncond_branch;
			end
			else begin
				to_rob[u] = 0;
			end
		end
	 end
	//to complete
	 always_comb begin

		nentry = entry;
		c_packet = 0;
		mult_remain = mult_done;
		clean = 0;
		if(loadwl.busy && loadwl.complete) begin
			c_packet[0].cdb_pack.complete = 1;
			c_packet[0].cdb_pack.p = loadwl.tag;
			c_packet[0].value_complete = loadwl.val;
			clean = 1;
		end
		for(int v = 0; v<`WIDTH; v++)begin
				for(int c = 0; c<`WIDTH; c++) begin
					if(mult_remain[c] && (!c_packet[v].cdb_pack.complete)) begin
						c_packet[v].cdb_pack.complete = 1;
						c_packet[v].cdb_pack.p = mult_tag[c];
						c_packet[v].value_complete = mult_result[c];
						mult_remain[c] = 0;
					end
				end
		end

		for(int n = 0; n<`WIDTH; n++)begin
			for(int m =0; m<`RS_SIZE-1;m++) begin
				if(nentry[m].busy && (!c_packet[n].cdb_pack.complete)) begin
						c_packet[n].cdb_pack.complete = 1;
						c_packet[n].cdb_pack.p = nentry[m].tag;
						c_packet[n].value_complete = nentry[m].val;	
						nentry[m] = 0;
				end
			end
		end		

		alu_remain = alu_done;

		for(int g = 0; g<`WIDTH; g++)begin
				for(int h = 0; h<`WIDTH; h++) begin
					if(alu_remain[h] && (!c_packet[g].cdb_pack.complete) &&  !issue_packet[h].decode_packet.rd_mem) begin
						c_packet[g].cdb_pack.complete = 1;
						c_packet[g].cdb_pack.p = alu_tag[h];
						alu_remain[h] = 0;
						if(issue_packet[h].decode_packet.destzero) begin
							c_packet[g].value_complete = 0;
						end
						else if(issue_packet[h].decode_packet.uncond_branch) begin
							c_packet[g].value_complete = issue_packet[h].decode_packet.NPC;						
						end
						else begin
							c_packet[g].value_complete = alu_result[h];
						end


					end
				end
		end
	
		for(int x = 0; x<`WIDTH; x++) begin
			for(int y = 0; y<`RS_SIZE-1; y++) begin
				if(mult_remain[x] && (!nentry[y].busy)) begin
					nentry[y].busy =1;
					nentry[y].tag = mult_tag[x];
					nentry[y].val = mult_result[x];
					mult_remain[x] = 0;
				end
				else if(alu_remain[x] && (!nentry[y].busy) && !issue_packet[x].decode_packet.rd_mem) begin
					nentry[y].busy =1;
					nentry[y].tag = alu_tag[x];
					alu_remain[x] = 0;
					if(issue_packet[x].decode_packet.destzero) begin
						nentry[y].val = 0;
					end
					else if(issue_packet[x].decode_packet.uncond_branch) begin
						nentry[y].val = issue_packet[x].decode_packet.NPC;						
					end
					else begin
						nentry[y].val = alu_result[x];
					end
				end
			end
		end
end

	always_comb begin
		nloadwl = loadwl;
		if(clean) begin
			nloadwl = 0;
		end
		else begin
			if(!loadwl.busy) begin
			if(issue_packet[0].decode_packet.rd_mem) begin				
				if(forwarden) begin
					nloadwl.busy = 1;
					nloadwl.complete =1;
					nloadwl.address = alu_result[0];
					case(issue_packet[0].decode_packet.inst.r.funct3) 
						LB:  nloadwl.val = {{(`XLEN-8){forwarddata[7]}}, forwarddata[7:0]};
						LH:  nloadwl.val = {{(`XLEN-16){forwarddata[15]}}, forwarddata[15:0]};
						LW:  nloadwl.val = forwarddata;
						LBU: nloadwl.val = {{(`XLEN-8){1'b0}}, forwarddata[7:0]};
						LHU: nloadwl.val = {{(`XLEN-16){1'b0}}, forwarddata[15:0]};
					endcase
					nloadwl.tag = alu_tag[0];
					nloadwl.ld_memsize = issue_packet[0].decode_packet.inst.r.funct3;
				end
				else if(dcachevalid) begin
					nloadwl.busy = 1;
					nloadwl.complete =1;
					nloadwl.address = alu_result[0];
					case(issue_packet[0].decode_packet.inst.r.funct3) 
						LB:  nloadwl.val = {{(`XLEN-8){dcache2procdata.bytes[alu_result[0][2:0]][7]}}, dcache2procdata.bytes[alu_result[0][2:0]]};
						LH:  nloadwl.val = {{(`XLEN-16){dcache2procdata.halves[alu_result[0][2:1]][15]}}, dcache2procdata.halves[alu_result[0][2:1]]};
						LW:  nloadwl.val = dcache2procdata.words[alu_result[0][2]];
						LBU: nloadwl.val = {{(`XLEN-8){1'b0}}, dcache2procdata.bytes[alu_result[0][2:0]]};
						LHU: nloadwl.val = {{(`XLEN-16){1'b0}}, dcache2procdata.halves[alu_result[0][2:1]]};
					endcase
					nloadwl.tag = alu_tag[0];
					nloadwl.ld_memsize = issue_packet[0].decode_packet.inst.r.funct3;
				end
				else begin
					nloadwl.busy = 1;
					nloadwl.complete =0;
					nloadwl.val = 0;
					nloadwl.tag = alu_tag[0];
					nloadwl.ld_memsize = issue_packet[0].decode_packet.inst.r.funct3;
					nloadwl.address = alu_result[0];
				end
			end
			else if(issue_packet[1].decode_packet.rd_mem) begin
				if(forwarden) begin
					nloadwl.busy = 1;
					nloadwl.complete =1;
					nloadwl.address = alu_result[1];
					case(issue_packet[1].decode_packet.inst.r.funct3) 
						LB:  nloadwl.val = {{(`XLEN-8){forwarddata[7]}}, forwarddata[7:0]};
						LH:  nloadwl.val = {{(`XLEN-16){forwarddata[15]}}, forwarddata[15:0]};
						LW:  nloadwl.val = forwarddata;
						LBU: nloadwl.val = {{(`XLEN-8){1'b0}}, forwarddata[7:0]};
						LHU: nloadwl.val = {{(`XLEN-16){1'b0}}, forwarddata[15:0]};
					endcase
					nloadwl.tag = alu_tag[1];
					nloadwl.ld_memsize = issue_packet[1].decode_packet.inst.r.funct3;
				end
				else if(dcachevalid) begin
					nloadwl.busy = 1;
					nloadwl.complete =1;
					nloadwl.address = alu_result[1];
					case(issue_packet[1].decode_packet.inst.r.funct3) 
						LB:  nloadwl.val = {{(`XLEN-8){dcache2procdata.bytes[alu_result[1][2:0]][7]}}, dcache2procdata.bytes[alu_result[1][2:0]]};
						LH:  nloadwl.val = {{(`XLEN-16){dcache2procdata.halves[alu_result[1][2:1]][15]}}, dcache2procdata.halves[alu_result[1][2:1]]};
						LW:  nloadwl.val = dcache2procdata.words[alu_result[1][2]];
						LBU: nloadwl.val = {{(`XLEN-8){1'b0}}, dcache2procdata.bytes[alu_result[1][2:0]]};
						LHU: nloadwl.val = {{(`XLEN-16){1'b0}}, dcache2procdata.halves[alu_result[1][2:1]]};
					endcase
					nloadwl.tag = alu_tag[1];
					nloadwl.ld_memsize = issue_packet[1].decode_packet.inst.r.funct3;
				end
				else begin
					nloadwl.busy = 1;
					nloadwl.complete =0;
					nloadwl.val = 0;
					nloadwl.tag = alu_tag[1];
					nloadwl.ld_memsize = issue_packet[1].decode_packet.inst.r.funct3;
					nloadwl.address = alu_result[1];
				end
			end
			else begin
				nloadwl = 0;
			end
			end
			else begin
				if(dcachevalid )begin
					nloadwl.busy = 1;
					nloadwl.complete =1;
					case(loadwl.ld_memsize)
						LB:  nloadwl.val = {{(`XLEN-8){dcache2procdata.bytes[loadwl.address[2:0]][7]}}, dcache2procdata.bytes[loadwl.address[2:0]]};
						LH:  nloadwl.val = {{(`XLEN-16){dcache2procdata.halves[loadwl.address[2:1]][15]}}, dcache2procdata.halves[loadwl.address[2:1]]};
						LW:  nloadwl.val = dcache2procdata.words[loadwl.address[2]];
						LBU: nloadwl.val = {{(`XLEN-8){1'b0}}, dcache2procdata.bytes[loadwl.address[2:0]]};
						LHU: nloadwl.val = {{(`XLEN-16){1'b0}}, dcache2procdata.halves[loadwl.address[2:1]]};
					endcase
				end
			end
		end
	end





	//store
	always_comb begin
		sten = 0;
		storeaddress = 0;
		store_lqp = 0;
		store_sqp = 0;
		storedata = 0;
		for(int d = 0; d <`WIDTH; d++) begin
			if(issue_packet[d].decode_packet.wr_mem) begin
				sten[d] = 1;
				storeaddress[d] = alu_result[d];
				st_memsize[d] = issue_packet[d].decode_packet.inst.r.funct3;
				store_lqp[d] = issue_packet[d].lqp;
				store_sqp[d] = issue_packet[d].sqp;
				if(issue_packet[d].decode_packet.regtwozero) begin
					storedata[d] = 0;
				end
				else begin
				storedata[d] = issue_packet[d].value2;
				end
			end
		end
	end
	//load
	always_comb begin
		if(issue_packet[0].decode_packet.rd_mem) begin
			lden = 1;
			loadaddress = alu_result[0];
			load_lqp = issue_packet[0].lqp;
			load_sqp = issue_packet[0].sqp;
			
		end
		else if(issue_packet[1].decode_packet.rd_mem) begin
			lden = 1;
			loadaddress = alu_result[1];
			load_lqp = issue_packet[1].lqp;
			load_sqp = issue_packet[1].sqp;
		end
		else if(loading) begin
			lden = 0;
			loadaddress = loadaddress;
			load_lqp = 0;
			load_sqp = 0;
		end
		else begin
			lden = 0;
			loadaddress = 0;
			load_lqp = 0;
			load_sqp = 0;
		end
	end


always_ff@(posedge clock) begin
	if(reset || rollback) begin
		entry <= 0;
		loadwl <=0;
	end
	else begin
		entry <= nentry;
		loadwl <= nloadwl;

	end
end



endmodule // module ex_stage
`endif // __EX_STAGE_V__
