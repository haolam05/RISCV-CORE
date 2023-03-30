module clock_divider (clk, div_clk);    // divided_clocks[0] = 25MHz, [1] = 12.5Mhz, ... [23] = 3Hz, [24] = 1.5Hz, [25] = 0.75Hz, ...
	input  logic 		clk;
	output logic [31:0] div_clk = 0;
	
	always_ff @(posedge clk) begin
		div_clk <= div_clk + 1;
	end
endmodule
