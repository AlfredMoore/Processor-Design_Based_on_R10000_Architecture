/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  id_stage.v                                          //
//                                                                     //
//  Description :  instruction decode (ID) stage of the pipeline;      // 
//                 decode the instruction fetch register operands, and // 
//                 compute immediate operand (if applicable)           // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`timescale 1ns/100ps


  // Decode an instruction: given instruction bits IR produce the
  // appropriate datapath control signals.
  //
  // This is a *combinational* module (basically a PLA).
  //
module decoder(

	//input [31:0] inst,
	//input valid_inst_in,  // ignore inst when low, outputs will
	                      // reflect noop (except valid_inst)
	//see sys_defs.svh for definition
	input IF_ID_PACKET if_packet,
	
	output ALU_OPA_SELECT opa_select,
	output ALU_OPB_SELECT opb_select,
	output DEST_REG_SEL   dest_reg, // mux selects
	output ALU_FUNC       alu_func,
	output logic rd_mem, wr_mem, cond_branch, uncond_branch,
	output logic csr_op,    // used for CSR operations, we only used this as 
	                        //a cheap way to get the return code out
	output logic halt,      // non-zero on a halt
	output logic illegal,    // non-zero on an illegal instruction
	output logic valid_inst  // for counting valid instructions executed
	                        // and for making the fetch stage die on halts/
	                        // keeping track of when to allow the next
	                        // instruction out of fetch
	                        // 0 for HALT and illegal instructions (die on halt)

);

	INST inst;
	logic valid_inst_in;
	
	assign inst          = if_packet.inst;
	assign valid_inst_in = if_packet.valid;
	assign valid_inst    = valid_inst_in & ~illegal;
	
	always_comb begin
		// default control values:
		// - valid instructions must override these defaults as necessary.
		//	 opa_select, opb_select, and alu_func should be set explicitly.
		// - invalid instructions should clear valid_inst.
		// - These defaults are equivalent to a noop
		// * see sys_defs.vh for the constants used here
		opa_select = OPA_IS_RS1;
		opb_select = OPB_IS_RS2;
		alu_func = ALU_ADD;
		dest_reg = DEST_NONE;
		csr_op = `FALSE;
		rd_mem = `FALSE;
		wr_mem = `FALSE;
		cond_branch = `FALSE;
		uncond_branch = `FALSE;
		halt = `FALSE;
		illegal = `FALSE;
		if(valid_inst_in) begin
			casez (inst) 
				`RV32_LUI: begin
					dest_reg   = DEST_RD;
					opa_select = OPA_IS_ZERO;
					opb_select = OPB_IS_U_IMM;
				end
				`RV32_AUIPC: begin
					dest_reg   = DEST_RD;
					opa_select = OPA_IS_PC;
					opb_select = OPB_IS_U_IMM;
				end
				`RV32_JAL: begin
					dest_reg      = DEST_RD;
					opa_select    = OPA_IS_PC;
					opb_select    = OPB_IS_J_IMM;
					uncond_branch = `TRUE;
				end
				`RV32_JALR: begin
					dest_reg      = DEST_RD;
					opa_select    = OPA_IS_RS1;
					opb_select    = OPB_IS_I_IMM;
					uncond_branch = `TRUE;
				end
				`RV32_BEQ, `RV32_BNE, `RV32_BLT, `RV32_BGE,
				`RV32_BLTU, `RV32_BGEU: begin
					opa_select  = OPA_IS_PC;
					opb_select  = OPB_IS_B_IMM;
					cond_branch = `TRUE;
				end
				`RV32_LB, `RV32_LH, `RV32_LW,
				`RV32_LBU, `RV32_LHU: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					rd_mem     = `TRUE;
				end
				`RV32_SB, `RV32_SH, `RV32_SW: begin
					opb_select = OPB_IS_S_IMM;
					wr_mem     = `TRUE;
				end
				`RV32_ADDI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
				end
				`RV32_SLTI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_SLT;
				end
				`RV32_SLTIU: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_SLTU;
				end
				`RV32_ANDI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_AND;
				end
				`RV32_ORI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_OR;
				end
				`RV32_XORI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_XOR;
				end
				`RV32_SLLI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_SLL;
				end
				`RV32_SRLI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_SRL;
				end
				`RV32_SRAI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_SRA;
				end
				`RV32_ADD: begin
					dest_reg   = DEST_RD;
				end
				`RV32_SUB: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SUB;
				end
				`RV32_SLT: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SLT;
				end
				`RV32_SLTU: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SLTU;
				end
				`RV32_AND: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_AND;
				end
				`RV32_OR: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_OR;
				end
				`RV32_XOR: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_XOR;
				end
				`RV32_SLL: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SLL;
				end
				`RV32_SRL: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SRL;
				end
				`RV32_SRA: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SRA;
				end
				`RV32_MUL: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_MUL;
				end
				`RV32_MULH: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_MULH;
				end
				`RV32_MULHSU: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_MULHSU;
				end
				`RV32_MULHU: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_MULHU;
				end
				`RV32_CSRRW, `RV32_CSRRS, `RV32_CSRRC: begin
					csr_op = `TRUE;
				end
				`WFI: begin
					halt = `TRUE;
				end
				default: illegal = `TRUE;

		endcase // casez (inst)
		end // if(valid_inst_in)
	end // always
