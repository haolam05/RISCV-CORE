module alu #(parameter N, parameter F3_LEN, parameter F7_LEN) (op, funct3, funct7, a, b, out);
    input  logic              op;
    input  logic [F3_LEN-1:0] funct3;
    input  logic [F7_LEN-1:0] funct7;
    input  logic [     N-1:0] a, b;
    output logic [     N-1:0] out;

  always_comb begin
    case (funct3)
      3'b000 : out = ((op == 1 && funct7 == 7'b0100000) ? a - b : a + b );                                                                                   // ADDI , [ADD, SUB]
      3'b001 : out = a << b[4:0];                                                                                                                            // SLLI , SLL
      3'b010 : out = ($signed(a) < $signed(b) ? 1 : 0);                                                                                                      // SLTI , SLT
      3'b011 : out = (        a  <         b  ? 1 : 0);                                                                                                      // SLTIU, SLTU
      3'b100 : out = a ^ b;                                                                                                                                  // XORI , XOR
      3'b101 : out = (funct7 == 7'b0 ? a >> b[4:0] : ((a >> b[4:0]) >> (N - b[4:0] - 1)) == 1 ? (-((1 << (N - b[4:0])) - (a >> b[4:0]))) : (a >> b[4:0]));   // ['SRLI', 'SRAI'], ['SRL' , 'SRA']
      3'b110 : out = a | b;                                                                                                                                  // ORI  , OR
      3'b111 : out = a & b;                                                                                                                                  // ANDI , AND
      default: ;
    endcase
  end
endmodule
