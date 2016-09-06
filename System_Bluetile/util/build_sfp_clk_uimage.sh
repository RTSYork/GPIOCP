#!/bin/bash

mkimage -A arm -O u-boot -T script -C none -a 0x00100000 -e 0x00100000 -n "SFPInit" -d zc706_init_sfp_clk zc706_init_sfp_clk_uimage
