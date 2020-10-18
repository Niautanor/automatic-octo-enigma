#!/bin/bash
TARGET=$1
shift
yosys "$@" -p "synth_ice40 -json ${TARGET}.json" ${TARGET}.v && \
nextpnr-ice40 --json ${TARGET}.json --freq 100 --hx8k --package tq144:4k --pcf ${TARGET}.pcf --asc ${TARGET}.txt && \
icepack ${TARGET}.txt ${TARGET}.bin
