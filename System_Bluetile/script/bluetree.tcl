proc log2 { x } {
	return [expr "log($x) / log(2)"]
}

proc ::bs::create_bluetree_net { nProcs clk_net rst_net {prefix ""} } {
	set mux_vlnv [get_ipdefs "york.ac.uk:blueshell:bluetree_mux2:*"]
	set mux_name "[set prefix]mux"

	# First, get the number of levels required
	set nLevels [log2 $nProcs]
	set nLevels [expr {floor($nLevels)}]

	# Now get the number of additional ones
	set nLevelsPow [expr {pow(2, $nLevels)}]
	set addnProcs [expr { int($nProcs - $nLevelsPow) }]

	# Now create the first set
	if { $addnProcs != 0 } {
		error "Cannot currently create non-power-of-two trees"
		return
	}

	# How many muxes do we actually want?
	# This always works out as nProcs - 1
	set muxes [list]

	for {set i 0} {$i < ($nProcs - 1)} {incr i} {
		set mux [create_bd_cell -vlnv $mux_vlnv "[set mux_name]_[set i]"]
		lappend muxes $mux

		# Connect up the clock and reset ports too
		connect_bd_net -net $clk_net [get_bd_pins $mux/CLK]
		connect_bd_net -net $rst_net [get_bd_pins $mux/RST_N]
	}

	# Now connect them up...
	set parent 0
	set baseId 1
	for {set toCreate 2} {$toCreate < $nProcs} {set toCreate [expr {$toCreate * 2}]} {
		for {set i 0} {$i < $toCreate} {incr i 2} {
			# Get the multiplexers
			set mux0 [lindex $muxes [expr {$baseId + $i + 0}]]
			set mux1 [lindex $muxes [expr {$baseId + $i + 1}]]
			set muxParent [lindex $muxes $parent]

			# And make the connections
			connect_bd_intf_net [get_bd_intf_pins $muxParent/server0] [get_bd_intf_pins $mux0/client]
			connect_bd_intf_net [get_bd_intf_pins $muxParent/server1] [get_bd_intf_pins $mux1/client]

			incr parent
		}
		incr baseId $toCreate
	}
}

proc ::bs::create_bluetree_net_hier { nProcs hierarchy_name } {
	# First, create the hierarchy
	set hier_cell [create_bd_cell -type hier $hierarchy_name]
	set hier_mux_prefix "[set hierarchy_name]/"

	set hier_clk_net "clk_net"
	set hier_rst_net "rst_net"

	create_bluetree_net $nProcs $hier_clk_net $hier_rst_net $hier_mux_prefix

	# Get the last muxes
	set muxes [get_bluetree_muxes $hier_mux_prefix]

	# Slice it to remove all but the last nProcs/2 ones (i.e. the last level ones)
	set requiredMuxes [expr { $nProcs / 2 }]
	set startIndex [expr {[llength $muxes] - $requiredMuxes}]
	set muxes [lrange $muxes $startIndex end]

	# Now expose those pins!
	for {set i 0} {$i < $nProcs} {incr i 2} {
		set hier_port_0 [create_bd_intf_pin -mode Slave -vlnv "york.ac.uk:blueshell:bluetree_interconnect_rtl:1.0" "[set hierarchy_name]/server_[expr {$i + 0}]"]
		set hier_port_1 [create_bd_intf_pin -mode Slave -vlnv "york.ac.uk:blueshell:bluetree_interconnect_rtl:1.0" "[set hierarchy_name]/server_[expr {$i + 1}]"]
		
		set parentMux [lindex $muxes [expr {$i / 2}]]
		connect_bd_intf_net [get_bd_intf_pins $parentMux/server0] $hier_port_0
		connect_bd_intf_net [get_bd_intf_pins $parentMux/server1] $hier_port_1
	}

	# Connect up the root
	set hier_client_port [create_bd_intf_pin -mode Master -vlnv "york.ac.uk:blueshell:bluetree_interconnect_rtl:1.0" "[set hierarchy_name]/client"]
	set rootMux [get_bluetree_mux 0 $hier_mux_prefix]
	connect_bd_intf_net [get_bd_intf_pins $rootMux/client] $hier_client_port

	# And the clock/reset
	set hier_clk_pin [create_bd_pin -dir I -type CLK "[set hier_mux_prefix]/CLK"]
	set hier_rst_pin [create_bd_pin -dir I -type RST "[set hier_mux_prefix]/RST_N"]

	connect_bd_net $hier_clk_pin [get_bd_pins $rootMux/CLK]
	connect_bd_net $hier_rst_pin [get_bd_pins $rootMux/RST_N]

	return $hier_cell
}

proc ::bs::get_bluetree_mux { muxIndex { prefix "" } } {
	set mux_name "[set prefix]mux"
	return [get_bd_cells "[set mux_name]_[set muxIndex]"]
}
proc ::bs::get_bluetree_muxes { { prefix "" } } {
	set mux_name "[set prefix]mux"
	return [get_bd_cells "[set mux_name]_*"]
}