/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  sys_defs.vh                                         //
//                                                                     //
//  Description :  This file has the macro-defines for macros used in  //
//                 the pipeline design.                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`ifndef __SYS_DEFS_VH__
`define __SYS_DEFS_VH__

/* Synthesis testing definition, used in DUT module instantiation */

`ifdef  SYNTH_TEST
`define DUT(mod) mod``_svsim
`else
`define DUT(mod) mod
`endif

//////////////////////////////////////////////
//
// Memory/testbench attribute definitions
//
//////////////////////////////////////////////
`define CACHE_MODE //removes the byte-level interface from the memory mode, DO NOT MODIFY!
`define NUM_MEM_TAGS           15

`define MEM_SIZE_IN_BYTES      (64*1024)
`define MEM_64BIT_LINES        (`MEM_SIZE_IN_BYTES/8)

//you can change the clock period to whatever, 10 is just fine
`define VERILOG_CLOCK_PERIOD   10.0
`define SYNTH_CLOCK_PERIOD     19.8 // Clock period for synth and memory latency

`define MEM_LATENCY_IN_CYCLES (100.0/`SYNTH_CLOCK_PERIOD+0.49999)
// the 0.49999 is to force ceiling(100/period).  The default behavior for
// float to integer conversion is rounding to nearest

typedef union packed {
    logic [7:0][7:0] byte_level;
    logic [3:0][15:0] half_level;
    logic [1:0][31:0] word_level;
} EXAMPLE_CACHE_BLOCK;

//////////////////////////////////////////////
// Exception codes
// This mostly follows the RISC-V Privileged spec
// except a few add-ons for our infrastructure
// The majority of them won't be used, but it's
// good to know what they are
//////////////////////////////////////////////

typedef enum logic [3:0] {
	INST_ADDR_MISALIGN  = 4'h0,
	INST_ACCESS_FAULT   = 4'h1,
	ILLEGAL_INST        = 4'h2,
	BREAKPOINT          = 4'h3,
	LOAD_ADDR_MISALIGN  = 4'h4,
	LOAD_ACCESS_FAULT   = 4'h5,
	STORE_ADDR_MISALIGN = 4'h6,
	STORE_ACCESS_FAULT  = 4'h7,
	ECALL_U_MODE        = 4'h8,
	ECALL_S_MODE        = 4'h9,
	NO_ERROR            = 4'ha, //a reserved code that we modified for our purpose
	ECALL_M_MODE        = 4'hb,
	INST_PAGE_FAULT     = 4'hc,
	LOAD_PAGE_FAULT     = 4'hd,
	HALTED_ON_WFI       = 4'he, //another reserved code that we used
	STORE_PAGE_FAULT    = 4'hf
} EXCEPTION_CODE;


//////////////////////////////////////////////
//
// Datapath control signals
//
//////////////////////////////////////////////

//
// ALU opA input mux selects
//
typedef enum logic [1:0] {
	OPA_IS_RS1  = 2'h0,
	OPA_IS_NPC  = 2'h1,
	OPA_IS_PC   = 2'h2,
	OPA_IS_ZERO = 2'h3
} ALU_OPA_SELECT;

//
// ALU opB input mux selects
//
typedef enum logic [3:0] {
	OPB_IS_RS2    = 4'h0,
	OPB_IS_I_IMM  = 4'h1,
	OPB_IS_S_IMM  = 4'h2,
	OPB_IS_B_IMM  = 4'h3,
	OPB_IS_U_IMM  = 4'h4,
	OPB_IS_J_IMM  = 4'h5
} ALU_OPB_SELECT;

//
// Destination register select
//
typedef enum logic [1:0] {
	DEST_RD = 2'h0,
	DEST_NONE  = 2'h1
} DEST_REG_SEL;

//
// ALU function code input
// probably want to leave these alone
//
typedef enum logic [4:0] {
	ALU_ADD     = 5'h00,
	ALU_SUB     = 5'h01,
	ALU_SLT     = 5'h02,
	ALU_SLTU    = 5'h03,
	ALU_AND     = 5'h04,
	ALU_OR      = 5'h05,
	ALU_XOR     = 5'h06,
	ALU_SLL     = 5'h07,
	ALU_SRL     = 5'h08,
	ALU_SRA     = 5'h09,
	ALU_MUL     = 5'h0a,
	ALU_MULH    = 5'h0b,
	ALU_MULHSU  = 5'h0c,
	ALU_MULHU   = 5'h0d,
	ALU_DIV     = 5'h0e,
	ALU_DIVU    = 5'h0f,
	ALU_REM     = 5'h10,
	ALU_REMU    = 5'h11
} ALU_FUNC;

//////////////////////////////////////////////
//
// Assorted things it is not wise to change
//
//////////////////////////////////////////////

//
// actually, you might have to change this if you change VERILOG_CLOCK_PERIOD
// JK you don't ^^^
//
`define SD #1


// the RISCV register file zero register, any read of this register always
// returns a zero value, and any write to this register is thrown away
//
`define ZERO_REG 5'd0

//
// Memory bus commands control signals
//
typedef enum logic [1:0] {
	BUS_NONE     = 2'h0,
	BUS_LOAD     = 2'h1,
	BUS_STORE    = 2'h2
} BUS_COMMAND;

typedef enum logic [2:0] {
	LB   = 3'b000,
	LH     = 3'b001,
	LW    = 3'b010,
	LBU		= 3'b100,
	LHU		= 3'b101
} LOAD_COMMAND;
`ifndef CACHE_MODE
typedef enum logic [1:0] {
	BYTE = 2'h0,
	HALF = 2'h1,
	WORD = 2'h2,
	DOUBLE = 2'h3
} MEM_SIZE;
`endif
//
// useful boolean single-bit definitions
//
`define FALSE  1'h0
`define TRUE  1'h1

// RISCV ISA SPEC
`define XLEN 32
typedef union packed {
	logic [31:0] inst;
	struct packed {
		logic [6:0] funct7;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] funct3;
		logic [4:0] rd;
		logic [6:0] opcode;
	} r; //register to register instructions
	struct packed {
		logic [11:0] imm;
		logic [4:0]  rs1; //base
		logic [2:0]  funct3;
		logic [4:0]  rd;  //dest
		logic [6:0]  opcode;
	} i; //immediate or load instructions
	struct packed {
		logic [6:0] off; //offset[11:5] for calculating address
		logic [4:0] rs2; //source
		logic [4:0] rs1; //base
		logic [2:0] funct3;
		logic [4:0] set; //offset[4:0] for calculating address
		logic [6:0] opcode;
	} s; //store instructions
	struct packed {
		logic       of; //offset[12]
		logic [5:0] s;   //offset[10:5]
		logic [4:0] rs2;//source 2
		logic [4:0] rs1;//source 1
		logic [2:0] funct3;
		logic [3:0] et; //offset[4:1]
		logic       f;  //offset[11]
		logic [6:0] opcode;
	} b; //branch instructions
	struct packed {
		logic [19:0] imm;
		logic [4:0]  rd;
		logic [6:0]  opcode;
	} u; //upper immediate instructions
	struct packed {
		logic       of; //offset[20]
		logic [9:0] et; //offset[10:1]
		logic       s;  //offset[11]
		logic [7:0] f;	//offset[19:12]
		logic [4:0] rd; //dest
		logic [6:0] opcode;
	} j;  //jump instructions
`ifdef ATOMIC_EXT
	struct packed {
		logic [4:0] funct5;
		logic       aq;
		logic       rl;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] funct3;
		logic [4:0] rd;
		logic [6:0] opcode;
	} a; //atomic instructions
`endif
`ifdef SYSTEM_EXT
	struct packed {
		logic [11:0] csr;
		logic [4:0]  rs1;
		logic [2:0]  funct3;
		logic [4:0]  rd;
		logic [6:0]  opcode;
	} sys; //system call instructions
`endif

} INST; //instruction typedef, this should cover all types of instructions

//
// Basic NOP instruction.  Allows pipline registers to clearly be reset with
// an instruction that does nothing instead of Zero which is really an ADDI x0, x0, 0
//
`define NOP 32'h00000013

//////////////////////////////////////////////
//
// IF Packets:
// Data that is exchanged between the IF and the ID stages  
//
//////////////////////////////////////////////

typedef struct packed {
	logic valid; // If low, the data in this struct is garbage
    INST  inst;  // fetched instruction out
	logic [`XLEN-1:0] NPC; // PC + 4
	logic [`XLEN-1:0] PC;  // PC 
	logic take;
	logic [`XLEN-1:0] targetpc;
} IF_ID_PACKET;

