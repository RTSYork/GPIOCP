# bdName: name of the board design.
# fName: filename of the YAML description of the board.
proc ::bs::create_bd_from_yaml {bdName fName} {
	# Try and open the file
	set f [open $fName "r"]
	set yamlContents [read $f]
	close $f

	set bdDesc [yaml::yaml2dict $yamlContents]

	# Ok, got the desc. Do some sanity checking
	if { ![dict exists $bdDesc "clock"] } {
		puts "No 'clock' element found in board description. Aborting."
		return TCL_ERROR
	}

	if { ![dict exists $bdDesc "reset"] } {
		puts "No 'reset' element found in board description. Aborting."
		return TCL_ERROR
	}

	# Create the board
	set bd [create_bd_design $bdName]

	# Figure out the clock type
	set clkDict [dict get $bdDesc "clock"]
	switch [dict get $clkDict "style"] {
		standard {
			bs::create_standard_clock $bd $clkDict
		}
		mig {
			bs::create_mig_clock $bd $clkDict
		}
		zynq {
			bs::create_zynq_clock $bd $clkDict
		}
	}

	# And the reset
	set rstDict [dict get $bdDesc "reset"]
	bs::create_standard_reset $bd $rstDict

	# Now to instantiate all of the IP
	set ips [dict get $bdDesc "ip"]
	foreach {ip} $ips {
		# Get the IP VLNV if possible
		set ipVlnv [dict get $ip "vlnv"]
		set vlnv [get_ipdefs -regexp ".*:[set ipVlnv]:.*"]

		if { [llength $vlnv] != 1 } {
			puts "ERROR: VLNV $ipVlnv matched more than one IP core. Please be more specific."
			puts "Cores matched: $vlnv"
			return TCL_ERROR
		}

		# Is there any special case rule for that VLNV?
		set specialCase [::bs::specialcase::getInstForVLNV $vlnv]
		if {$specialCase == ""} {
			set ipInst [create_bd_cell -type ip -vlnv $vlnv [dict get $ip "name"]]

			# Apply any parameters
			if {[dict exists $ip "parameters"]} {
				set params [dict get $ip "parameters"]
				apply_parameters_to_inst $ipInst $params
			}

			# Connect up the clocks
			set ipClk [get_bd_pins -of $ipInst -filter {TYPE == clk}]
			connect_bd_net -net bs_autogen_clk $ipClk

			# And resets
			set ipRst [get_bd_pins -quiet -of $ipInst -filter {TYPE == rst && CONFIG.POLARITY == ACTIVE_LOW}]
			connect_bd_net -quiet -net bs_autogen_rstn_peripheral $ipRst

			set ipRst [get_bd_pins -quiet -of $ipInst -filter {TYPE == rst && CONFIG.POLARITY == ACTIVE_HIGH}]
			connect_bd_net -quiet -net bs_autogen_rst_peripheral $ipRst
		} else {
			set ipInst [$specialCase $ip]
		}
	}

	# Now create the Bluetiles interconnect
	# Get the rows and columns
	set tileConnections [dict get $bdDesc "tilenet"]
	set tileY [llength $tileConnections]
	set tileX 0

	# Get the longest X axis
	foreach {yaxis} $tileConnections {
		if {[llength $yaxis] > $tileX} {
			set tileX [llength $yaxis]
		}
	}

	if {$tileX == 0} {
		puts "ERROR: No tile X axis!"
		return TCL_ERROR
	}
	if {$tileY == 0} {
		puts "ERROR: No tile Y axis!"
		return TCL_ERROR
	}

	# Create the bluetiles network
	set tileCell [bs::create_bluetiles_net_hier $tileX $tileY "bluetilesnet"]
	connect_bd_net -net bs_autogen_clk [get_bd_pins $tileCell/CLK]
	connect_bd_net -net bs_autogen_rstn_interconnect [get_bd_pins $tileCell/RST_N]

	set curY 0
	foreach {yaxis} $tileConnections {
		set curX 0
		foreach {xaxis} $yaxis {
			# Get the interface port
			set btPort [get_bd_intf_pins "$tileCell/home_[set curX]_[set curY]"]

			# Name of the cell
			set cellName [dict get $xaxis "name"]
			set cell [get_bd_cells $cellName]
			
			# Get the VLNV of the cell
			set cellVlnv [dict get $xaxis "vlnv"]
			set vlnv [get_ipdefs -regexp ".*:[set cellVlnv]:.*"]

			# Is there a special case?
			set specialCase [::bs::specialcase::getTileConnectForVLNV $vlnv]
			if {$specialCase == ""} {
				# We try and conncet to a magic port called "bluetile"
				connect_bd_intf_net [get_bd_intf_pins $cell/bluetile] $btPort
			} else {
				# Call the special case connection
				$specialCase $cell $btPort
			}

			incr curX
		}

		incr curY
	}

	# Tree net
	if {[dict exists $bdDesc "treenet"]} {
		set treeDesc [dict get $bdDesc "treenet"]
		set treeConnections [dict get $treeDesc "clients"]
		set treeClients [llength $treeConnections]

		# Round up to nearest power of 2
		set treeClientsRounded [expr { 2 ** int(ceil([log2 $treeClients])) }]

		# Just to shut the tools up a bit.
		if {$treeClientsRounded == 1} {
			set treeClientsRounded 2
		}

		# Create the tree
		set treenet [bs::create_bluetree_net_hier $treeClientsRounded "treenet"]
		set curCli 0

		connect_bd_net -net bs_autogen_clk [get_bd_pins $treenet/CLK]
		connect_bd_net -net bs_autogen_rstn_interconnect [get_bd_pins $treenet/RST_N]

		foreach {cli} $treeConnections {
			set treePort [get_bd_intf_pins "$treenet/server_$curCli"]

			# Name of the cell
			set cellName [dict get $cli "name"]
			set cell [get_bd_cells $cellName]
			
			# Get the VLNV of the cell
			set cellVlnv [dict get $cli "vlnv"]
			set vlnv [get_ipdefs -regexp ".*:[set cellVlnv]:.*"]

			# Is there a special case?
			set specialCase [::bs::specialcase::getTreeConnectForVLNV $vlnv]
			if {$specialCase == ""} {
				connect_bd_intf_net [get_bd_intf_pins $cell/bluetree] $treePort
			} else {
				# Call the special case connection
				$specialCase $cell $treePort
			}

			incr curCli
		}

		# Figure out the root connection
		set treeRoot [dict get $treeDesc "root"]

		switch [dict get $treeRoot "type"] {
			mig {
				bs::create_tree_root_mig $treeRoot [get_bd_intf_pins $treenet/client]
			}
		}
	}

	return $bd
}

