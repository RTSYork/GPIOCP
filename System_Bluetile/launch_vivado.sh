#!/bin/bash

# This script is a helper to automatically source all
# blueshell specific scripts when launching Vivado.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
vivado -source $DIR/script/init.tcl $@
