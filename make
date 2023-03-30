#!/bin/bash
iverilog -Wall -g2012 -o cpu riscv32.sv instruction_memory.sv data_memory.sv counter.sv alu.sv load.sv display_control.sv display.sv clock_divider.sv decode.sv
