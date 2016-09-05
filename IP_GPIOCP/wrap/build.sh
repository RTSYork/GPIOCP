#!/bin/bash

ln -nfs $BLUESPECDIR/Verilog bsverilog
bsc -p %/Prelude:%/Libraries:../ -u -verilog ../Top_level.bsv
../../util/generate_server_wrapper < Top_level.yml > BS_GPIOProcessor.v