//////////////////////////////////////////////
//
// ID Packets:
// Data that is exchanged from ID to EX stage
//
//////////////////////////////////////////////

typedef struct packed {
	logic [`XLEN-1:0] NPC;   // PC + 4
	logic [`XLEN-1:0] PC;    // PC

	logic [`XLEN-1:0] rs1_value;    // reg A value                                  
	logic [`XLEN-1:0] rs2_value;    // reg B value                                  
	                                                                                
	ALU_OPA_SELECT opa_select; // ALU opa mux select (ALU_OPA_xxx *)
	ALU_OPB_SELECT opb_select; // ALU opb mux select (ALU_OPB_xxx *)
	INST inst;                 // instruction
	
	logic [4:0] dest_reg_idx;  // destination (writeback) register index      
	ALU_FUNC    alu_func;      // ALU function select (ALU_xxx *)
	logic       rd_mem;        // does inst read memory?
	logic       wr_mem;        // does inst write memory?
	logic       cond_branch;   // is inst a conditional branch?
	logic       uncond_branch; // is inst an unconditional branch?
	logic       halt;          // is this a halt?
	logic       illegal;       // is this instruction illegal?
	logic       csr_op;        // is this a CSR operation? (we only used this as a cheap way to get return code)
	logic       valid;         // is inst a valid instruction to be counted for CPI calculations?
} ID_EX_PACKET;