endmodule // decoder


module id_stage(         
	input         clock,              // system clock
	input         reset,              // system reset
	//input         wb_reg_wr_en_out,    // Reg write enable from WB Stage
	//input  [4:0] wb_reg_wr_idx_out,  // Reg write index from WB Stage
	//input  [`XLEN-1:0] wb_reg_wr_data_out,  // Reg write data from WB Stage
	input rollback,
	//input logic [`WIDTH-1:0] spare, //rs and rob structural harzard 
	input  IF_ID_PACKET [`WIDTH-1:0] if_id_packet_in,
	output logic [`WIDTH-1:0] disp_enable,
	output logic [`WIDTH-1:0] [$clog2(`RF_SIZE)-1:0] destreg,
	output ID_PACKET [`WIDTH-1:0]	id_out,
	output logic [`WIDTH-1:0] loaden,
	output logic [`WIDTH-1:0] storeen
);

 
	DEST_REG_SEL [`WIDTH-1:0] dest_reg_select; 


	genvar i;
	generate
		for(i=0;i<`WIDTH;i++) begin: decode

		decoder decoder_0 (
		.if_packet(if_id_packet_in[i]),	 
		// Outputs
		.opa_select(id_out[i].opa_select),
		.opb_select(id_out[i].opb_select),
		.alu_func(id_out[i].alu_func),
		.dest_reg(dest_reg_select[i]),
		.rd_mem(id_out[i].rd_mem),
		.wr_mem(id_out[i].wr_mem),
		.cond_branch(id_out[i].cond_branch),
		.uncond_branch(id_out[i].uncond_branch),
		.csr_op(id_out[i].csr_op),
		.halt(id_out[i].halt),
		.illegal(id_out[i].illegal),
		.valid_inst(id_out[i].valid)
	);
		end
	endgenerate

	// mux to generate dest_reg_idx based on
	// the dest_reg_select output from decoder
	always_comb begin
		for(int a=0; a<`WIDTH; a++) begin
		case (dest_reg_select[a])
			DEST_RD:  begin  
			if(if_id_packet_in[a].inst.r.rd == `ZERO_REG) begin
				id_out[a].destzero = 1;
				destreg[a] = `ZERO_REG;
			end
			else begin destreg[a] = if_id_packet_in[a].inst.r.rd;
				id_out[a].destzero = 0;
			end
			end
			DEST_NONE:  begin destreg[a] = `ZERO_REG;
			id_out[a].destzero = 1;
			end
			default:  	begin  destreg[a] = `ZERO_REG; 
			id_out[a].destzero = 1;
			end
		endcase
	 	  id_out[a].inst = if_id_packet_in[a].inst;
   	 	  id_out[a].NPC  = if_id_packet_in[a].NPC;
   		  id_out[a].PC   = if_id_packet_in[a].PC;
		  id_out[a].take = if_id_packet_in[a].take;
		  id_out[a].targetpc = if_id_packet_in[a].targetpc;
		  if(if_id_packet_in[a].inst.r.rs2 == `ZERO_REG) begin
			id_out[a].regtwozero = 1;
		  end
		  else id_out[a].regtwozero = 0;
		  if(if_id_packet_in[a].inst.r.rs1 == `ZERO_REG) begin
			id_out[a].regonezero = 1;
		  end
		  else id_out[a].regonezero = 0;

	end
	end

	//dispatch enable
	always_comb begin
		if(rollback) begin
			disp_enable = 0;
			loaden = 0;
			storeen = 0;
		end
		else begin
		for(int x = 0; x<`WIDTH; x++) begin
			disp_enable[x] = id_out[x].valid;
			loaden[x] = id_out[x].rd_mem;
			storeen[x] = id_out[x].wr_mem;
		end
		end
	end

endmodule // module id_stage
