# Special case to create a Microblaze tile
# instDict: 
proc ::bs::specialcase::microblazeInst {instDict} {
	# This is special-cased so we can add in special parameters later
	# Get the MBlaze VLNV
	set mblazeVlnv [get_ipdefs -regexp "xilinx.com:ip:microblaze:.*"]

	# First, create a hierarchy to hold it all
	set mblaze_hier [create_bd_cell -type hier [dict get $instDict "name"]]

	set mblaze [create_bd_cell -type ip -vlnv $mblazeVlnv "$mblaze_hier/[dict get $instDict "name"]_mblaze"]

	# First create the hierarchy pins
	set clkPin [create_bd_pin -dir I -type CLK "$mblaze_hier/CLK"]
	set interconnect_rstn [create_bd_pin -dir I -type RST "$mblaze_hier/interconnect_rstn"]
	set periph_rstn [create_bd_pin -dir I -type RST "$mblaze_hier/peripheral_rstn"]
	set periph_rst [create_bd_pin -dir I -type RST "$mblaze_hier/peripheral_rst"]

	# Connect up to the resets and clocks
	connect_bd_net [get_bd_pins $mblaze/Reset] [get_bd_pins [get_bd_cells bs_reset_manager]/mb_reset]
	connect_bd_net $clkPin [get_bd_pins $mblaze/Clk]
	connect_bd_net -net [get_bd_nets bs_autogen_clk] $clkPin
	connect_bd_net -net [get_bd_nets bs_autogen_rstn_interconnect] $interconnect_rstn
	connect_bd_net -net [get_bd_nets bs_autogen_rstn_peripheral] $periph_rstn
	connect_bd_net -net [get_bd_nets bs_autogen_rst_peripheral] $periph_rst

	# We should apply parameters if found
	if {[dict exists $instDict "parameters"]} {
		set params [dict get $instDict "parameters"]

		# Take off any custom ones
		if {[dict exists $params "localMemory"]} {
			mblaze_add_local_memory $mblaze_hier [dict get $params "localMemory"]
			dict unset params "localMemory"
		}

		if {[dict exists $params "cacheSize"]} {
			set cSize [dict get $params "cacheSize"]
			dict unset params "cacheSize"

			set_property CONFIG.C_USE_ICACHE 1 $mblaze
			set_property CONFIG.C_USE_DCACHE 1 $mblaze
			set_property CONFIG.C_CACHE_BYTE_SIZE $cSize $mblaze
			set_property CONFIG.C_DCACHE_BYTE_SIZE $cSize $mblaze

			# Enable caches by default.
			# See reference manual page 155 for the magic number
			set_property CONFIG.C_RESET_MSR 0x000000a0 $mblaze
		}

		# Turn on basically everything.
		if {[dict exists $params "fatBlaze"]} {
			if {[dict get $params "fatBlaze"]} {
				set_property -dict [list CONFIG.C_USE_MSR_INSTR {1} \
			    	                     CONFIG.C_USE_PCMP_INSTR {1} \
			    	                     CONFIG.C_USE_BARREL {1} \
			    	                     CONFIG.C_USE_DIV {1} \
			    	                     CONFIG.C_USE_HW_MUL {1} \
			    	                     CONFIG.C_USE_FPU {2} \
			    	                     CONFIG.C_PVR {2} \
			    	                     CONFIG.C_USE_EXTENDED_FSL_INSTR {1} ] $mblaze
			}
			dict unset params "fatBlaze"
		}

		# Finally, apply the normal parameters
		bs::apply_parameters_to_inst $mblaze $params
	}

        puts "DONE"
	return $mblaze
}