typedef struct packed {
	logic [`XLEN-1:0] alu_result; // alu_result
	logic [`XLEN-1:0] NPC; //pc + 4
	logic             take_branch; // is this a taken branch?
	//pass throughs from decode stage
	logic [`XLEN-1:0] rs2_value;
	logic             rd_mem, wr_mem;
	logic [4:0]       dest_reg_idx;
	logic             halt, illegal, csr_op, valid;
	logic [2:0]       mem_size; // byte, half-word or word
} EX_MEM_PACKET;

 // __SYS_DEFS_VH__

`define WIDTH 2
`define RS_SIZE 8
`define PRF_SIZE 64
`define RF_SIZE 32
`define FL_SIZE 32
`define BTB_SIZE 256
`define ROB_SIZE 32
`define NUM_STAGE 2
`define LQ_SIZE 8
`define SQ_SIZE 8
`define CACHE_LINES 32
`define CACHE_LINE_BITS $clog2(`CACHE_LINES)
typedef union packed{
    logic [63:0] double;
    logic [1:0][31:0] words;
    logic [3:0][15:0] halves;
    logic [7:0][7:0] bytes;
} CACHE_BLOCK;
typedef struct packed {
	CACHE_BLOCK                     data;
    logic [28 - `CACHE_LINE_BITS:0]  tags;
    logic                            valids;
    //logic [`XLEN-1:0] address;
} DCACHE_PACKET;
typedef struct packed {
	logic [63:0]                     data;
    logic [12 - `CACHE_LINE_BITS:0]  tags;
    logic                            valids;
} ICACHE_PACKET;
typedef struct packed {
	logic [63:0]                     data;
    logic [12 - `CACHE_LINE_BITS:0]  tags;
    logic                            valids;
	logic [`CACHE_LINE_BITS - 1:0]   idx;
} VCACHE_PACKET;
typedef enum logic [1:0] {
	BYTE = 2'h0,
	HALF = 2'h1,
	WORD = 2'h2,
	DOUBLE = 2'h3
} MEM_SIZE;
typedef struct packed {
    INST inst;
	ALU_FUNC    alu_func; 
	//logic [4:0] dest_reg_idx;     
	logic       rd_mem;       
	logic       wr_mem;      
	logic       halt;       
	logic       cond_branch;   
	logic       uncond_branch; 
	logic       csr_op;        
    logic [`XLEN-1:0] NPC;   
	logic [`XLEN-1:0] PC;   
	logic [`XLEN-1:0] targetpc;
	logic       valid;
	logic       illegal;
	logic		take;
	ALU_OPA_SELECT opa_select; 
	ALU_OPB_SELECT opb_select;
	logic 		destzero;
	logic		regonezero;
	logic		regtwozero;
} ID_PACKET;
typedef struct packed {
    logic   complete;
    logic   [$clog2(`PRF_SIZE)-1:0] p;
} CDB;
typedef struct packed {
    logic [$clog2(`PRF_SIZE)-1:0] T1;
    logic [$clog2(`PRF_SIZE)-1:0] T2;
    logic   T1_enable;
    logic   T2_enable;
    logic [$clog2(`PRF_SIZE)-1:0] T;
    logic   busy;
    ID_PACKET    rspack;
   // logic [$clog2(`RS_SIZE):0]   counter;
    logic   issue_en;
	logic [$clog2(`LQ_SIZE)-1:0] 	lqp;
	logic [$clog2(`SQ_SIZE)-1:0] 	sqp;

    //logic   issue_complete;
} RS_entry;
typedef struct packed {
    logic [$clog2(`PRF_SIZE)-1:0] T1;
    logic [$clog2(`PRF_SIZE)-1:0] T2;
    logic [$clog2(`PRF_SIZE)-1:0] T;
    ID_PACKET    rspack1;
	logic [$clog2(`LQ_SIZE)-1:0] 	lqp;
	logic [$clog2(`SQ_SIZE)-1:0] 	sqp;

	//logic	vali;
} toissue_packet;
typedef struct packed {
	logic [9:0] tag;
	logic [11:0] target;
	logic [1:0] direction;
} BTB1;
typedef struct packed {
	logic [$clog2(`PRF_SIZE)-1:0] tag;
	logic ready;
} Maptable1;
typedef struct packed {
	logic [$clog2(`PRF_SIZE)-1:0] tag;
	logic [`XLEN-1:0] val;
	logic busy;
} ex_buffer;
typedef struct packed {
	logic [$clog2(`PRF_SIZE)-1:0] tag;
	logic retire_en;
} retire_packet;
typedef struct packed {
	logic [$clog2(`PRF_SIZE)-1:0] T;
	logic [$clog2(`PRF_SIZE)-1:0] T_hold;
	logic illegal;
	logic halt;
	logic complete;
	logic isbranch;
	logic rollback;
	logic mispredict;
	logic ldex;
	//logic take;
	logic [`XLEN-1:0] targetpc;
	logic [`XLEN-1:0] pc;
	logic [$clog2(`RF_SIZE)-1:0] destreg;
	logic store;
	logic load;
	logic uncond;
} ROB1;
typedef struct packed {
	logic [`XLEN-1:0] address;
	logic valid;
	logic [`XLEN-1:0] data;
	logic [2:0] st_memsize;		
} sq;
typedef struct packed {
	logic [`XLEN-1:0] address;
	logic [`XLEN-1:0] pc;
	logic valid;
	logic [$clog2(`ROB_SIZE)-1:0] robnum;
} lq;
typedef struct packed {
		logic busy;
		logic complete;
		logic [$clog2(`PRF_SIZE)-1:0] tag;
		logic [`XLEN-1:0] val;
		logic [2:0] ld_memsize;		
		logic [`XLEN-1:0] address;
} loadwl1;
   // new_sys_defs

	//D stage

	typedef struct packed {
		logic [$clog2(`PRF_SIZE)-1:0] t1;
		logic [$clog2(`PRF_SIZE)-1:0] t2;
		logic t1_enable;
		logic t2_enable;
	} MapT_RS_packet;
	typedef struct packed {
		logic [$clog2(`RF_SIZE)-1:0] regnum;
		logic retire_en;
	} MapT_ARF_packet;

	//I stage



	typedef struct packed {
		ID_PACKET decode_packet;
		logic [$clog2(`PRF_SIZE)-1:0] T;
		logic [`XLEN-1:0] value1;
		logic [`XLEN-1:0] value2;
		logic [$clog2(`LQ_SIZE)-1:0] 	lqp;
		logic [$clog2(`SQ_SIZE)-1:0] 	sqp;
	} I_EX_packet;


	//EX stage
	typedef struct packed {
		logic free;
		logic [$clog2(`PRF_SIZE)-1:0] T;
	} EX_RS_packet;


	typedef struct packed {
		CDB cdb_pack;
		logic [`XLEN-1:0] value_complete;
	} EX_C_packet;
	typedef struct packed {
		logic [$clog2(`PRF_SIZE)-1:0] T;
		logic mispredict;
		logic [`XLEN-1:0]targetpc;
		logic [`XLEN-1:0]pc;
		logic isbranch;
		logic uncond;
	} EX_ROB_packet;
	typedef struct packed {
		logic [`XLEN-1:0] pc;
		//logic [`XLEN-1:0] npc;
		logic [`XLEN-1:0] targetpc;
		logic mispredict;
		logic isbranch;
		logic uncond;
		//logic [$clog2(`PRF_SIZE)-1:0] tag;
	} ROB_BTB_packet;
	/*typedef struct packed {
		logic rb_signal; 	
		logic [$clog2(`PRF_SIZE)-1:0] tag;
		logic [`XLEN-1:0] except_pc;
	} BTB_ROB_packet;*/
	//C stage


	typedef struct packed {
		logic retire_en;
		logic [$clog2(`PRF_SIZE)-1:0] t_hold;
		//logic rollback_en;
		//logic [$clog2(`PRF_SIZE)-1:0] t;

	} ROB_FL_packet;
	typedef struct packed {
		logic retire_en;
		//logic [$clog2(`PRF_SIZE)-1:0] t_hold;
		//logic rollback_en;
		logic [$clog2(`PRF_SIZE)-1:0] t;
		logic [$clog2(`RF_SIZE)-1:0] regnum;

	} ROB_PRF_packet;









`endif