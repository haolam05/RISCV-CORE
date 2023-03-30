module decode #(parameter RV_LEN, parameter OP_LEN, parameter F3_LEN, parameter F7_LEN, parameter NUM_REGS, parameter IMM_I_LEN, parameter IMM_S_LEN, parameter IMM_B_LEN, parameter IMM_U_LEN, parameter IMM_J_LEN) 
    (clk, jal, jalr, branch, load, store, lui, auipc, arith, ins, opcode, funct3, funct7, rd, rs1, rs2, imm_i, imm_s, imm_b, imm_u, imm_j, rs1_val, rs2_val);
    input  logic                clk;
    input  logic [     RV_LEN-1:0] ins, rs1_val, rs2_val;
    output logic                   jal, jalr, branch, load, store, lui, auipc, arith;
    output logic [     OP_LEN-1:0] opcode;
    output logic [     F3_LEN-1:0] funct3;
    output logic [     F7_LEN-1:0] funct7;
    output logic [   NUM_REGS-1:0] rd, rs1, rs2;
    output logic [  IMM_I_LEN-1:0] imm_i;
    output logic [  IMM_S_LEN-1:0] imm_s;
    output logic [  IMM_B_LEN-1:0] imm_b;
    output logic [  IMM_U_LEN-1:0] imm_u;
    output logic [  IMM_J_LEN-1:0] imm_j;

    assign jal    = (ins[6:0] == 7'b1101111);
    assign jalr   = (ins[6:0] == 7'b1100111);
    assign branch = (ins[6:0] == 7'b1100011 && (
                           (ins[14:12] == 3'b000 &&         rs1_val  == rs2_val)          || 
                           (ins[14:12] == 3'b001 &&         rs1_val  != rs2_val)          ||
                           (ins[14:12] == 3'b100 && $signed(rs1_val) <  $signed(rs2_val)) ||
                           (ins[14:12] == 3'b101 && $signed(rs1_val) >= $signed(rs2_val)) ||
                           (ins[14:12] == 3'b110 &&         rs1_val  <  rs2_val)          ||
                           (ins[14:12] == 3'b111 &&         rs1_val  >= rs2_val)));
    assign load   = (ins[6:0] == 7'b0000011);
    assign store  = (ins[6:0] == 7'b0100011 && (ins[14:12] == 3'b000 || ins[14:12] == 3'b001 || ins[14:12] == 3'b010));
    assign lui    = (ins[6:0] == 7'b0110111);
    assign auipc  = (ins[6:0] == 7'b0010111);
    assign arith  = (ins[6:0] == 7'b0010011 || ins[6:0] == 7'b0110011);

    always_ff @(posedge clk) begin
        opcode <= ins[ 6:0 ];
        funct3 <= ins[14:12];
        funct7 <= ins[31:25];
        rs1    <= ins[19:15];
        rs2    <= ins[24:20];
        rd     <= ins[11:7 ];
        imm_i  <= { ins[31:20]                                           };
        imm_s  <= { ins[31:25], ins[11:7]                                };
        imm_b  <= { ins[31]   , ins[7]    , ins[30:25], ins[11:8] , 1'b0 };
        imm_u  <= { ins[31:12], 12'b0                                    };
        imm_j  <= { ins[14:12], ins[20]   , ins[30:21], 1'b0             };
    end
endmodule
