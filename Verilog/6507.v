`define FETCH 0
`define EXECUTE1 1
`define EXECUTE2 2
`define EXECUTE3 3
`define EXECUTE4 4
`define INDIRECT1 8
`define INDIRECT2 9
`define JSR1 10
`define JSR2 11
`define JSR3 12
`define RET1 13
`define RET2 14
`define RET3 15

module CPU_6507(
	output [12:0] addr_bus,
	output reg [7:0] d_out,
	input [7:0] d_in,
	output reg wenb,
	
	input clk,
	input rstb,
	input rdy
);

reg [7:0] A;
reg [7:0] X;
reg [7:0] Y;
reg carry;
reg intr_disable;
reg overflow;
reg decimal;
reg [7:0] stack_ptr;
reg negative;
reg zero;

reg [15:0] PC;
reg [15:0] full_addr;
assign addr_bus = full_addr[12:0];

reg [7:0] addr_in_buff;

reg [7:0] I;
reg is_reset;
reg [3:0] phase;

wire [7:0] instr = phase == `EXECUTE1 ? d_in : I;

// Decode logic
wire isNOP = instr == 8'hEA;

wire isLoadOrStore = instr[7:6] == 2'b10 && !isNOP && !(
		instr == 8'h90 ||
		instr == 8'hB0 ||
		instr[3:0] == 4'h8 ||
		instr[3:0] == 4'hA
	);
wire isLoad = isLoadOrStore && instr[5];
wire isStore = isLoadOrStore && !instr[5];

wire isJSR = instr == 8'h20;
wire isRTS = instr == 8'h60;
wire isRTI = instr == 8'h40;
wire isTransfer = instr == 8'h98 || instr == 8'hA8 || (instr[3:0] == 4'hA && instr[7:6] == 2'b10);
wire isBranch = instr[4:0] == 5'h10;
wire isJump = instr == 8'h4C || instr == 8'h6C;
wire isStack = ~instr[7] && instr[4:0] == 5'h08;
wire pull = instr[5];
wire isSpecial = (~instr[7] && instr[4:0] == 5'h18) || instr == 8'hB8 || instr == 8'hD8 || instr == 8'hF8;

wire isArith = !isLoadOrStore && !isNOP && !isTransfer && !isBranch && !isJump && !isTransfer && !isStack && !isSpecial;

wire isBreak = instr == 8'h00;

wire isImplied = instr[3:0] == 4'hA || instr[3:0] == 4'h8;
wire isImmediate = instr[4:0] == 5'h09 || instr[3:0] == 4'h02 || (instr[7] && ~instr[4] && instr[3:0] == 0); 
wire isIndexed = instr[4];
wire indexedByY = instr[3:0] == 4'h1 || instr[3:0] == 4'h9 || instr == 8'h96 || instr == 8'hB6 || instr == 8'hBE;
wire indexedIndirect = instr[4:0] == 5'h01;
wire indirectIndexed = instr[4:0] == 5'h11;
wire zeropage = (indexedIndirect || indirectIndexed || instr[3:2] == 2'b01) && !isImplied;
wire addr16 = !isImmediate && (instr[3:0] == 4'h9 || instr[3:2] == 2'b11 || instr == 8'h20) && !isImplied;
wire isCompare = (instr[7:5] == 3'b110 && instr[1:0] == 2'b01) || instr[3:0] == 4'h4 || instr[3:0] == 4'h0 || instr[3:0] == 4'hC;
wire isBit = instr == 8'h2C || instr == 8'h24;

// ALU
wire [7:0] ALU_in1 = ~instr[0] && instr[3:0] != 4'hA && ~instr[7] ? d_in : ( //Shifts and rotates
		instr[7] && instr[1:0] == 2'b00 ? (instr[5] ? X : Y) : (
		instr[7] && instr[1:0] == 2'b01 ? A : (
		(instr[7] && instr[1:0] == 2'b10 && instr != 8'hCA) || isBit ? d_in : (
		instr == 8'hCA ? X : (instr == 8'h88 ? Y : A)
	))));
wire [7:0] ALU_in2 = d_in;
wire [7:0] ALU_nin2 = ~d_in;
reg [8:0] ALU_res;

