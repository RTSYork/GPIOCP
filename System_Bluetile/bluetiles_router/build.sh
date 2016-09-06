#!/bin/bash

ln -nfs $BLUESPECDIR/Verilog bsverilog
bsc -p %/Prelude:%/Libraries:../common -u -verilog BluetilesRouter.bsv
../util/generate_server_wrapper < bluetiles_router.yml > BluetilesRouter.v
