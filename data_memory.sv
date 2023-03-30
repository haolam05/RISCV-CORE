module data_memory #(parameter ADDR, parameter DATA, parameter DATA_FILE, parameter DATA_ADDR, parameter DATA_SIZE) (clk, wr_en, addr, d_in, d_out);
    input  logic            clk, wr_en;
    input  logic [ADDR-1:0] addr;
    input  logic [DATA-1:0] d_in;
    output logic [DATA-1:0] d_out;

    logic [DATA-1:0] DAT_MEM [0:2**ADDR-1];

    initial begin
        $readmemh(DATA_FILE, DAT_MEM, DATA_ADDR, DATA_ADDR + DATA_SIZE - 1);
    end

    always_ff @(posedge clk) begin
        if (wr_en) DAT_MEM[addr] <= d_in;
        else               d_out <= DAT_MEM[addr];
    end
endmodule