wire [7:0] ALU_sub = ALU_in1 - ALU_in2;
wire [7:0] ALU_sbc = ALU_sub - !carry;

wire [3:0] ALU_opsel = {instr[0], instr[7:5]};
always @(*) begin
	case(ALU_opsel)
		0: ALU_res <= {ALU_in1, 1'b0};
		1: ALU_res <= {ALU_in1, carry};
		2: ALU_res <= {ALU_in1[0], 1'b0, ALU_in1[7:1]};
		3: ALU_res <= {ALU_in1[0], carry, ALU_in1[7:1]};
		4: ALU_res <= {carry, ALU_in1 - 1'b1};
		5: ALU_res <= {carry, ALU_in1};
		6: ALU_res <= instr == 8'hC8 ? {carry, ALU_in1 + 1'b1} : {carry, ALU_in1 - 1'b1};
		7: ALU_res <= {carry, ALU_in1 + 1'b1};
		8: ALU_res <= {carry, ALU_in1 | ALU_in2};
		9: ALU_res <= {carry, ALU_in1 & ALU_in2};
		10: ALU_res <= {carry, ALU_in1 ^ ALU_in2};
		11: ALU_res <= ALU_in1 + ALU_in2 + carry;
		12: ALU_res <= {carry, ALU_in1};
		13: ALU_res <= {carry, ALU_in1};
		14: ALU_res <= ALU_in1 + ALU_nin2 + 1'b1;
		15: ALU_res <= ALU_in1 + ALU_nin2 + carry;
	endcase
end

wire toA = !isLoadOrStore && !isCompare && (
		instr[3:0] == 4'h1 ||
		instr[3:0] == 4'h5 ||
		instr[3:0] == 4'h9 ||
		(instr[3:0] == 4'hA && ~instr[7]) ||
		instr[3:0] == 4'hD
	);
wire toY = instr == 8'hC8 || instr == 8'h88;
wire toX = instr == 8'hE8 || instr == 8'hCA;
wire toMem = (instr[3:0] == 4'hE || instr[3:0] == 4'h6) && !isLoadOrStore;

wire loadstoreTargetA = instr[1:0] == 2'b01;
wire loadstoreTargetX = instr[1:0] == 2'b10;
wire loadstoreTargetY = instr[1:0] == 2'b00;

wire [7:0] status_word = {negative, overflow, 1'b0, 1'b0, decimal, intr_disable, zero, carry};

//Branch conditions
reg should_branch;
always @(*) begin
	case(instr[7:5])
		0: should_branch <= negative == 1'b0;
		1: should_branch <= negative == 1'b1;
		2: should_branch <= overflow == 1'b0;
		3: should_branch <= overflow == 1'b1;
		4: should_branch <= carry == 1'b0;
		5: should_branch <= carry == 1'b1;
		6: should_branch <= zero == 1'b0;
		7: should_branch <= zero == 1'b1;
	endcase
end

wire [2:0] transfer_idx = {instr[1], instr[5:4]};

reg [7:0] transfer_source;
always @(*) begin
	case(transfer_idx)
		1: transfer_source <= Y;
		2: transfer_source <= A;
		4: transfer_source <= X;
		5: transfer_source <= X;
		6: transfer_source <= A;
		7: transfer_source <= stack_ptr;
		default: transfer_source <= A;
	endcase
end

always @(posedge clk) begin
	if(!rstb) begin
		d_out <= 8'h00;
		full_addr <= 16'h0000;
		phase <= `EXECUTE2;
		is_reset <= 1'b1;
		I <= 8'h00; //BRK
		wenb <= 1'b1;
		carry <= 1'b0;
		addr_in_buff <= 8'h00;
		intr_disable <= 1'b1;
		overflow <= 1'b0;
		decimal <= 1'b0;
		stack_ptr <= 8'h00;
		negative <= 1'b0;
		A <= 8'h00;
		X <= 8'h00;
		Y <= 8'h00;
		zero <= 1'b1;
	end else if(rdy) begin
		phase <= phase + 1;
		if(phase == `FETCH) begin
			wenb <= 1'b1;
			full_addr <= PC;
			PC <= PC + 1;
		end else if(phase == `EXECUTE1) begin
			`ifdef BENCH
			if(d_in == 8'hFF) begin
				$display("\r\n");
				$finish();
			end
			`endif
			I <= d_in;
			if(isNOP) begin
				phase <= `FETCH;
			end else if(isStack) begin
				if(pull) begin
					full_addr <= {8'h01, stack_ptr + 1'b1};
					stack_ptr <= stack_ptr + 1'b1;
					wenb <= 1'b1;
					phase <= `EXECUTE4;
				end else begin
					full_addr <= {8'h01, stack_ptr};
					stack_ptr <= stack_ptr - 1'b1;
					wenb <= 1'b0;
					d_out <= instr[6] ? A : status_word;
					phase <= `FETCH;
				end
			end else if(isSpecial) begin
				case(instr[7:5])
					0: carry <= 1'b0;
					1: carry <= 1'b1;
					2: intr_disable <= 1'b0;
					3: intr_disable <= 1'b1;
					5: overflow <= 1'b0;
					6: decimal <= 1'b0;
					7: decimal <= 1'b1;
				endcase
				phase <= `FETCH;
			end else if(isRTS || isRTI) begin
				phase <= isRTS ? `RET2 : `RET1;
				full_addr <= {8'h01, stack_ptr + 1'b1};
				stack_ptr <= stack_ptr + 1;
				wenb <= 1'b1;
			end else if(isTransfer) begin
				case(transfer_idx)
					1: A <= transfer_source;
					2: Y <= transfer_source;
					4: A <= transfer_source;
					5: stack_ptr <= transfer_source;
					6: X <= transfer_source;
					7: X <= transfer_source;
				endcase
				if(transfer_idx != 5) begin
					negative <= transfer_source[7];
					zero <= transfer_source == 8'h00;
				end
				phase <= `FETCH;
			end else begin
				if(isImmediate || isBranch) begin
					full_addr <= PC;
					PC <= PC + 1;
					phase <= `EXECUTE4;
				end
				if(zeropage || addr16 || isJump || isJSR) begin
					full_addr <= PC;
					PC <= PC + 1;
				end
			end
		end else if(phase == `EXECUTE2) begin
			if(isBreak) begin
				full_addr <= 16'hFFFC | (~is_reset << 1);
			end else begin
				if(zeropage) begin
					if(indexedIndirect) begin
						full_addr <= {8'h00, d_in + (indexedByY ? Y : X)};
						phase <= `INDIRECT1;
					end else if(indirectIndexed) begin
						full_addr <= {8'h00, d_in};
						phase <= `INDIRECT1;
					end else if(isIndexed) begin
						full_addr <= {8'h00, d_in + (indexedByY ? Y : X)};
						phase <= `EXECUTE4;
					end else begin
						full_addr <= {8'h00, d_in};
						phase <= `EXECUTE4;
					end
				end
				if(addr16 || isJump || isJSR) begin
					addr_in_buff <= d_in;
					full_addr <= PC;
					PC <= PC + 1;
					if(isJSR) begin
						phase <= `JSR1;
					end
				end
			end
		end else if(phase == `EXECUTE3) begin
			if(isBreak) begin
				addr_in_buff <= d_in;
				full_addr <= full_addr | 1;
			end else if(addr16 || isJump) begin
				if(instr == 8'h6C) begin
					phase <= `INDIRECT1;
				end else if(isIndexed) begin
					full_addr <= {d_in, addr_in_buff} + (indexedByY ? Y : X);
				end else begin
					full_addr <= {d_in, addr_in_buff};
				end
			end
		end else if(phase == `EXECUTE4) begin
			phase <= `FETCH;
			if(isBreak) begin
				if(is_reset) begin
					PC <= {d_in, addr_in_buff};
				end else begin
					phase <= `JSR1;
				end
				is_reset <= 1'b0;
			end else if(isStack) begin
				if(instr[6]) begin
					A <= d_in;
					negative <= d_in[7];
					zero <= d_in == 8'h00;
				end else begin
					negative <= d_in[7];
					overflow <= d_in[6];
					decimal <= d_in[3];
					intr_disable <= d_in[2];
					zero <= d_in[1];
					carry <= d_in[0];
				end
			end else if(isJump) begin
				PC <= full_addr;
			end else if(isBranch) begin
				if(should_branch) begin
					PC <= PC + {d_in[7], d_in[7], d_in[7], d_in[7], d_in[7], d_in[7], d_in[7], d_in[7], d_in};
				end
			end else if(isBit) begin
				negative <= ALU_in1[7];
				overflow <= ALU_in1[6];
				zero <= ALU_res[7:0] == 0;
			end else if(isLoadOrStore) begin
				if(isLoad) begin
					if(loadstoreTargetA) begin
						A <= d_in;
					end else if(loadstoreTargetX) begin
						X <= d_in;
					end else if(loadstoreTargetY) begin
						Y <= d_in;
					end
					negative <= d_in[7];
					zero <= d_in == 8'h00;
				end else if(isStore) begin
					if(loadstoreTargetA) begin
						d_out <= A;
					end else if(loadstoreTargetX) begin
						d_out <= X;
					end else if(loadstoreTargetY) begin
						d_out <= Y;
					end
					wenb <= 1'b0;
				end
			end else if(toMem) begin
				d_out <= ALU_res[7:0];
				wenb <= 1'b0;
				negative <= ALU_res[7];
				zero <= ALU_res[7:0] == 0;
				if(~instr[7]) begin
					carry <= ALU_res[8];
				end
			end else if(toA) begin
				A <= ALU_res[7:0];
				carry <= ALU_res[8];
				zero <= ALU_res[7:0] == 0;
				negative <= ALU_res[7];
				overflow <= ALU_res[7] != ALU_in1[7];
			end else if(toX) begin
				X <= ALU_res[7:0];
				zero <= ALU_res[7:0] == 0;
				negative <= ALU_res[7];
			end else if(toY) begin
				Y <= ALU_res[7:0];
				zero <= ALU_res[7:0] == 0;
				negative <= ALU_res[7];
			end else if(isCompare) begin
				carry <= ALU_res[8];
				zero <= ALU_res[7:0] == 0;
				negative <= ALU_res[7];
			end
		end else if(phase == `INDIRECT1) begin
			addr_in_buff <= d_in;
			full_addr <= {full_addr[15:8], full_addr[7:0] + 1'b1};
			wenb <= 1'b1;
		end else if(phase == `INDIRECT2) begin
			if(indirectIndexed) begin
				full_addr <= {d_in, addr_in_buff} + Y;
			end else begin
				full_addr <= {d_in, addr_in_buff};
			end
			phase <= `EXECUTE4;
		end else if(phase == `JSR1) begin
			full_addr <= {8'h01, stack_ptr};
			d_out <= PC[15:8];
			PC[15:8] <= d_in;
			wenb <= 1'b0;
			stack_ptr <= stack_ptr - 1;
		end else if(phase == `JSR2) begin
			full_addr <= {8'h01, stack_ptr};
			d_out <= PC[7:0];
			PC[7:0] <= addr_in_buff;
			wenb <= 1'b0;
			stack_ptr <= stack_ptr - 1;
			if(!isBreak) begin
				phase <= `FETCH;
			end
		end else if(phase == `JSR3) begin
			full_addr <= {8'h01, stack_ptr};
			d_out <= status_word;
			wenb <= 1'b0;
			stack_ptr <= stack_ptr - 1;
			phase <= `FETCH;
			intr_disable <= 1'b1;
		end else if(phase == `RET1) begin
			negative <= d_in[7];
			overflow <= d_in[6];
			decimal <= d_in[3];
			intr_disable <= d_in[2];
			zero <= d_in[1];
			carry <= d_in[0];
			full_addr <= {8'h01, stack_ptr + 1'b1};
			stack_ptr <= stack_ptr + 1;
			wenb <= 1'b1;
		end else if(phase == `RET2) begin
			PC[7:0] <= d_in;
			full_addr <= {8'h01, stack_ptr + 1'b1};
			stack_ptr <= stack_ptr + 1;
			wenb <= 1'b1;
		end else if(phase == `RET3) begin
			PC[15:8] <= d_in;
			full_addr <= {8'h01, stack_ptr + 1'b1};
			wenb <= 1'b1;
			phase <= `FETCH;
		end else begin
			phase <= `FETCH;
		end
	end
end

endmodule
