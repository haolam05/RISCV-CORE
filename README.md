Introduction:
- 37 RV32 Base Instruction Set was implemented in Verilog and run on FPGA board
	(excluding system calls and CSRs)
- Can run arbitrary code that had compiled to RV32 executable
- Pipelining stages are added to increase throughput
- Demonstrate C printf() working by displaying string on FPGA 7 segment displays

To run:
In top level module riscv32.sv:
- Simulation & Testing
	+ comment out the riscv32_testbench()
	+ Set clkSelect = CLOCK_50 for Simulation on line 262
	+ run "./make"
	+ run "./test cpu"

- on FPGA (Set to correct version in chosen software)
	+ Set clkSelect = div_clk[WHICH_CLK] on line 263
	+ Compile and upload to the board
