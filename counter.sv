module counter #(parameter N, parameter CODE_ADDR) (clk, reset, en, set, val, out);
	input  logic         clk, reset, en, set;
  input  logic [N-1:0] val;
	output logic [N-1:0] out;

	always_ff @(posedge clk) begin
        if      (reset) out <= CODE_ADDR[N-1:0];
        else if (en)    out <= (set ? val : out + val);
	end
endmodule
