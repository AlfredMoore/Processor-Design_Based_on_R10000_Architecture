`timescale 1ns/100ps

module ROB (
	input clock,
	input reset,
	input [`WIDTH-1:0] [$clog2(`RF_SIZE)-1:0] destreg,
	input [`WIDTH-1:0] dispatch_en,
	input [`WIDTH-1:0] illegal,
	input [`WIDTH-1:0] halt,
	input [`WIDTH-1:0] storeen,
	input [`WIDTH-1:0] loaden,
	input clean,
	//input ID_DISP_PACKET [`WIDTH-1:0] packet,
	//from ldq
	input logic [`LQ_SIZE-1:0][$clog2(`ROB_SIZE)-1:0] ldqrobnum,
	input logic [`LQ_SIZE-1:0] ldexception,
	input logic [`LQ_SIZE-1:0] [`XLEN-1:0] ldexpc,
	//input from mt
	input [`WIDTH-1:0][$clog2(`PRF_SIZE)-1:0] tag_old,
	//input from fl
	input [`WIDTH-1:0][$clog2(`PRF_SIZE)-1:0] free_reg,
	//complete
	input CDB [`WIDTH-1:0] cdb,
	//branch
	input EX_ROB_packet [`WIDTH-1:0] ex_packet,
	input loading,
	input storeing,
	//update btb
	output ROB_BTB_packet [`WIDTH-1:0] tobtb_packet,
	//retire
	output ROB_FL_packet [`WIDTH-1:0] tofl_packet,
	output ROB_PRF_packet [`WIDTH-1:0] toprf_packet,
	output logic [`WIDTH-1:0] loadretire,
	output logic storeretire,
	output logic [$clog2(`RF_SIZE)-1:0] rollback_reg,
	output logic [$clog2(`PRF_SIZE)-1:0] rollback_tag,
	//to loadq
	output logic [`WIDTH-1:0][$clog2(`ROB_SIZE)-1:0] robnum,
	//rollback enable
	output logic rollback_en,
	output logic exception_en,
	output logic [$clog2(`ROB_SIZE)-1:0] recover_head,
	output logic [`XLEN-1:0]  exception_pc,
	//hazard
	output logic [`WIDTH-1:0] full,
	output logic [`WIDTH-1:0] robretire_halt,
	output logic [`WIDTH-1:0] robretire_illegal
);
	//logic ldenadd1;
	ROB1 [`ROB_SIZE-1:0] entry;
	//ROB [`ROB_SIZE-1:0] nentry;
	logic rollback_signal;
	logic exception_signal;
	logic [1:0] retire_num;
	logic [$clog2(`ROB_SIZE)-1:0] head_pointer;
	logic [$clog2(`ROB_SIZE)-1:0] tail_pointer;

	//logic [$clog2(`ROB_SIZE)-1:0] next_head;
	//logic [$clog2(`ROB_SIZE)-1:0] next_tail;
	logic [$clog2(`ROB_SIZE)-1:0] htdistance;
	logic [$clog2(`ROB_SIZE)-1:0] thdistance;
	assign thdistance = tail_pointer - head_pointer;
	assign rollback_en = rollback_signal || exception_signal;
	always_comb begin
		htdistance = head_pointer - tail_pointer;
		if(tail_pointer < head_pointer) begin
			if(htdistance == 1) begin
				full = 2'b00;
			end
			else if(htdistance == 2) begin
				if(dispatch_en) begin
					full =  2'b00;
				end
				else begin
					full = 2'b01;
				end
			end
			else if(htdistance == 3) begin
				if(dispatch_en == 2'b11) begin
					full = 2'b00;
				end
				else if(dispatch_en) begin
					full = 2'b01;
				end
				else full =2'b11;
			end
			else if(htdistance == 4) begin
				if(dispatch_en == 2'b11) begin
					full =2'b01;
				end
				else full = 2'b11;
			end
			else full = 2'b11;
		end
		else  begin
			if(tail_pointer == `ROB_SIZE - 1) begin
				if(head_pointer == 0)begin
					full = 2'b00;
				end
				else if(head_pointer == 1) begin
					if(dispatch_en) begin
						full = 2'b00;
					end
					else begin
						full =2'b01;
					end
				end
				else if(head_pointer == 2) begin
					if(dispatch_en == 2'b11) begin
						full = 2'b0;
					end
					else if(dispatch_en) begin
						full =2'b01;
					end
					else full =2'b11;
				end
				else if(head_pointer == 3) begin
					if(dispatch_en == 2'b11) begin
						full = 2'b01;
					end
					else full =2'b11;
				end
				else full =2'b11;
			end
			else if(tail_pointer == `ROB_SIZE - 2) begin
				if(head_pointer == 0)begin
					if(dispatch_en) begin
						full = 2'b00;
					end
					else full = 2'b01;
				end
				else if(head_pointer == 1) begin
					if(dispatch_en == 2'b11) begin
						full = 2'b00;
					end
					else if(dispatch_en) begin
						full =2'b01;
					end
					else full =2'b11;
				end
				else if(head_pointer == 2) begin
					if(dispatch_en == 2'b11) begin
						full = 2'b01;
					end
					else full =2'b11;
				end
				else full =2'b11;
			end
			else if(tail_pointer == `ROB_SIZE - 3) begin
				if(head_pointer == 0) begin
					if(dispatch_en == 2'b11) begin
						full = 2'b00;
					end
					else if(dispatch_en) begin
						full = 2'b01;
					end
					else full = 2'b11;
				end
				else if(head_pointer == 1) begin
					if(dispatch_en == 2'b11) begin
						full = 2'b01;
					end
					else full =2'b11;
				end
				else full =2'b11;
			end
			else if(tail_pointer == `ROB_SIZE - 4) begin
				if(head_pointer == 0) begin
					if(dispatch_en == 2'b11) begin
						full =2'b01;
					end
					else full = 2'b11;
				end
				else full =2'b11;
			end
			else full =2'b11;
		end		
	end
	//to ldq
	always_comb begin
		robnum = 0;
		if(dispatch_en == 2'b11) begin
			robnum[0] = tail_pointer;
			if(tail_pointer == `ROB_SIZE - 1) begin
				robnum[1] = 0;
			end
			else robnum[1] = tail_pointer + 1;
		end
		else if(dispatch_en == 2'b01) begin
			robnum[0] = tail_pointer;
		end
		else if(dispatch_en == 2'b10) begin
			robnum[1] = tail_pointer;
		end
		else robnum = 0;
	end
	//retire and rollback
	always_comb begin
		tofl_packet = 0;
		toprf_packet = 0;
		tobtb_packet = 0;
		rollback_signal = 0;
		exception_signal = 0;
		recover_head = 0;
		exception_en = 0;
		exception_pc = 0;
		retire_num = 0;
		robretire_halt = 0;
		robretire_illegal = 0;
		storeretire = 0;
		loadretire = 0;
		rollback_reg = 0;
		rollback_tag = 0;
		if(clean ) begin
		tofl_packet = 0;
		toprf_packet = 0;
		tobtb_packet = 0;
		rollback_signal = 0;
		exception_signal = 0;
		recover_head = 0;
		exception_en = 0;
		exception_pc = 0;
		retire_num = 0;
		robretire_illegal = 0;
		storeretire = 0;
		loadretire = 0;
		rollback_reg = 0;
		rollback_tag = 0;
		end
		else begin
		if(entry[head_pointer].complete) begin
			if(!entry[head_pointer].rollback && !entry[head_pointer].ldex && !((loading||storeing) && (entry[head_pointer].store || entry[head_pointer].halt)) && (head_pointer != tail_pointer))begin
				tofl_packet[0].retire_en = 1;
				tofl_packet[0].t_hold = entry[head_pointer].T_hold;
				toprf_packet[0].retire_en = 1;
				robretire_halt[0] = entry[head_pointer].halt;
				robretire_illegal[0] = entry[head_pointer].illegal;
				toprf_packet[0].t = entry[head_pointer].T;
				toprf_packet[0].regnum = entry[head_pointer].destreg;
				storeretire = entry[head_pointer].store;
				loadretire[0] = entry[head_pointer].load;
				if(entry[head_pointer].isbranch) begin
					tobtb_packet[0].pc = entry[head_pointer].pc;
					tobtb_packet[0].targetpc = entry[head_pointer].targetpc;
					tobtb_packet[0].isbranch = 1;
					tobtb_packet[0].mispredict = entry[head_pointer].mispredict;
					tobtb_packet[0].uncond = entry[head_pointer].uncond;
				end
				else begin
					tobtb_packet[0] = 0;
				end
	

				if(head_pointer == `ROB_SIZE-1) begin
					if(!robretire_halt[0] && entry[0].complete && (!entry[0].rollback) && !(entry[head_pointer].store && entry[0].store) && !((loading||storeing) && (entry[0].store || entry[0].halt)) && !entry[0].ldex && (head_pointer != tail_pointer)	&& (tail_pointer != 0)	&&	!(storeretire && entry[0].halt)) begin
						tofl_packet[1].retire_en = 1;
						tofl_packet[1].t_hold = entry[0].T_hold;
						toprf_packet[1].retire_en = 1;
						robretire_halt[1] = entry[0].halt;
				     	robretire_illegal[1] = entry[0].illegal;
						toprf_packet[1].t = entry[0].T;
						toprf_packet[1].regnum = entry[0].destreg;
						if(entry[0].store) begin
						storeretire = 1;
						end
						loadretire[1] = entry[0].load;

						if(entry[0].isbranch) begin
							tobtb_packet[1].pc = entry[0].pc;
							tobtb_packet[1].targetpc = entry[0].targetpc;
							tobtb_packet[1].isbranch = 1;
							tobtb_packet[1].mispredict = entry[0].mispredict;
							tobtb_packet[1].uncond = entry[0].uncond;
						end
						else begin
							tobtb_packet[1] = 0;
						end

					end
					else begin
						tofl_packet[1].retire_en = 0;
						tofl_packet[1].t_hold = entry[0].T_hold;
						toprf_packet[1].retire_en = 0;
						toprf_packet[1].t = entry[0].T;
						toprf_packet[1].regnum = entry[0].destreg;
					end
				end
				else begin
					if(!robretire_halt[0] &&  entry[head_pointer+1].complete && (!entry[head_pointer+1].rollback) 
					&& !entry[head_pointer+1].ldex && !((loading||storeing) && (entry[head_pointer+1].store || entry[head_pointer+1].halt)) && !(entry[head_pointer].store && entry[head_pointer+1].store) && (head_pointer != tail_pointer)	&& !((head_pointer < tail_pointer) && thdistance <= 2)		&&	!(storeretire && entry[head_pointer+1].halt)) begin
						tofl_packet[1].retire_en = 1;
						tofl_packet[1].t_hold = entry[head_pointer+1].T_hold;
						toprf_packet[1].retire_en = 1;
						robretire_halt[1] = entry[head_pointer+1].halt;
				     	robretire_illegal[1] = entry[head_pointer+1].illegal;
						toprf_packet[1].t = entry[head_pointer+1].T;
						toprf_packet[1].regnum = entry[head_pointer+1].destreg;
						if(entry[head_pointer+1].store) begin
						storeretire = 1;
						end
						loadretire[1] = entry[head_pointer+1].load;
						if(entry[head_pointer+1].isbranch) begin
							tobtb_packet[1].pc = entry[head_pointer+1].pc;
							tobtb_packet[1].targetpc = entry[head_pointer+1].targetpc;
							tobtb_packet[1].isbranch = 1;
							tobtb_packet[1].mispredict = entry[head_pointer+1].mispredict;
							tobtb_packet[1].uncond = entry[head_pointer+1].uncond;
						end
						else begin
							tobtb_packet[1] = 0;
						end
					end
					else begin
						tofl_packet[1].retire_en = 0;
						tofl_packet[1].t_hold = entry[head_pointer+1].T_hold;
						toprf_packet[1].retire_en = 0;
						toprf_packet[1].t = entry[head_pointer+1].T;
						toprf_packet[1].regnum = entry[head_pointer+1].destreg;
					end
				end
			end
			else if(entry[head_pointer].rollback && !entry[head_pointer].ldex && !storeing )begin // rollback
				rollback_signal = 1;
				rollback_reg = entry[head_pointer].destreg;
				rollback_tag = entry[head_pointer].T;
				exception_pc = entry[head_pointer].targetpc;
				if(head_pointer == `ROB_SIZE -1 )begin
					recover_head = 0;
				end
				else begin
					recover_head = head_pointer + 1;
				end
				
			end
			else if(entry[head_pointer].ldex && !storeing) begin // ld exception
				exception_en = 1;
				exception_signal = 1;
				recover_head = head_pointer;
				exception_pc = entry[head_pointer].pc;
			end
		end
		else begin
			tofl_packet = 0;
			toprf_packet = 0;
		end
		end
		retire_num = tofl_packet[0].retire_en + tofl_packet[1].retire_en;
	end

	always_ff@(posedge clock) begin
		if(reset || robretire_halt) begin
			entry <= 0;
			head_pointer <= 0;
			tail_pointer <= 0; 
		end
		else if(rollback_signal) begin
			if(head_pointer == `ROB_SIZE -1) begin
				tail_pointer <= 0;
				//entry[0] <= 0;
			end
			else begin
				tail_pointer <= head_pointer +1;
				//entry[head_pointer + 1] <= 0;
			end
			entry[head_pointer].rollback <= 0;
			for(int p = 0; p <`ROB_SIZE; p ++ ) begin
				if(head_pointer != p) begin
					entry[p] <=0;
				end
			end
		end
		else if(exception_signal) begin
			tail_pointer <= head_pointer;
			entry <= 0;
		end
		else begin

				for(int f = 0; f<`WIDTH; f++) begin
					if(cdb[f].complete) begin
						for(int e =0; e<`ROB_SIZE; e++) begin
							if((cdb[f].p == entry[e].T) && (entry[e].T != entry[e].T_hold)) begin
								entry[e].complete <= 1;
							end
						end
					end
				end
			case(retire_num)
				2'b00: begin head_pointer <= head_pointer;
							case(dispatch_en)
								2'b00: begin tail_pointer <= tail_pointer;
									
								end
								2'b01: begin if(tail_pointer == 31) begin
												tail_pointer <= 0;
								end
								else begin
											tail_pointer <= tail_pointer + 1;
								end
											entry[tail_pointer].T <= free_reg[0];
											entry[tail_pointer].T_hold <= tag_old[0];
											entry[tail_pointer].destreg <= destreg[0];
											entry[tail_pointer].complete <= 0;
											entry[tail_pointer].isbranch <= 0;
											entry[tail_pointer].rollback <= 0;
											entry[tail_pointer].mispredict <= 0;
											entry[tail_pointer].ldex <= 0;
											entry[tail_pointer].targetpc <= 0;
											entry[tail_pointer].pc <= 0;
											entry[tail_pointer].illegal <= illegal[0];
											entry[tail_pointer].halt <= halt[0];
											entry[tail_pointer].destreg <= destreg[0];
											entry[tail_pointer].store <= storeen[0];
											entry[tail_pointer].load <= loaden[0];
								end
								2'b10: begin if(tail_pointer == 31) begin
												tail_pointer <= 0;
								end
								else begin
											tail_pointer <= tail_pointer + 1;
								end
											entry[tail_pointer].T <= free_reg[1];
											entry[tail_pointer].T_hold <= tag_old[1];
											entry[tail_pointer].destreg <= destreg[1];
											entry[tail_pointer].illegal <= illegal[1];
											entry[tail_pointer].halt <= halt[1];
											entry[tail_pointer].complete <= 0;
											entry[tail_pointer].isbranch <= 0;
											entry[tail_pointer].rollback <= 0;
											entry[tail_pointer].mispredict <= 0;
											entry[tail_pointer].ldex <= 0;
											entry[tail_pointer].targetpc <= 0;
											entry[tail_pointer].pc <= 0;
											entry[tail_pointer].store <= storeen[1];											
											entry[tail_pointer].load <= loaden[1];											
								end
								2'b11: begin if(tail_pointer == 31) begin
									tail_pointer <= 1;
									entry[tail_pointer].T <= free_reg[0];
									entry[tail_pointer].T_hold <= tag_old[0];
									entry[tail_pointer].destreg <= destreg[0];
									entry[tail_pointer].illegal <= illegal[0];
									entry[tail_pointer].halt <= halt[0];
									entry[tail_pointer].complete <= 0;
									entry[tail_pointer].isbranch <= 0;
									entry[tail_pointer].rollback <= 0;
									entry[tail_pointer].mispredict <= 0;
									entry[tail_pointer].ldex <= 0;
									entry[tail_pointer].targetpc <= 0;
									entry[tail_pointer].pc <= 0;
									entry[tail_pointer].store <= storeen[0];									
									entry[tail_pointer].load <= loaden[0];									
									entry[0].T <= free_reg[1];
									entry[0].T_hold <= tag_old[1];
									entry[0].destreg <= destreg[1];
									entry[0].illegal <= illegal[1];
									entry[0].halt <= halt[1];
									entry[0].complete <= 0;
									entry[0].isbranch <= 0;
									entry[0].rollback <= 0;
									entry[0].mispredict <= 0;
									entry[0].ldex <= 0;
									entry[0].targetpc <= 0;
									entry[0].pc <= 0;
									entry[0].store <= storeen[1];
									entry[0].load <= loaden[1];
								end
								else if (tail_pointer == 30) begin
									tail_pointer <= 0;
									entry[tail_pointer].T <= free_reg[0];
									entry[tail_pointer].T_hold <= tag_old[0];
									entry[tail_pointer].destreg <= destreg[0];
									entry[tail_pointer].illegal <= illegal[0];
									entry[tail_pointer].halt <= halt[0];
									entry[tail_pointer].complete <= 0;
									entry[tail_pointer].isbranch <= 0;
									entry[tail_pointer].rollback <= 0;
									entry[tail_pointer].ldex <= 0;
									entry[tail_pointer].mispredict <= 0;
									entry[tail_pointer].targetpc <= 0;
									entry[tail_pointer].pc <= 0;
									entry[tail_pointer].store <= storeen[0];
									entry[tail_pointer].load <= loaden[0];									
									entry[31].T <= free_reg[1];
									entry[31].T_hold <= tag_old[1];
									entry[31].destreg <= destreg[1];
									entry[31].illegal <= illegal[1];
									entry[31].halt <= halt[1];
									entry[31].complete <= 0;
									entry[31].isbranch <= 0;
									entry[31].rollback <= 0;
									entry[31].ldex <= 0;
									entry[31].mispredict <= 0;
									entry[31].targetpc <= 0;
									entry[31].pc <= 0;	
									entry[31].store <= storeen[1];
									entry[31].load <= loaden[1];
								end
								else begin 
									tail_pointer <= tail_pointer + 2;
									entry[tail_pointer].T <= free_reg[0];
									entry[tail_pointer].T_hold <= tag_old[0];
									entry[tail_pointer].destreg <= destreg[0];
									entry[tail_pointer].illegal <= illegal[0];
									entry[tail_pointer].halt <= halt[0];
									entry[tail_pointer].complete <= 0;
									entry[tail_pointer].isbranch <= 0;
									entry[tail_pointer].rollback <= 0;
									entry[tail_pointer].ldex <= 0;
									entry[tail_pointer].mispredict <= 0;
									entry[tail_pointer].targetpc <= 0;
									entry[tail_pointer].pc <= 0;
									entry[tail_pointer].store <= storeen[0];
									entry[tail_pointer].load <= loaden[0];
									entry[tail_pointer+1].T <= free_reg[1];
									entry[tail_pointer+1].T_hold <= tag_old[1];
									entry[tail_pointer+1].destreg <= destreg[1];
									entry[tail_pointer+1].illegal <= illegal[1];
									entry[tail_pointer+1].halt <= halt[1];
									entry[tail_pointer+1].complete <= 0;
									entry[tail_pointer+1].isbranch <= 0;
									entry[tail_pointer+1].rollback <= 0;
									entry[tail_pointer+1].ldex <= 0;
									entry[tail_pointer+1].mispredict <= 0;
									entry[tail_pointer+1].targetpc <= 0;
									entry[tail_pointer+1].pc <= 0;
									entry[tail_pointer+1].store <= storeen[1];
									entry[tail_pointer+1].load <= loaden[1];
								end
								end
							endcase
				end



				2'b01: begin entry[head_pointer] <= 0;
							if(head_pointer == 31) begin
								head_pointer <= 0;
							end
							else begin
								head_pointer <= head_pointer + 1;
							end	
							case(dispatch_en)
								2'b00: begin tail_pointer <= tail_pointer;
											
								end
								2'b01: begin if(tail_pointer == 31) begin
												tail_pointer <= 0;
								end
								else begin
											tail_pointer <= tail_pointer + 1;
								end
											entry[tail_pointer].T <= free_reg[0];
											entry[tail_pointer].T_hold <= tag_old[0];
											entry[tail_pointer].destreg <= destreg[0];
											entry[tail_pointer].illegal <= illegal[0];
											entry[tail_pointer].halt <= halt[0];
											entry[tail_pointer].complete <= 0;
											entry[tail_pointer].isbranch <= 0;
											entry[tail_pointer].rollback <= 0;
											entry[tail_pointer].ldex <= 0;
											entry[tail_pointer].mispredict <= 0;
											entry[tail_pointer].targetpc <= 0;
											entry[tail_pointer].pc <= 0;
											entry[tail_pointer].store <= storeen[0];
											entry[tail_pointer].load <= loaden[0];
								end
								2'b10: begin if(tail_pointer == 31) begin
												tail_pointer <= 0;
								end
								else begin
											tail_pointer <= tail_pointer + 1;
								end
											entry[tail_pointer].T <= free_reg[1];
											entry[tail_pointer].T_hold <= tag_old[1];
											entry[tail_pointer].destreg <= destreg[1];
											entry[tail_pointer].illegal <= illegal[1];
											entry[tail_pointer].halt <= halt[1];
											entry[tail_pointer].complete <= 0;
											entry[tail_pointer].isbranch <= 0;
											entry[tail_pointer].rollback <= 0;
											entry[tail_pointer].ldex <= 0;
											entry[tail_pointer].mispredict <= 0;
											entry[tail_pointer].targetpc <= 0;
											entry[tail_pointer].pc <= 0;
											entry[tail_pointer].store <= storeen[1];
											entry[tail_pointer].load <= loaden[1];
								end
								2'b11: begin if(tail_pointer == 31) begin
									tail_pointer <= 1;
									entry[tail_pointer].T <= free_reg[0];
									entry[tail_pointer].T_hold <= tag_old[0];
									entry[tail_pointer].destreg <= destreg[0];
									entry[tail_pointer].illegal <= illegal[0];
									entry[tail_pointer].halt <= halt[0];
									entry[tail_pointer].complete <= 0;
									entry[tail_pointer].isbranch <= 0;
									entry[tail_pointer].rollback <= 0;
									entry[tail_pointer].ldex <= 0;
									entry[tail_pointer].mispredict <= 0;
									entry[tail_pointer].targetpc <= 0;
									entry[tail_pointer].pc <= 0;
									entry[tail_pointer].store <= storeen[0];
									entry[tail_pointer].load <= loaden[0];
									entry[0].T <= free_reg[1];
									entry[0].T_hold <= tag_old[1];
									entry[0].destreg <= destreg[1];
									entry[0].illegal <= illegal[1];
									entry[0].halt <= halt[1];
									entry[0].complete <= 0;
									entry[0].isbranch <= 0;
									entry[0].rollback <= 0;
									entry[0].ldex <= 0;
									entry[0].mispredict <= 0;
									entry[0].targetpc <= 0;
									entry[0].pc <= 0;
									entry[0].store <= storeen[1];
									entry[0].load <= loaden[1];
								end
								else if (tail_pointer == 30) begin
									tail_pointer <= 0;
									entry[tail_pointer].T <= free_reg[0];
									entry[tail_pointer].T_hold <= tag_old[0];
									entry[tail_pointer].destreg <= destreg[0];
									entry[tail_pointer].illegal <= illegal[0];
									entry[tail_pointer].halt <= halt[0];
									entry[tail_pointer].complete <= 0;
									entry[tail_pointer].isbranch <= 0;
									entry[tail_pointer].rollback <= 0;
									entry[tail_pointer].ldex <= 0;
									entry[tail_pointer].mispredict <= 0;
									entry[tail_pointer].targetpc <= 0;
									entry[tail_pointer].pc <= 0;
									entry[tail_pointer].store <= storeen[0];
									entry[tail_pointer].load <= loaden[0];
									entry[31].T <= free_reg[1];
									entry[31].T_hold <= tag_old[1];
									entry[31].destreg <= destreg[1];
									entry[31].illegal <= illegal[1];
									entry[31].halt <= halt[1];
									entry[31].complete <= 0;
									entry[31].isbranch <= 0;
									entry[31].rollback <= 0;
									entry[31].ldex <= 0;
									entry[31].mispredict <= 0;
									entry[31].targetpc <= 0;
									entry[31].pc <= 0;
									entry[31].store <= storeen[1];
									entry[31].load <= loaden[1];
								end
								else begin 
									tail_pointer <= tail_pointer + 2;
									entry[tail_pointer].T <= free_reg[0];
									entry[tail_pointer].T_hold <= tag_old[0];
									entry[tail_pointer].destreg <= destreg[0];
									entry[tail_pointer].illegal <= illegal[0];
									entry[tail_pointer].halt <= halt[0];
									entry[tail_pointer].complete <= 0;
									entry[tail_pointer].isbranch <= 0;
									entry[tail_pointer].rollback <= 0;
									entry[tail_pointer].ldex <= 0;
									entry[tail_pointer].mispredict <= 0;
									entry[tail_pointer].targetpc <= 0;
									entry[tail_pointer].pc <= 0;
									entry[tail_pointer].store <= storeen[0];
									entry[tail_pointer].load <= loaden[0];
									entry[tail_pointer+1].T <= free_reg[1];
									entry[tail_pointer+1].T_hold <= tag_old[1];
									entry[tail_pointer+1].destreg <= destreg[1];
									entry[tail_pointer+1].illegal <= illegal[1];
									entry[tail_pointer+1].halt <= halt[1];
									entry[tail_pointer+1].complete <= 0;
									entry[tail_pointer+1].isbranch <= 0;
									entry[tail_pointer+1].rollback <= 0;
									entry[tail_pointer+1].ldex <= 0;
									entry[tail_pointer+1].mispredict <= 0;
									entry[tail_pointer+1].targetpc <= 0;
									entry[tail_pointer+1].pc <= 0;	
									entry[tail_pointer+1].store <= storeen[1];
									entry[tail_pointer+1].load <= loaden[1];
								end
								end
							endcase
				end
				2'b10: begin entry[head_pointer] <=0;
						if(head_pointer == 31) begin
								entry[0] <= 0;
								head_pointer <= 1;
						end
						else if(head_pointer == 30) begin
							entry[head_pointer+1] <=0;
							head_pointer <= 0;
						end
						else begin
							entry[head_pointer+1] <=0;
							head_pointer <= head_pointer + 2;
						end
						case(dispatch_en)
								2'b00: begin tail_pointer <= tail_pointer;
											
								end
								2'b01: begin if(tail_pointer == 31) begin
												tail_pointer <= 0;
								end
								else begin
											tail_pointer <= tail_pointer + 1;
								end
											entry[tail_pointer].T <= free_reg[0];
											entry[tail_pointer].T_hold <= tag_old[0];
											entry[tail_pointer].destreg <= destreg[0];
											entry[tail_pointer].illegal <= illegal[0];
											entry[tail_pointer].halt <= halt[0];
											entry[tail_pointer].complete <= 0;
											entry[tail_pointer].isbranch <= 0;
											entry[tail_pointer].rollback <= 0;
											entry[tail_pointer].ldex <= 0;
											entry[tail_pointer].mispredict <= 0;
											entry[tail_pointer].targetpc <= 0;
											entry[tail_pointer].pc <= 0;
											entry[tail_pointer].store <= storeen[0];
											entry[tail_pointer].load <= loaden[0];
								end
								2'b10: begin if(tail_pointer == 31) begin
												tail_pointer <= 0;
								end
								else begin
											tail_pointer <= tail_pointer + 1;
								end
											entry[tail_pointer].T <= free_reg[1];
											entry[tail_pointer].T_hold <= tag_old[1];
											entry[tail_pointer].destreg <= destreg[1];
											entry[tail_pointer].illegal <= illegal[1];
											entry[tail_pointer].halt <= halt[1];
											entry[tail_pointer].complete <= 0;
											entry[tail_pointer].isbranch <= 0;
											entry[tail_pointer].rollback <= 0;
											entry[tail_pointer].ldex <= 0;
											entry[tail_pointer].mispredict <= 0;
											entry[tail_pointer].targetpc <= 0;
											entry[tail_pointer].pc <= 0;
											entry[tail_pointer].store <= storeen[1];
											entry[tail_pointer].load <= loaden[1];
								end
								2'b11: begin if(tail_pointer == 31) begin
									tail_pointer <= 1;
									entry[tail_pointer].T <= free_reg[0];
									entry[tail_pointer].T_hold <= tag_old[0];
									entry[tail_pointer].destreg <= destreg[0];
									entry[tail_pointer].illegal <= illegal[0];
									entry[tail_pointer].halt <= halt[0];
									entry[tail_pointer].complete <= 0;
									entry[tail_pointer].isbranch <= 0;
									entry[tail_pointer].rollback <= 0;
									entry[tail_pointer].ldex <= 0;
									entry[tail_pointer].mispredict <= 0;
									entry[tail_pointer].targetpc <= 0;
									entry[tail_pointer].pc <= 0;
									entry[tail_pointer].store <= storeen[0];
									entry[tail_pointer].load <= loaden[0];
									entry[0].T <= free_reg[1];
									entry[0].T_hold <= tag_old[1];
									entry[0].destreg <= destreg[1];
									entry[0].illegal <= illegal[1];
									entry[0].halt <= halt[1];
									entry[0].complete <= 0;
									entry[0].isbranch <= 0;
									entry[0].rollback <= 0;
									entry[0].ldex <= 0;
									entry[0].mispredict <= 0;
									entry[0].targetpc <= 0;
									entry[0].pc <= 0;	
									entry[0].store <= storeen[1];
									entry[0].load <= loaden[1];
								end
								else if (tail_pointer == 30) begin
									tail_pointer <= 0;
									entry[tail_pointer].T <= free_reg[0];
									entry[tail_pointer].T_hold <= tag_old[0];
									entry[tail_pointer].destreg <= destreg[0];
									entry[tail_pointer].illegal <= illegal[0];
									entry[tail_pointer].halt <= halt[0];
									entry[tail_pointer].complete <= 0;
									entry[tail_pointer].isbranch <= 0;
									entry[tail_pointer].rollback <= 0;
									entry[tail_pointer].ldex <= 0;
									entry[tail_pointer].mispredict <= 0;
									entry[tail_pointer].targetpc <= 0;
									entry[tail_pointer].pc <= 0;
									entry[tail_pointer].store <= storeen[0];
									entry[tail_pointer].load <= loaden[0];
									entry[31].T <= free_reg[1];
									entry[31].T_hold <= tag_old[1];
									entry[31].destreg <= destreg[1];
									entry[31].illegal <= illegal[1];
									entry[31].halt <= halt[1];
									entry[31].complete <= 0;
									entry[31].isbranch <= 0;
									entry[31].rollback <= 0;
									entry[31].ldex <= 0;
									entry[31].mispredict <= 0;
									entry[31].targetpc <= 0;
									entry[31].pc <= 0;	
									entry[31].store <= storeen[1];
									entry[31].load <= loaden[1];
								end
								else begin 
									tail_pointer <= tail_pointer + 2;
									entry[tail_pointer].T <= free_reg[0];
									entry[tail_pointer].T_hold <= tag_old[0];
									entry[tail_pointer].destreg <= destreg[0];
									entry[tail_pointer].illegal <= illegal[0];
									entry[tail_pointer].halt <= halt[0];
									entry[tail_pointer].complete <= 0;
									entry[tail_pointer].isbranch <= 0;
									entry[tail_pointer].rollback <= 0;
									entry[tail_pointer].ldex <= 0;
									entry[tail_pointer].mispredict <= 0;
									entry[tail_pointer].targetpc <= 0;
									entry[tail_pointer].pc <= 0;
									entry[tail_pointer].store <= storeen[0];
									entry[tail_pointer].load <= loaden[0];
									entry[tail_pointer+1].T <= free_reg[1];
									entry[tail_pointer+1].T_hold <= tag_old[1];
									entry[tail_pointer+1].destreg <= destreg[1];
									entry[tail_pointer+1].illegal <= illegal[1];
									entry[tail_pointer+1].halt <= halt[1];
									entry[tail_pointer+1].complete <= 0;
									entry[tail_pointer+1].isbranch <= 0;
									entry[tail_pointer+1].rollback <= 0;
									entry[tail_pointer+1].ldex <= 0;
									entry[tail_pointer+1].mispredict <= 0;
									entry[tail_pointer+1].targetpc <= 0;
									entry[tail_pointer+1].pc <= 0;
									entry[tail_pointer+1].store <= storeen[1];
									entry[tail_pointer+1].load <= loaden[1];
								end
								end
							endcase
				end
				
			endcase
				//mispredict
			for(int b = 0 ; b<`WIDTH; b++) begin
				if(ex_packet[b].isbranch ) begin
					for(int j = 0; j<`ROB_SIZE; j++) begin
						if(entry[j].T == ex_packet[b].T) begin
							entry[j].isbranch <= 1;
							entry[j].rollback <= ex_packet[b].mispredict;
							entry[j].mispredict <= ex_packet[b].mispredict;
							entry[j].pc <= ex_packet[b].pc;
							entry[j].targetpc <= ex_packet[b].targetpc;
							entry[j].uncond <= ex_packet[b].uncond;
						end
					end
				end
			end
				for(int k = 0; k < `LQ_SIZE; k++) begin
					if(ldexception[k]) begin
						entry[ldqrobnum[k]].ldex <= 1;
						entry[ldqrobnum[k]].pc <= ldexpc[k];
					end
				end			
				//cdb

		end
	end



							







		
			


	
			





endmodule