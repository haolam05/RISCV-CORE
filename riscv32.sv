// Implementation of RISCV32 Base Instruction Set
module riscv32 (CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR);
    // System parameters
    parameter NUM_LEDS             = 10;
    parameter NUM_KEYS             = 4;
    parameter NUM_SEGMENTS         = 8;
	parameter DIV_CLK_LEN          = 32;
	parameter WHICH_CLK            = 18;

    // System inputs
    input  logic                    CLOCK_50;
    input  logic [    NUM_KEYS-1:0] KEY;

    // System outputs
    output logic [NUM_SEGMENTS-1:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    output logic [    NUM_LEDS-1:0] LEDR;
    
    // System control signals
	logic        [ DIV_CLK_LEN-1:0] div_clk;
    logic                           reset;

    // Assign System control signals
    assign reset                   = ~KEY[0] | ~KEY[1] | ~KEY[2] | ~KEY[3];
    assign HEX4                    = 8'b11111111;
    assign HEX5                    = 8'b11111111;
    assign LEDR[0] = 0 & ((opcode  == opcode_1) == (opcode_2 == opcode_3));
    assign LEDR[1] = 0 & ((funct7  == funct7_1) == (funct7_2 == funct7_3));
    assign LEDR[2] = 0 & ((funct3  == funct3_1) == (funct3_2 == funct3_3));
    assign LEDR[3] = 0 & ((rd      == rd_1    ) == (rd_2     == rd_3    ) == (rs1   == rs1_1  ) == (rs1_2   == rs1_3  ) == (rs2 == rs2_1) == (rs2_2 == rs2_3));
    assign LEDR[4] = 0 & ((imm_i   == imm_i_1 ) == (imm_i_2  == imm_i_3 ) == (imm_s == imm_s_1) == (imm_s_2 == imm_s_3));
    assign LEDR[5] = 0 & ((imm_b   == imm_b_1 ) == (imm_b_2  == imm_b_3 ));
    assign LEDR[6] = 0 & ((imm_u   == imm_u_1 ) == (imm_u_2  == imm_u_3 ));
    assign LEDR[7] = 0 & ((imm_j   == imm_j_1 ) == (imm_j_2  == imm_j_3 ));
    assign LEDR[8] = 0 & (branch || branch_1 || branch_2 || branch_3 || load  || load_1 || load_2  || load_3  || load_4  || load_5  || store || store_1 || store_2 || store_3 || jal     || jal_1 || jal_2  || jal_3 || jal_4           );
    assign LEDR[9] = 0 & (lui    || lui_1    || lui_2    || lui_3    || lui_4 || auipc  || auipc_1 || auipc_2 || auipc_3 || auipc_4 || arith || arith_1 || arith_2 || arith_3 || arith_4 || jalr || jalr_1 || jalr_2 || jalr_3 || jalr_4);

    // RISCV32 Parameters
    parameter CODE_FILE            = "code.hex";
    parameter CODE_SIZE            = 32768;                         // Size of code section
    parameter CODE_ADDR            = 0;                             // start addr (code section) - 0x0               => 0x10000 - 1
    parameter INS_MEM_LEN          = 15;                            // Instruction memory: 2**16 Words, each word = 32 bits

    parameter DATA_FILE            = "data.hex";
    parameter DATA_SIZE            = 32768;                         // Size of data section
    parameter DATA_ADDR            = 0;                             // start addr (data section) - 0x10000           => 0x20000 - 1
    parameter DAT_MEM_LEN          = 15;                            // Data        memory: 2**16 Words, each word = 32 bits

    parameter RV_LEN               = 32;                            // RISC-V 32-bits intruction/register length
    parameter INS_LEN              = 4;                             // pc incr by 4 every step
    parameter OP_LEN               = 7;                             // Length of opcode filed
    parameter F3_LEN               = 3;                             // Length of funct3 filed
    parameter F7_LEN               = 7;                             // Length of funct7 filed
    parameter NUM_REGS             = 5;                             // Number of registers (except PC) in bits 
    parameter IMM_I_LEN            = 12;
    parameter IMM_S_LEN            = 12;
    parameter IMM_B_LEN            = 13;
    parameter IMM_U_LEN            = 32;
    parameter IMM_J_LEN            = 15;                            // Bit 21 -> 15 are unused => trim, actual size of imm_j_len = 21

    parameter ASCII_LEN            = 8;

    // Decode Signals - (RISCV32 Instruction Fields)
    logic [     RV_LEN-1:0] ins        , ins_1        , ins_2        , ins_3   ;   // 32 bitsinstruction
    logic [     OP_LEN-1:0] opcode     , opcode_1     , opcode_2     , opcode_3;
    logic [     F3_LEN-1:0] funct3     , funct3_1     , funct3_2     , funct3_3, funct3_4;
    logic [     F7_LEN-1:0] funct7     , funct7_1     , funct7_2     , funct7_3;
    logic [   NUM_REGS-1:0] rd         , rd_1         , rd_2         , rd_3    , rd_4;   // Destination register index
    logic [   NUM_REGS-1:0] rs1        , rs1_1        , rs1_2        , rs1_3   ;   // Register #1 index
    logic [   NUM_REGS-1:0] rs2        , rs2_1        , rs2_2        , rs2_3   ;   // Register #2 index
    logic [  IMM_I_LEN-1:0] imm_i      , imm_i_1      , imm_i_2      , imm_i_3 ;
    logic [  IMM_S_LEN-1:0] imm_s      , imm_s_1      , imm_s_2      , imm_s_3 ;
    logic [  IMM_B_LEN-1:0] imm_b      , imm_b_1      , imm_b_2      , imm_b_3 ;
    logic [  IMM_U_LEN-1:0] imm_u      , imm_u_1      , imm_u_2      , imm_u_3 ;
    logic [  IMM_J_LEN-1:0] imm_j      , imm_j_1      , imm_j_2      , imm_j_3 ;
    logic                   jal        , jal_1        , jal_2        , jal_3   , jal_4;
    logic                   jalr       , jalr_1       , jalr_2       , jalr_3  , jalr_4;
    logic                   branch     , branch_1     , branch_2     , branch_3;
    logic                   load       , load_1       , load_2       , load_3  , load_4, load_5;
    logic                   store      , store_1      , store_2      , store_3 ;
    logic                   lui        , lui_1        , lui_2        , lui_3   , lui_4;
    logic                   auipc      , auipc_1      , auipc_2      , auipc_3 , auipc_4;
    logic                   arith      , arith_1      , arith_2      , arith_3 , arith_4;

    // RISCV Registers
    logic [     RV_LEN-1:0] REGS [0:2**NUM_REGS-1];

    // Instruction Memory logic signals
    logic [     RV_LEN-1:0] ins_out;

    // Data Memory logic signals
    logic                   mem_wr_en;
    logic [DAT_MEM_LEN-1:0] mem_addr;
    logic [     RV_LEN-1:0] mem_wr_data, mem_rd_data;

    // Counter logic signals
    logic                   counter_en, set;
    logic [INS_MEM_LEN-1:0] incr_val;
    logic [INS_MEM_LEN-1:0] pc;

    // ALU logic signals
    logic [     RV_LEN-1:0] a, b, alu_out, alu_out_3;
    logic                   op;

    // Load signals
    logic [     RV_LEN-1:0] load_out;

 	// ClocK Divider signals
	logic                   clkSelect;

    // Helper signals
    logic [     RV_LEN-1:0] auipc_temp_2, jmp_temp_2, auipc_temp_3, jmp_temp_3;
    logic [            1:0] halt;

    // Module Calls
    instruction_memory #(.ADDR(INS_MEM_LEN), .DATA(RV_LEN), .CODE_FILE(CODE_FILE), .CODE_ADDR(CODE_ADDR), .CODE_SIZE(CODE_SIZE)) ins_mem (
        .clk           ( clkSelect          ),
        .addr          ( pc                 ),
        .d_out         ( ins_out            )
    );
    data_memory #(.ADDR(DAT_MEM_LEN), .DATA(RV_LEN), .DATA_FILE(DATA_FILE), .DATA_ADDR(DATA_ADDR), .DATA_SIZE(DATA_SIZE)) dat_mem (
        .clk           ( clkSelect          ),
        .wr_en         ( mem_wr_en          ),
        .addr          ( mem_addr           ),
        .d_in          ( mem_wr_data        ),
        .d_out         ( mem_rd_data        )
    );
    counter #(.N(INS_MEM_LEN), .CODE_ADDR(CODE_ADDR)) p_c (
        .clk           ( clkSelect          ),
        .reset         ( reset              ),
        .en            ( counter_en         ),
        .set           ( set                ),
        .val           ( incr_val           ),
        .out           ( pc                 )
    );
    alu #(.N(RV_LEN), .F3_LEN(F3_LEN), .F7_LEN(F7_LEN)) alu (
        .op            ( op                 ),
        .funct3        ( funct3_2           ),
        .funct7        ( funct7_2           ),
        .a             ( a                  ),
        .b             ( b                  ),
        .out           ( alu_out            )
    );
    load #(.F3_LEN(F3_LEN), .N(RV_LEN)) mem_load (
        .funct3        ( funct3_4           ),
        .in            ( mem_rd_data        ),
        .out           ( load_out           )
    );
    decode #(.RV_LEN(RV_LEN), .OP_LEN(OP_LEN), .F3_LEN(F3_LEN), .F7_LEN(F7_LEN), .NUM_REGS(NUM_REGS), .IMM_I_LEN(IMM_I_LEN), .IMM_S_LEN(IMM_S_LEN), .IMM_B_LEN(IMM_B_LEN), .IMM_U_LEN(IMM_U_LEN), .IMM_J_LEN(IMM_J_LEN)) decoder (
        .clk           ( clkSelect          ),
        .ins           ( ins                ),
        .opcode        ( opcode             ),
        .funct3        ( funct3             ),
        .funct7        ( funct7             ),
        .rd            ( rd                 ),
        .rs1           ( rs1                ),
        .rs2           ( rs2                ),
        .imm_i         ( imm_i              ),
        .imm_s         ( imm_s              ),
        .imm_b         ( imm_b              ),
        .imm_u         ( imm_u              ),
        .imm_j         ( imm_j              ),
        .rs1_val       ( REGS[ins[19:15]]   ),
        .rs2_val       ( REGS[ins[24:20]]   ),
        .jal           ( jal                ),
        .jalr          ( jalr               ),
        .branch        ( branch             ),
        .load          ( load               ),
        .store         ( store              ),
        .lui           ( lui                ),
        .auipc         ( auipc              ),
        .arith         ( arith              )
    );
    decode #(.RV_LEN(RV_LEN), .OP_LEN(OP_LEN), .F3_LEN(F3_LEN), .F7_LEN(F7_LEN), .NUM_REGS(NUM_REGS), .IMM_I_LEN(IMM_I_LEN), .IMM_S_LEN(IMM_S_LEN), .IMM_B_LEN(IMM_B_LEN), .IMM_U_LEN(IMM_U_LEN), .IMM_J_LEN(IMM_J_LEN)) decoder_1 (
        .clk           ( clkSelect          ),
        .ins           ( ins_1              ),
        .opcode        ( opcode_1           ),
        .funct3        ( funct3_1           ),
        .funct7        ( funct7_1           ),
        .rd            ( rd_1               ),
        .rs1           ( rs1_1              ),
        .rs2           ( rs2_1              ),
        .imm_i         ( imm_i_1            ),
        .imm_s         ( imm_s_1            ),
        .imm_b         ( imm_b_1            ),
        .imm_u         ( imm_u_1            ),
        .imm_j         ( imm_j_1            ),
        .rs1_val       ( REGS[ins_1[19:15]] ),
        .rs2_val       ( REGS[ins_1[24:20]] ),
        .jal           ( jal_1              ),
        .jalr          ( jalr_1             ),
        .branch        ( branch_1           ),
        .load          ( load_1             ),
        .store         ( store_1            ),
        .lui           ( lui_1              ),
        .auipc         ( auipc_1            ),
        .arith         ( arith_1            )
    );
    decode #(.RV_LEN(RV_LEN), .OP_LEN(OP_LEN), .F3_LEN(F3_LEN), .F7_LEN(F7_LEN), .NUM_REGS(NUM_REGS), .IMM_I_LEN(IMM_I_LEN), .IMM_S_LEN(IMM_S_LEN), .IMM_B_LEN(IMM_B_LEN), .IMM_U_LEN(IMM_U_LEN), .IMM_J_LEN(IMM_J_LEN)) decoder_2 (
        .clk           ( clkSelect          ),
        .ins           ( ins_2              ),
        .opcode        ( opcode_2           ),
        .funct3        ( funct3_2           ),
        .funct7        ( funct7_2           ),
        .rd            ( rd_2               ),
        .rs1           ( rs1_2              ),
        .rs2           ( rs2_2              ),
        .imm_i         ( imm_i_2            ),
        .imm_s         ( imm_s_2            ),
        .imm_b         ( imm_b_2            ),
        .imm_u         ( imm_u_2            ),
        .imm_j         ( imm_j_2            ),
        .rs1_val       ( REGS[ins_2[19:15]] ),
        .rs2_val       ( REGS[ins_2[24:20]] ),
        .jal           ( jal_2              ),
        .jalr          ( jalr_2             ),
        .branch        ( branch_2           ),
        .load          ( load_2             ),
        .store         ( store_2            ),
        .lui           ( lui_2              ),
        .auipc         ( auipc_2            ),
        .arith         ( arith_2            )
    );
    decode #(.RV_LEN(RV_LEN), .OP_LEN(OP_LEN), .F3_LEN(F3_LEN), .F7_LEN(F7_LEN), .NUM_REGS(NUM_REGS), .IMM_I_LEN(IMM_I_LEN), .IMM_S_LEN(IMM_S_LEN), .IMM_B_LEN(IMM_B_LEN), .IMM_U_LEN(IMM_U_LEN), .IMM_J_LEN(IMM_J_LEN)) decoder_3 (
        .clk           ( clkSelect          ),
        .ins           ( ins_3              ),
        .opcode        ( opcode_3           ),
        .funct3        ( funct3_3           ),
        .funct7        ( funct7_3           ),
        .rd            ( rd_3               ),
        .rs1           ( rs1_3              ),
        .rs2           ( rs2_3              ),
        .imm_i         ( imm_i_3            ),
        .imm_s         ( imm_s_3            ),
        .imm_b         ( imm_b_3            ),
        .imm_u         ( imm_u_3            ),
        .imm_j         ( imm_j_3            ),
        .rs1_val       ( REGS[ins_3[19:15]] ),
        .rs2_val       ( REGS[ins_3[24:20]] ),
        .jal           ( jal_3              ),
        .jalr          ( jalr_3             ),
        .branch        ( branch_3           ),
        .load          ( load_3             ),
        .store         ( store_3            ),
        .lui           ( lui_3              ),
        .auipc         ( auipc_3            ),
        .arith         ( arith_3            )
    );
    display_control #(.NUM_SEGMENTS(NUM_SEGMENTS), .ASCII_LEN(ASCII_LEN)) hex_display (
        .clk           ( clkSelect          ),
        .bytes_4       ( mem_rd_data        ),
        .HEX0          ( HEX0               ),
        .HEX1          ( HEX1               ),
        .HEX2          ( HEX2               ),
        .HEX3          ( HEX3               )
    );
	clock_divider cdiv (
        .clk           ( CLOCK_50           ),
        .div_clk       ( div_clk            )
    );

    // Assign Clock Divider signals
    // assign clkSelect = CLOCK_50;                // For Simulation
	assign clkSelect = div_clk[WHICH_CLK];     // For Board

    always_ff @(posedge clkSelect) begin : FSM_State_Transition
        if (reset)
            begin
                for (int i = 0; i < 2**NUM_REGS-1; i++)
                    REGS[i] <= 0;
                set <= 0; incr_val <= 0; mem_wr_en <= 0; mem_addr <= 0; mem_wr_data <= 0; halt <= 0;  counter_en <= 1;
            end
        else
            begin
                // Fetch current: _**; next: _*
                ins  <= ((pc != 15'b0 && halt == 2'b0 && (jal || jalr || branch || load)) || halt != 2'b0) ? 32'h1C : ins_out;
                halt <= (pc != 15'b0 && (halt != 2'b0 || jal || jalr || branch || load) ? halt + 1 : 0);

                // Decode current: _*; next: _1
                ins_1 <= ins;

                // Execute current: _1; next: _2
                ins_2 <= ins_1;
                if      (halt == 1 && jal_1   ) begin incr_val <= imm_j - (4 * INS_LEN)                                          ; set <= 0; end
                else if (halt == 1 && jalr_1  ) begin incr_val <= REGS[rs1][DAT_MEM_LEN-1:0] + { {3{imm_i[IMM_I_LEN-1]}}, imm_i }; set <= 1; end
                else if (halt == 1 && branch_1) begin incr_val <= { {2{imm_b[IMM_B_LEN-1]}}, imm_b } - (4 * INS_LEN)             ; set <= 0; end
                else if (halt == 1 && load_1  ) begin incr_val <= -(3 * INS_LEN)                                                 ; set <= 0; end
                else                            begin incr_val <= INS_LEN                                                        ; set <= 0; end

                if (rd_2 != 0 && rd_2 == rs1_1)
                    if      (lui_3          )   a <= imm_u_2;
                    else if (auipc_3        )   a <= auipc_temp_2;
                    else if (arith_3        )   a <= alu_out;
                    else                        a <= REGS[rs1_1];
                else if (rd_3 != 0 && rd_3 == rs1_1)
                    if      (lui_4          )   a <= imm_u_3;
                    else if (auipc_4        )   a <= auipc_temp_3;
                    else if (arith_4        )   a <= alu_out;
                    else                        a <= REGS[rs1_1];
                else                            a <= REGS[rs1_1];

                if (opcode_1 == 7'b0010011)     b <= { {20{imm_i_1[IMM_I_LEN-1]}}, imm_i_1 };
                else if (rd_2 != 0 && rd_2 == rs2_1)
                    if      (lui_3          )   b <= imm_u_2;
                    else if (auipc_3        )   b <= auipc_temp_2;
                    else if (arith_3        )   b <= alu_out;
                    else                        b <= REGS[rs2_1];
                else if (rd_3 != 0 && rd_3 == rs2_1)
                    if      (lui_4          )   b <= imm_u_3;
                    else if (auipc_4        )   b <= auipc_temp_3;
                    else if (arith_4        )   b <= alu_out;
                    else                        b <= REGS[rs2_1];
                else                            b <= REGS[rs2_1];

                op <= (opcode_1 != 7'b0010011);
                if (auipc_2) auipc_temp_2 <= { 16'b0, pc } - (4 * INS_LEN) + imm_u_1;
                if (jal_2  ) jmp_temp_2   <= { 16'b0, pc } - (4 * INS_LEN) + INS_LEN;
                if (jalr_2 ) jmp_temp_2   <= { 16'b0, pc } - (4 * INS_LEN) + INS_LEN;

                // Memory current: _2; next: _3
                ins_3 <= ins_2; auipc_temp_3 <= auipc_temp_2; jmp_temp_3 <= jmp_temp_2; alu_out_3 <= alu_out;
                if (load_3)
                    begin
                        mem_wr_en <= 0;
                        if (rd_3 != 0 && rd_3 == rs1_2)
                            if      (lui_4          )   mem_addr    <= imm_u_3[DAT_MEM_LEN-1:0]      + { {3{imm_i_2[IMM_I_LEN-1]}}, imm_i_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                            else if (auipc_4        )   mem_addr    <= auipc_temp_3[DAT_MEM_LEN-1:0] + { {3{imm_i_2[IMM_I_LEN-1]}}, imm_i_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                            else if (jal_4 || jalr_4)   mem_addr    <= jmp_temp_3[DAT_MEM_LEN-1:0]   + { {3{imm_i_2[IMM_I_LEN-1]}}, imm_i_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                            else if (load_4         )   mem_addr    <= load_out[DAT_MEM_LEN-1:0]     + { {3{imm_i_2[IMM_I_LEN-1]}}, imm_i_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                            else if (arith_4        )   mem_addr    <= alu_out_3[DAT_MEM_LEN-1:0]    + { {3{imm_i_2[IMM_I_LEN-1]}}, imm_i_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                            else                        mem_addr    <= REGS[rs1_2][DAT_MEM_LEN-1:0]  + { {3{imm_i_2[IMM_I_LEN-1]}}, imm_i_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                        else                            mem_addr    <= REGS[rs1_2][DAT_MEM_LEN-1:0]  + { {3{imm_i_2[IMM_I_LEN-1]}}, imm_i_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                    end
                if (store_3)
                    begin
                        mem_wr_en <= 1;
                        if (rd_3 != 0 && rd_3 == rs1_2)
                            if      (lui_4          )   mem_addr    <= imm_u_3[DAT_MEM_LEN-1:0]      + { {3{imm_s_2[IMM_S_LEN-1]}}, imm_s_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                            else if (auipc_4        )   mem_addr    <= auipc_temp_3[DAT_MEM_LEN-1:0] + { {3{imm_s_2[IMM_S_LEN-1]}}, imm_s_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                            else if (jal_4 || jalr_4)   mem_addr    <= jmp_temp_3[DAT_MEM_LEN-1:0]   + { {3{imm_s_2[IMM_S_LEN-1]}}, imm_s_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                            else if (load_4         )   mem_addr    <= load_out[DAT_MEM_LEN-1:0]     + { {3{imm_s_2[IMM_S_LEN-1]}}, imm_s_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                            else if (arith_4        )   mem_addr    <= alu_out_3[DAT_MEM_LEN-1:0]    + { {3{imm_s_2[IMM_S_LEN-1]}}, imm_s_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                            else                        mem_addr    <= REGS[rs1_2][DAT_MEM_LEN-1:0]  + { {3{imm_s_2[IMM_S_LEN-1]}}, imm_s_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                        else                            mem_addr    <= REGS[rs1_2][DAT_MEM_LEN-1:0]  + { {3{imm_s_2[IMM_S_LEN-1]}}, imm_s_2 } - DATA_SIZE[DAT_MEM_LEN-1:0];
                        if (rd_3 != 0 && rd_3 == rs2_2)
                            if      (lui_4          )   mem_wr_data <= imm_u_3      & (funct3_2 == 3'b000 ? 32'hFF : (funct3_2 == 3'b001 ? 32'hFFFF : 32'hFFFFFFFF));
                            else if (auipc_4        )   mem_wr_data <= auipc_temp_3 & (funct3_2 == 3'b000 ? 32'hFF : (funct3_2 == 3'b001 ? 32'hFFFF : 32'hFFFFFFFF));
                            else if (jal_4 || jalr_4)   mem_wr_data <= jmp_temp_3   & (funct3_2 == 3'b000 ? 32'hFF : (funct3_2 == 3'b001 ? 32'hFFFF : 32'hFFFFFFFF));
                            else if (load_4         )   mem_wr_data <= load_out     & (funct3_2 == 3'b000 ? 32'hFF : (funct3_2 == 3'b001 ? 32'hFFFF : 32'hFFFFFFFF));
                            else if (arith_4        )   mem_wr_data <= alu_out_3    & (funct3_2 == 3'b000 ? 32'hFF : (funct3_2 == 3'b001 ? 32'hFFFF : 32'hFFFFFFFF));
                            else                        mem_wr_data <= REGS[rs2_2]  & (funct3_2 == 3'b000 ? 32'hFF : (funct3_2 == 3'b001 ? 32'hFFFF : 32'hFFFFFFFF));
                        else                            mem_wr_data <= REGS[rs2_2]  & (funct3_2 == 3'b000 ? 32'hFF : (funct3_2 == 3'b001 ? 32'hFFFF : 32'hFFFFFFFF));
                    end

                // Writeback current: _3
                lui_4 <= lui_3; auipc_4 <= auipc_3; jal_4 <= jal_3; jalr_4 <= jalr_3; load_4 <= load_3; arith_4 <= arith_3; rd_4 <= rd_3; load_5 <= load_4; funct3_4 <= funct3_3;
                if (rd_3 != 0 &&  lui_4           ) REGS[rd_3] <= imm_u_3;
                if (rd_3 != 0 &&  auipc_4         ) REGS[rd_3] <= auipc_temp_3;
                if (rd_3 != 0 && (jal_4 || jalr_4)) REGS[rd_3] <= jmp_temp_3;
                if (rd_4 != 0 &&  load_5          ) REGS[rd_4] <= load_out;
                if (rd_3 != 0 &&  arith_4         ) REGS[rd_3] <= alu_out_3;
            end
    end
endmodule

// module riscv32_testbench();
// 	parameter CLOCK_PERIOD = 100;
//     parameter NUM_LEDS     = 10;
//     parameter NUM_KEYS     = 4;
//     parameter NUM_SEGMENTS = 8;

//     logic                    CLOCK_50;
//     logic [    NUM_KEYS-1:0] KEY;
//     logic [NUM_SEGMENTS-1:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
//     logic [    NUM_LEDS-1:0] LEDR;

//     riscv32 dut (
//         .CLOCK_50 ( CLOCK_50 ),
//         .HEX0     ( HEX0     ),
//         .HEX1     ( HEX1     ),
//         .HEX2     ( HEX2     ),
//         .HEX3     ( HEX3     ),
//         .HEX4     ( HEX4     ),
//         .HEX5     ( HEX5     ),
//         .KEY      ( KEY      ),
//         .LEDR     ( LEDR     )
//     );

// 	initial begin
//         $dumpfile("test.vcd");
//         $dumpvars(0, riscv32_testbench);
// 		CLOCK_50 <= 0;
// 		forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50;
// 	end

// 	initial begin
//         // $monitor("time: %0d ; pc: 0x%h ; opcode: %07b ; funct3: %03b ; funct7: %03b, a: %h ; b: %h ; op: %d ; alu_out: %h ; ra: %h ; sp: %h ; a0: %h ; mem_rd_data: %h ; mem_addr: %h ; mem_wr_data: %h ; load_out: %h",
//         //           $time(), dut.pc, dut.opcode, dut.funct3, dut.funct7, dut.a, dut.b, dut.op, dut.alu_out, dut.REGS[1], dut.REGS[2], dut.REGS[10], dut.mem_rd_data, dut.mem_addr, dut.mem_wr_data, dut.load_out);

//         $monitor("HEX0: %b; HEX1: %b; HEX2: %b; HEX3: %b", HEX0, HEX1, HEX2, HEX3);
//         KEY[0] <= 0;                @(posedge CLOCK_50);
//         KEY[0] <= 1; repeat(1223)   @(posedge CLOCK_50);    // previously : 3159, Now: 1223
//         $finish;
//     end
// endmodule