proc ::bs::specialcase::microblazeTileNet {cell connTarget} {
	# Microblaze is a weird one. It needs connecting to an AXI-stream bridge
	# Create the stream links
	set mblazeName [get_property NAME $cell]
	set mblaze [get_bd_cells "$cell/*_mblaze"]

	set_property CONFIG.C_FSL_LINKS 1 $mblaze

	# Then create the AXIS bridge
	set axiBtVlnv [get_ipdefs -regexp "york.ac.uk:blueshell:bluetiles_axis:.*"]
	set axiBt [create_bd_cell -type ip -vlnv $axiBtVlnv "$cell/[set mblazeName]_axisbridge"]

	# Connect up the clocks
	connect_bd_net [get_bd_pins "$cell/CLK"] [get_bd_pins $axiBt/CLK]
	connect_bd_net [get_bd_pins "$cell/peripheral_rstn"] [get_bd_pins $axiBt/RST_N]

	# Connect up the AXIS
	connect_bd_intf_net [get_bd_intf_pins $mblaze/M0_AXIS] [get_bd_intf_pins $axiBt/S_AXIS]
	connect_bd_intf_net [get_bd_intf_pins $axiBt/M_AXIS] [get_bd_intf_pins $mblaze/S0_AXIS]

	# Finally, connect up the Bluetiles
	connect_bd_intf_net [get_bd_intf_pins $axiBt/bluetile] $connTarget
}

proc ::bs::specialcase::microblazeTreeNet {cell connTarget} {
	# Create two AXI interconnects for the I/D sides
	set mblazeName [get_property NAME $cell]
	set mblaze [get_bd_cells "$cell/*_mblaze"]
	set muxVlnv [get_ipdefs -regexp "york.ac.uk:blueshell:bluetree_mux2:.*"]
	set bridgeVlnv [get_ipdefs -regexp "york.ac.uk:blueshell:axi_bluetree_bridge:.*"]

	set data_int [create_bd_cell -type ip -vlnv "xilinx.com:ip:axi_interconnect:2.1" "$cell/[set mblazeName]_tree_data"]
	set inst_int [create_bd_cell -type ip -vlnv "xilinx.com:ip:axi_interconnect:2.1" "$cell/[set mblazeName]_tree_inst"]
	set data_bridge [create_bd_cell -type ip -vlnv $bridgeVlnv "$cell/[set mblazeName]_tree_data_bridge"]
	set inst_bridge [create_bd_cell -type ip -vlnv $bridgeVlnv "$cell/[set mblazeName]_tree_inst_bridge"]
	set mux [create_bd_cell -type ip -vlnv $muxVlnv "$cell/[set mblazeName]_mux"]

	set_property CONFIG.NUM_MI 1 $data_int
	set_property CONFIG.NUM_MI 1 $inst_int

	# Connections
	if {[get_property CONFIG.C_USE_DCACHE $mblaze] == 1} {
		connect_bd_intf_net [get_bd_intf_pins $mblaze/M_AXI_DC] [get_bd_intf_pins $data_int/S00_AXI]
	} else {
		set_property CONFIG.C_D_AXI 1 $mblaze
		connect_bd_intf_net [get_bd_intf_pins $mblaze/M_AXI_DP] [get_bd_intf_pins $data_int/S00_AXI]
	}

	if {[get_property CONFIG.C_USE_ICACHE $mblaze] == 1} {
		connect_bd_intf_net [get_bd_intf_pins $mblaze/M_AXI_IC] [get_bd_intf_pins $inst_int/S00_AXI]
	} else {
		set_property CONFIG.C_I_AXI 1 $mblaze
		connect_bd_intf_net [get_bd_intf_pins $mblaze/M_AXI_IP] [get_bd_intf_pins $inst_int/S00_AXI]
	}

	connect_bd_intf_net [get_bd_intf_pins $data_int/M00_AXI] [get_bd_intf_pins $data_bridge/AXI]
	connect_bd_intf_net [get_bd_intf_pins $inst_int/M00_AXI] [get_bd_intf_pins $inst_bridge/AXI]
	connect_bd_intf_net [get_bd_intf_pins $data_bridge/bluetree] [get_bd_intf_pins $mux/server0]
	connect_bd_intf_net [get_bd_intf_pins $inst_bridge/bluetree] [get_bd_intf_pins $mux/server1]

	connect_bd_intf_net [get_bd_intf_pins $mux/client] $connTarget

	create_bd_addr_seg -range 0x80000000 -offset 0 [get_bd_addr_spaces $mblaze/Data] [get_bd_addr_segs $data_bridge/AXI/Reg] "SEG_[set mblazeName]_DAXI"
	create_bd_addr_seg -range 0x80000000 -offset 0 [get_bd_addr_spaces $mblaze/Instruction] [get_bd_addr_segs $inst_bridge/AXI/Reg] "SEG_[set mblazeName]_IAXI"

	connect_bd_net [get_bd_pins "$cell/CLK"] [get_bd_pins $data_int/ACLK] [get_bd_pins $data_int/S00_ACLK] [get_bd_pins $data_int/M00_ACLK]
	connect_bd_net [get_bd_pins "$cell/CLK"] [get_bd_pins $inst_int/ACLK] [get_bd_pins $inst_int/S00_ACLK] [get_bd_pins $inst_int/M00_ACLK]
	connect_bd_net [get_bd_pins "$cell/CLK"] [get_bd_pins $data_bridge/CLK] [get_bd_pins $inst_bridge/CLK]
	connect_bd_net [get_bd_pins "$cell/CLK"] [get_bd_pins $mux/CLK]

	connect_bd_net [get_bd_pins "$cell/interconnect_rstn"] [get_bd_pins $data_int/ARESETN] [get_bd_pins $data_int/S00_ARESETN] [get_bd_pins $data_int/M00_ARESETN]
	connect_bd_net [get_bd_pins "$cell/interconnect_rstn"] [get_bd_pins $inst_int/ARESETN] [get_bd_pins $inst_int/S00_ARESETN] [get_bd_pins $inst_int/M00_ARESETN]
	connect_bd_net [get_bd_pins "$cell/interconnect_rstn"] [get_bd_pins $data_bridge/RST_N] [get_bd_pins $inst_bridge/RST_N]
	connect_bd_net [get_bd_pins "$cell/interconnect_rstn"] [get_bd_pins $mux/RST_N]
}

