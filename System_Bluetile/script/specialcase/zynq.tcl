proc ::bs::specialcase::zynqInst {instDict} {
	# This is special-cased so we can add in special parameters later
	set ps7Vlnv [get_ipdefs -regexp "xilinx.com:ip:processing_system7:.*"]
	set ps7 [create_bd_cell -type ip -vlnv $ps7Vlnv [dict get $instDict "name"]]

	# Run board automation whether it was wanted or not
	apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells $ps7]

	# And connect
	connect_bd_net -net bs_autogen_clk [get_bd_pins $ps7/FCLK_CLK0]
	connect_bd_net -net bs_autogen_clk [get_bd_pins $ps7/M_AXI_GP0_ACLK]
	connect_bd_net [get_bd_pins $ps7/FCLK_RESET0_N] [get_bd_pins [get_bd_cells bs_reset_manager]/ext_reset_in]

	return $ps7
}

proc ::bs::specialcase::zynqTileNet {cell connTarget} {
	# This is a bit nasty.
	# We need to create an AXI FIFO, then connect that to an AXIS <-> Bluetiles bridge
	# To do that, we need an AXI interconnect too :/
	set ps7Name [get_property NAME $cell]

	# TODO: get_ipdefs with a wildcard version returns 1.7, not 2.1
	# Fix this later to do a proper search again.
	#set interconnectVlnv [get_ipdefs -regexp "xilinx.com:ip:axi_interconnect:2.1"]
	set interconnect [create_bd_cell -type ip -vlnv "xilinx.com:ip:axi_interconnect:2.1" "[set ps7Name]_bt_interconnect"]

	set_property CONFIG.NUM_MI 1 $interconnect

	# Axi MM FIFO
	set fifoVlnv [get_ipdefs -regexp "xilinx.com:ip:axi_fifo_mm_s:.*"]
	set fifo [create_bd_cell -type ip -vlnv $fifoVlnv "[set ps7Name]_bt_fifo"]
	set_property CONFIG.C_USE_TX_CTRL 0 $fifo

	# And now the AXI stream
	set axisVlnv [get_ipdefs -regexp "york.ac.uk:blueshell:bluetiles_axis:.*"]
	set axis [create_bd_cell -type ip -vlnv $axisVlnv "[set ps7Name]_bt_axis"]

	# Now connect!
	# Ugh
	puts "Connecting clock"
	connect_bd_net -net [get_bd_nets bs_autogen_clk] [get_bd_pins $interconnect/ACLK] [get_bd_pins $interconnect/S00_ACLK] [get_bd_pins $interconnect/M00_ACLK]
	connect_bd_net -net [get_bd_nets bs_autogen_clk] [get_bd_pins $fifo/s_axi_aclk]
	connect_bd_net -net [get_bd_nets bs_autogen_clk] [get_bd_pins $axis/CLK]

	puts "Connecting resets"
	connect_bd_net -net [get_bd_nets bs_autogen_rstn_interconnect] [get_bd_pins $interconnect/ARESETN] [get_bd_pins $interconnect/S00_ARESETN] [get_bd_pins $interconnect/M00_ARESETN]
	connect_bd_net -net [get_bd_nets bs_autogen_rstn_interconnect] [get_bd_pins $fifo/s_axi_aresetn]
	connect_bd_net -net [get_bd_nets bs_autogen_rstn_interconnect] [get_bd_pins $axis/RST_N]

	connect_bd_intf_net [get_bd_intf_pins $interconnect/M00_AXI] [get_bd_intf_pins $fifo/S_AXI]
	connect_bd_intf_net [get_bd_intf_pins $fifo/AXI_STR_TXD] [get_bd_intf_pins $axis/S_AXIS]
	connect_bd_intf_net [get_bd_intf_pins $fifo/AXI_STR_RXD] [get_bd_intf_pins $axis/M_AXIS]
	connect_bd_intf_net [get_bd_intf_pins $axis/bluetile] $connTarget

	connect_bd_intf_net [get_bd_intf_pins $cell/M_AXI_GP0] [get_bd_intf_pins $interconnect/S00_AXI]

	# Address assignment
	create_bd_addr_seg -range 64K -offset 0x40000000 [get_bd_addr_spaces $cell/Data] [get_bd_addr_segs $fifo/S_AXI/Mem0] "SEG_[set ps7Name]_fifo"

	# Set interrupts on and connect
	set_property -dict [list CONFIG.PCW_USE_FABRIC_INTERRUPT {1} CONFIG.PCW_IRQ_F2P_INTR {1}] $cell
	connect_bd_net [get_bd_pins $fifo/interrupt] [get_bd_pins $cell/IRQ_F2P]
}

# Register it!
proc ::bs::specialcase::zynqInit {} {
	variable specialcaseInst
	variable specialcaseTileConnect
	dict append specialcaseInst "xilinx.com:ip:processing_system7:5.5" "zynqInst"
	dict append specialcaseTileConnect "xilinx.com:ip:processing_system7:5.5" "zynqTileNet"
}
