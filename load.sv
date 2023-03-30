module load #(parameter F3_LEN, parameter N) (funct3, in, out);
  input  logic [F3_LEN-1:0] funct3;
  input  logic [     N-1:0] in;
  output logic [     N-1:0] out;

  always_comb begin
    out = 0;
    case (funct3)
      3'b000 : begin out = (((in & 32'h000000FF) >> 7 ) == 1 ? (-((1 <<  8) - (in & 32'h000000FF))) : (in & 32'h000000FF)); end    // LB
      3'b001 : begin out = (((in & 32'h0000FFFF) >> 15) == 1 ? (-((1 << 16) - (in & 32'h0000FFFF))) : (in & 32'h0000FFFF)); end    // LH
      3'b010 : begin out = (((in & 32'hFFFFFFFF) >> 31) == 1 ? (-((1 << 32) - (in & 32'hFFFFFFFF))) : (in & 32'hFFFFFFFF)); end    // LW
      3'b100 : begin out =    in & 32'h000000FF                                                                           ; end    // LBU
      3'b101 : begin out =    in & 32'h0000FFFF                                                                           ; end    // LHU
      default: ;
    endcase
  end
endmodule