# In this case, cell is a hierarchy to create everything under
proc ::bs::specialcase::mblaze_add_local_memory { cell memsize } {
	set mblazeName [get_property NAME $cell]
	set lmbBramVlnv [get_ipdefs -regexp "xilinx.com:ip:lmb_bram_if_cntlr:.*"]
	set lmbBram [create_bd_cell -type ip -vlnv $lmbBramVlnv "$cell/[set mblazeName]_lmb_bram"]
	set_property CONFIG.C_NUM_LMB 2 $lmbBram

	set bramVlnv [get_ipdefs -regexp "xilinx.com:ip:blk_mem_gen:.*"]
	set bram [create_bd_cell -type ip -vlnv $bramVlnv "$cell/[set mblazeName]_bram"]

	# Find the microblaze
	set mblaze [get_bd_cells "$cell/*_mblaze"]

	# Connections
	connect_bd_intf_net [get_bd_intf_pins $lmbBram/BRAM_PORT] [get_bd_intf_pins $bram/BRAM_PORTA]
	connect_bd_intf_net [get_bd_intf_pins $mblaze/DLMB] [get_bd_intf_pins $lmbBram/SLMB]
	connect_bd_intf_net [get_bd_intf_pins $mblaze/ILMB] [get_bd_intf_pins $lmbBram/SLMB1]

	connect_bd_net [get_bd_pins "$cell/CLK"] [get_bd_pins $lmbBram/LMB_Clk]
	connect_bd_net [get_bd_pins "$cell/peripheral_rst"] [get_bd_pins $lmbBram/LMB_Rst]

	# Finally, address segments
	create_bd_addr_seg -range $memsize -offset 0x80000000 [get_bd_addr_spaces $mblaze/Data] [get_bd_addr_segs $lmbBram/SLMB/Mem] "SEG_[set mblazeName]_DLMB"
	create_bd_addr_seg -range $memsize -offset 0x80000000 [get_bd_addr_spaces $mblaze/Instruction] [get_bd_addr_segs $lmbBram/SLMB1/Mem] "SEG_[set mblazeName]_ILMB"
}

# Register it!
proc ::bs::specialcase::microblazeInit {} {
	variable specialcaseInst
	variable specialcaseTileConnect
	variable specialcaseTreeConnect
	dict append specialcaseInst "xilinx.com:ip:microblaze:9.5" "microblazeInst"
	dict append specialcaseTileConnect "xilinx.com:ip:microblaze:9.5" "microblazeTileNet"
	dict append specialcaseTreeConnect "xilinx.com:ip:microblaze:9.5" "microblazeTreeNet"
}