proc ::bs::apply_parameters_to_inst {instance parameterDict} {
	# We can actually cheat for this one!
    if {[dict size $parameterDict] > 0} {
	set_property -dict $parameterDict $instance
    }
}

proc ::bs::create_standard_clock { bd clkDict } {
	# This is done by creating a standard clock manager
	# Need to actually find the clock manager first
	set clkManagerVlnv [get_ipdefs -regexp "xilinx.com:ip:clk_wiz:.*"]
	if {[llength $clkManagerVlnv] != 1} {
		puts "Query did not return a single clock wizard. Aborting."
		return TCL_ERROR
	}

	# Instantiate
	set clkManager [create_bd_cell -type ip -vlnv $clkManagerVlnv bs_clock_manager]

	# Set frequency
	set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ [dict get $clkDict "frequency"] $clkManager

	# Run board automation?
	if { [dict exists $clkDict "bdAutomation"] && [dict get $clkDict "bdAutomation"]} {
		apply_bd_automation -rule xilinx.com:bd_rule:board [get_bd_pins $clkManager/clk_in1]
		apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "reset"}  [get_bd_pins $clkManager/reset]
	}

	# Finally, connect the output to something useful
	connect_bd_net -net bs_autogen_clk [get_bd_pins $clkManager/clk_out1]
	connect_bd_net -net bs_autogen_clk_locked [get_bd_pins $clkManager/locked]
}

