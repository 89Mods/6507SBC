`default_nettype wire
`define BENCH

module tb(
	input clk,
	input rstb
);

reg [7:0] memory [0:8191];
wire [12:0] addr_bus;
wire [7:0] mem_rval = addr_bus == 13'h0208 ? 8'hFF : memory[addr_bus];
wire wenb;
wire [7:0] dbus_out;

reg spi_clk = 0;
reg spi_din = 0;
reg spi_cs = 0;
reg spi_cd = 0; //1 = data, 0 = command

initial begin
	/*memory[13'h1FFC] = 8'h00;
	memory[13'h1FFD] = 8'h02;
	
	memory[13'h0200] = 8'hA9; //LDA #0x23
	memory[13'h0201] = 8'h23;
	memory[13'h0202] = 8'h38; //SEC
	memory[13'h0203] = 8'h69; //ADC #0x07
	memory[13'h0204] = 8'h07;
	memory[13'h0205] = 8'h8D; //STA 0xFFFF
	memory[13'h0206] = 8'hFF;
	memory[13'h0207] = 8'hFF;
	
	memory[13'h0208] = 8'hFF; //KIL*/
	$readmemh("../test_pgm/rom.bin.txt", memory);
end

wire [7:0] test1 = memory[128+32];
wire [7:0] test2 = memory[128+33];

always @(posedge clk) begin
	if(!wenb) begin
		if(addr_bus < 512) begin
			memory[addr_bus] <= dbus_out;
		end
		if(addr_bus == 13'h1FFF) begin
			$write("%c", dbus_out);
			$fflush();
		end
		if(addr_bus == 13'h0201) begin //Port 1
			
		end
		if(addr_bus == 13'h0202) begin //Port 2
			spi_cs <= dbus_out[2];
			spi_cd <= dbus_out[6];
			spi_clk <= dbus_out[4];
			spi_din <= dbus_out[5];
			if(dbus_out[7]) begin
				for(integer i = 0; i < 64; i++) begin
					for(integer j = 0; j < 128; j++) begin
						if(pixels[j][i]) begin
							$write("##");
						end else begin
							$write("  ");
						end
					end
					$write("\r\n");
					$fflush();
				end
				for(integer j = 0; j < 128; j++) begin
					$write("~~");
				end
				$write("\r\n");
				$fflush();
			end
		end
	end
end

reg pixels [0:127][0:63];

initial begin
	for(integer i = 0; i < 128; i++) begin
		for(integer j = 0; j < 64; j++) begin
			pixels[i][j] = $random();
		end
	end
end

reg [7:0] cursor_x = 0;
reg [2:0] cursor_y = 0;
wire [5:0] index_y = (~cursor_y) << 3;
reg [7:0] spi_dbuff = 0;
reg [3:0] spi_step = 0;
reg last_spi_clk = 0;
always @(posedge clk) begin
	if(spi_cs) begin
		spi_step <= 0;
		spi_dbuff <= 0;
	end else begin
		last_spi_clk <= spi_clk;
		if(spi_clk && !last_spi_clk) begin
			spi_step <= spi_step + 1;
			spi_dbuff <= {spi_dbuff[6:0], spi_din};
		end
		if(spi_step[3]) begin
			spi_step <= 0;
			if(spi_cd) begin
				cursor_x <= cursor_x + 1;
				pixels[~cursor_x][index_y] <= spi_dbuff[7];
				pixels[~cursor_x][index_y+1] <= spi_dbuff[6];
				pixels[~cursor_x][index_y+2] <= spi_dbuff[5];
				pixels[~cursor_x][index_y+3] <= spi_dbuff[4];
				pixels[~cursor_x][index_y+4] <= spi_dbuff[3];
				pixels[~cursor_x][index_y+5] <= spi_dbuff[2];
				pixels[~cursor_x][index_y+6] <= spi_dbuff[1];
				pixels[~cursor_x][index_y+7] <= spi_dbuff[0];
			end else begin
				if(spi_dbuff[7:3] == 5'b10110) begin
					cursor_y <= spi_dbuff[2:0];
				end
				if(spi_dbuff[7:4] == 4'b0001) begin
					cursor_x[7:4] <= spi_dbuff[3:0];
				end
				if(spi_dbuff[7:4] == 4'b0000) begin
					cursor_x[3:0] <= spi_dbuff[3:0];
				end
			end
		end
	end
end

CPU_6507 CPU_6507(
	.clk(clk),
	.rstb(rstb),
	.addr_bus(addr_bus),
	.wenb(wenb),
	.d_out(dbus_out),
	.d_in(mem_rval),
	.rdy(1'b1)
);

initial begin
	//$dumpfile("tb.vcd");
	//$dumpvars();
end

endmodule
