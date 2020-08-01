#!/bin/bash
yosys -p "synth_ice40 -json $1.json" $1.v && \
nextpnr-ice40 --json $1.json --freq 100 --hx8k --package tq144:4k --pcf $1.pcf --asc $1.txt && \
icepack $1.txt $1.bin