proc ::bs::create_mig_clock { bd clkDict } {
	# This is done by creating a standard clock manager
	# Need to actually find the clock manager first
	set clkManagerVlnv [get_ipdefs -regexp "xilinx.com:ip:clk_wiz:.*"]
	if {[llength $clkManagerVlnv] != 1} {
		puts "Query did not return a single clock wizard. Aborting."
		return TCL_ERROR
	}

	# Instantiate
	set clkManager [create_bd_cell -type ip -vlnv $clkManagerVlnv bs_clock_manager]

	# Set frequency
	set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ [dict get $clkDict "frequency"] $clkManager

	# Run board automation?
	if { [dict exists $clkDict "bdAutomation"] && [dict get $clkDict "bdAutomation"]} {
		apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "reset"}  [get_bd_pins $clkManager/reset]
	}

	connect_bd_net -net bs_mig_ui_clk [get_bd_pins $clkManager/clk_in1]

	# Connect the output to something useful
	connect_bd_net -net bs_autogen_clk [get_bd_pins $clkManager/clk_out1]

	# Create an AND gate for the locked from this and from the MIG
	set vec_logic_vlnv [get_ipdefs -regexp "xilinx.com:ip:util_vector_logic:.*"]
	set vec_logic [create_bd_cell -type ip -vlnv $vec_logic_vlnv "mmcm_locked_and"]

	set_property CONFIG.C_SIZE 1 $vec_logic
	set_property CONFIG.C_OPERATION and $vec_logic

	connect_bd_net [get_bd_pins $clkManager/locked] [get_bd_pins $vec_logic/Op1]
	connect_bd_net -net bs_autogen_clk_locked [get_bd_pins $vec_logic/Res]
	connect_bd_net -net bs_mig_ui_clk_locked [get_bd_pins $vec_logic/Op2]
}

proc ::bs::create_zynq_clock { bd clkDict } {
	# For the Zynq, we just connect to a net. Don't create one, it won't work properly
	# Create the DCM locked signal
	set constantVlnv [get_ipdefs -regexp "xilinx.com:ip:xlconstant:.*"]
	set constant [create_bd_cell -type ip -vlnv $constantVlnv bs_dcm_locked_driver]

	create_bd_net bs_autogen_clk
	connect_bd_net -net bs_autogen_clk_locked [get_bd_pins $constant/dout]

	puts "WARNING: Zynq clock frequency is currently ignored. Please bear this in mind when creating designs."
}

proc ::bs::create_standard_reset { bd rstDict } {
	set rstManagerVlnv [get_ipdefs -regexp "xilinx.com:ip:proc_sys_reset:.*"]
	if {[llength $rstManagerVlnv] != 1}  {
		puts "Query did not return a single reset manager. Aborting."
		return TCL_ERROR
	}

	set rstManager [create_bd_cell -type ip -vlnv $rstManagerVlnv bs_reset_manager]

	if { [dict exists $rstDict "bdAutomation"] && [dict get $rstDict "bdAutomation"]} {
		apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "reset" }  [get_bd_pins $rstManager/ext_reset_in]
	}

	# Connect up the locked signal
	connect_bd_net -net bs_autogen_clk_locked [get_bd_pins $rstManager/dcm_locked]

	# Expose the resets
	connect_bd_net -net bs_autogen_rstn_interconnect [get_bd_pins $rstManager/interconnect_aresetn]
	connect_bd_net -net bs_autogen_rstn_peripheral [get_bd_pins $rstManager/peripheral_aresetn]
	connect_bd_net -net bs_autogen_rst_peripheral [get_bd_pins $rstManager/peripheral_reset]

	# We assume the user clock is currently the slowest in the system
	connect_bd_net -net bs_autogen_clk [get_bd_pins $rstManager/slowest_sync_clk]
}

