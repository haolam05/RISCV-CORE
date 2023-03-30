module instruction_memory #(parameter ADDR, parameter DATA, parameter CODE_FILE, parameter CODE_ADDR, parameter CODE_SIZE) (clk, addr, d_out);
    input  logic            clk;
    input  logic [ADDR-1:0] addr;
    output logic [DATA-1:0] d_out;

    logic [DATA-1:0] INS_MEM [0:2**ADDR-1];

    initial begin
        $readmemh(CODE_FILE, INS_MEM, CODE_ADDR, CODE_ADDR + CODE_SIZE - 1);
    end

    always_ff @(posedge clk) begin
        d_out <= INS_MEM[addr];
    end
endmodule
