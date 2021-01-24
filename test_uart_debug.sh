#!/bin/bash
iverilog "$@" -o sram_debug_tb uart_debug_tb.v uart_debug.v uart_tx.v uart_rx.v sram_axi.v skidbuffer.v ../BlackIce-II/examples/sram/src/{sram_top,sram_ctrl,sram_io_ice40}.v $(yosys-config --datdir/ice40/cells_sim.v) bram_axi.v && ./sram_debug_tb