proc ::bs::create_tree_root_mig { rootDict rootPort } {
	# First, we need a Bluetree splitter
	set bluesplit_vlnv [get_ipdefs -regexp "york.ac.uk:blueshell:bluetree_memoverlay:.*"]
	set bluesplit [create_bd_cell -type ip -vlnv $bluesplit_vlnv "treenet_root_bluetreesplit"]

	# Now need 2xAXI bridges
	set axi_bridge_vlnv [get_ipdefs -regexp "york.ac.uk:blueshell:bluetree_axi3_bridge:.*"]
	set axi_bridge_0 [create_bd_cell -type ip -vlnv $axi_bridge_vlnv "treenet_root_axibridge_bram"]
	set axi_bridge_1 [create_bd_cell -type ip -vlnv $axi_bridge_vlnv "treenet_root_axibridge_ddr"]
	set interconnect_0 [create_bd_cell -type ip -vlnv "xilinx.com:ip:axi_interconnect:2.1" "treenet_root_intc_bram"]
	set interconnect_1 [create_bd_cell -type ip -vlnv "xilinx.com:ip:axi_interconnect:2.1" "treenet_root_intc_ddr"]

	# Vector logic for the resetter
	set vec_logic_vlnv [get_ipdefs -regexp "xilinx.com:ip:util_vector_logic:.*"]
	set vec_logic [create_bd_cell -type ip -vlnv $vec_logic_vlnv "treenet_root_mig_rstinv"]

	# Overlay size is expressed as a number of 32-bit words
	if {[dict exists $rootDict "overlaySize"]} {
		set overlay_size [dict get $rootDict "overlaySize"]
	} else {
		set overlay_size 1024
	}

	set_property CONFIG.C_SIZE 1 $vec_logic
	set_property CONFIG.C_OPERATION not $vec_logic

	set_property CONFIG.NUM_MI 1 $interconnect_0
	set_property CONFIG.NUM_SI 1 $interconnect_0
	set_property CONFIG.NUM_MI 1 $interconnect_1
	set_property CONFIG.NUM_SI 1 $interconnect_1

	# Create the BRAM controller
	set bram_ctrl_vlnv [get_ipdefs -regexp "xilinx.com:ip:axi_bram_ctrl:.*"]
	set bram_ctrl [create_bd_cell -type ip -vlnv $bram_ctrl_vlnv "treenet_root_bram_ctrl"]
	set bram_vlnv [get_ipdefs -regexp "xilinx.com:ip:blk_mem_gen:.*"]
	set bram [create_bd_cell -type ip -vlnv $bram_vlnv "treenet_root_bram"]
	set slice_vlnv [get_ipdefs -regexp "xilinx.com:ip:xlslice:.*"]
	set slice [create_bd_cell -type ip -vlnv $slice_vlnv "treenet_root_bram_addrslice"]

	# Lots of properties for the BRAM
	# For simplicity, we're going to assume a 4K BRAM for now
	# TODO: Make this a proper parameter later...
	set_property -dict [list CONFIG.Use_Byte_Write_Enable {true} \
	                         CONFIG.Byte_Size {8} \
	                         CONFIG.Write_Width_A {32} \
	                         CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
	                         CONFIG.Use_RSTA_Pin {true} \
	                         CONFIG.use_bram_block {Stand_Alone} \
	                         CONFIG.Enable_32bit_Address {false} \
	                         CONFIG.Read_Width_A {32} \
	                         CONFIG.Write_Width_B {32} \
	                         CONFIG.Write_Depth_A $overlay_size \
	                         CONFIG.Read_Width_B {32}] $bram

	set_property CONFIG.highAddr [expr {($overlay_size / 4) - 1}] $bluesplit

	if {[dict exists $rootDict "bootfile"]} {
		set_property -dict [list CONFIG.Coe_File [file normalize [dict get $rootDict "bootfile"]] CONFIG.Load_Init_File {true}] $bram
	}

	set_property CONFIG.SINGLE_PORT_BRAM 1 $bram_ctrl

	set overlay_addr_width [expr {int(ceil([log2 [expr $overlay_size * 4]]))}]
	set_property CONFIG.DIN_WIDTH $overlay_addr_width $slice
	set_property CONFIG.DIN_FROM [expr $overlay_addr_width - 1] $slice
	set_property CONFIG.DIN_TO 2 $slice


	# Create the mig
	# This is a difficult one to connect, so just run the board automation. If you do not want
	# board automation, this will have to be done manually.
	set mig_vlnv [get_ipdefs -regexp "xilinx.com:ip:mig_7series:.*"]
	set mig [create_bd_cell -type ip -vlnv $mig_vlnv "treenet_root_mig"]

	if {[dict exists $rootDict "bdInterface"]} {
		set mig_automation_dict [dict create "Board_Interface" [dict get $rootDict "bdInterface"]]

		apply_bd_automation -rule xilinx.com:bd_rule:mig_7series -config $mig_automation_dict $mig
	} else {
		apply_bd_automation -rule xilinx.com:bd_rule:mig_7series -config {Board_Interface "ddr3_sdram" } $mig
	}
	
	apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "reset" }  [get_bd_pins $mig/sys_rst]

	# Connect everything up
	connect_bd_intf_net $rootPort [get_bd_intf_pins $bluesplit/server]
	connect_bd_intf_net [get_bd_intf_pins $bluesplit/client0] [get_bd_intf_pins $axi_bridge_0/bluetree]
	connect_bd_intf_net [get_bd_intf_pins $bluesplit/client1] [get_bd_intf_pins $axi_bridge_1/bluetree]

	connect_bd_intf_net [get_bd_intf_pins $axi_bridge_0/axi_read] [get_bd_intf_pins $interconnect_0/S00_AXI]
	connect_bd_intf_net [get_bd_intf_pins $interconnect_0/M00_AXI] [get_bd_intf_pins $bram_ctrl/S_AXI]

	connect_bd_intf_net [get_bd_intf_pins $axi_bridge_1/axi_read] [get_bd_intf_pins $interconnect_1/S00_AXI]
	connect_bd_intf_net [get_bd_intf_pins $interconnect_1/M00_AXI] [get_bd_intf_pins $mig/S_AXI]

	# BRAM connections
	connect_bd_net [get_bd_pins $bram_ctrl/bram_clk_a] [get_bd_pins $bram/clka]
	connect_bd_net [get_bd_pins $bram_ctrl/bram_wrdata_a] [get_bd_pins $bram/dina]
	connect_bd_net [get_bd_pins $bram_ctrl/bram_rddata_a] [get_bd_pins $bram/douta]
	connect_bd_net [get_bd_pins $bram_ctrl/bram_en_a] [get_bd_pins $bram/ena]
	connect_bd_net [get_bd_pins $bram_ctrl/bram_rst_a] [get_bd_pins $bram/rsta]
	connect_bd_net [get_bd_pins $bram_ctrl/bram_we_a] [get_bd_pins $bram/wea]

	connect_bd_net [get_bd_pins $bram_ctrl/bram_addr_a] [get_bd_pins $slice/Din]
	connect_bd_net [get_bd_pins $slice/Dout] [get_bd_pins $bram/addra]

	# Clocking
	# This is an annoying one
	connect_bd_net -net [get_bd_nets bs_autogen_clk] [get_bd_pins $axi_bridge_0/CLK] [get_bd_pins $axi_bridge_1/CLK] [get_bd_pins $interconnect_1/ACLK] [get_bd_pins $interconnect_1/S00_ACLK] [get_bd_pins $interconnect_0/ACLK] [get_bd_pins $interconnect_0/M00_ACLK] [get_bd_pins $interconnect_0/S00_ACLK]
	connect_bd_net -net [get_bd_nets bs_autogen_clk] [get_bd_pins $bluesplit/CLK] [get_bd_pins $bram_ctrl/s_axi_aclk]
	connect_bd_net -net [get_bd_nets bs_autogen_rstn_interconnect] [get_bd_pins $axi_bridge_0/RST_N] [get_bd_pins $axi_bridge_1/RST_N] [get_bd_pins $interconnect_1/ARESETN] [get_bd_pins $interconnect_1/S00_ARESETN] [get_bd_pins $interconnect_0/ARESETN] [get_bd_pins $interconnect_0/S00_ARESETN] [get_bd_pins $interconnect_0/M00_ARESETN]
	connect_bd_net -net [get_bd_nets bs_autogen_rstn_interconnect] [get_bd_pins $bluesplit/RST_N] [get_bd_pins $bram_ctrl/s_axi_aresetn]

	connect_bd_net [get_bd_pins $mig/ui_clk_sync_rst] [get_bd_pins $vec_logic/Op1]
	connect_bd_net [get_bd_pins $vec_logic/Res] [get_bd_pins $interconnect_1/M00_ARESETN] [get_bd_pins $mig/aresetn]

	# We connect this to a specially named net so that the clock generator can also connect to it
	connect_bd_net -net bs_mig_ui_clk [get_bd_pins $mig/ui_clk] [get_bd_pins $interconnect_1/M00_ACLK]
	connect_bd_net -net bs_mig_ui_clk_locked [get_bd_pins $mig/mmcm_locked]

	if {[dict get $rootDict "overlaySize"]} {
		create_bd_addr_seg -range [expr {[dict get $rootDict "overlaySize"] * 4}] -offset 0x00000000 [get_bd_addr_spaces $axi_bridge_0/axi_read] [get_bd_addr_segs $bram_ctrl/S_AXI/Mem0] "SEG_tree_root_bram"
	} else {
		create_bd_addr_seg -range 4K -offset 0x00000000 [get_bd_addr_spaces $axi_bridge_0/axi_read] [get_bd_addr_segs $bram_ctrl/S_AXI/Mem0] "SEG_tree_root_bram"
	}
	
	create_bd_addr_seg -range 1G -offset 0x00000000 [get_bd_addr_spaces $axi_bridge_1/axi_read] [get_bd_addr_segs $mig/memmap/memaddr] "SEG_tree_root_ddr"
}


















