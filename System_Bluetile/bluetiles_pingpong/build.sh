#!/bin/bash

ln -nfs $BLUESPECDIR/Verilog bsverilog
bsc -p %/Prelude:%/Libraries:../common:. -u -verilog TilePingPong.bsv
