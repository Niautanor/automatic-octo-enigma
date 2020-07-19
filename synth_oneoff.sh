#!/bin/bash
yosys -p "synth_ice40 -blif $1.blif" $1.v && arachne-pnr -d 8k -P tq144:4k -p $1.pcf $1.blif -o $1.txt && icepack $1.txt $1.bin
