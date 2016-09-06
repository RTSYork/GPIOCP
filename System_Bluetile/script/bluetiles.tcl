proc ::bs::create_bluetiles_net { xDim yDim clk_net rst_net {prefix ""} {xOff 0} {yOff 0} } {
	# Get the current version of the bluetiles router
	set router_vlnv [get_ipdefs "york.ac.uk:blueshell:bluetiles_router:*"]
	set router_name "[set prefix]router"

	set xDim [expr {$xDim + $xOff}]
	set yDim [expr {$yDim + $yOff}]

	# First create the routers
	for {set x $xOff} {$x < $xDim} {incr x} {
		for {set y $yOff} {$y < $yDim} {incr y} {
			set router [create_bd_cell -vlnv $router_vlnv "[set router_name]_[set x]_[set y]"]

			set_property "CONFIG.xAddr" $x $router
			set_property "CONFIG.yAddr" $y $router

			connect_bd_net -net $clk_net [get_bd_pins "[set router_name]_[set x]_[set y]/CLK"]
			connect_bd_net -net $rst_net [get_bd_pins "[set router_name]_[set x]_[set y]/RST_N"]
		}
	}

	# Now connect them up!
	for {set x $xOff} {$x < $xDim} {incr x} {
		for {set y $yOff} {$y < $yDim} {incr y} {
			if { $x != ($xDim - 1) } {
				connect_bd_intf_net [get_bd_intf_pins "[set router_name]_[set x]_[set y]/east"] [get_bd_intf_pins "[set router_name]_[expr {$x + 1}]_[set y]/west"]
			}

			if { $y != ($yDim - 1) } {
				connect_bd_intf_net [get_bd_intf_pins "[set router_name]_[set x]_[set y]/south"] [get_bd_intf_pins "[set router_name]_[set x]_[expr {$y + 1}]/north"]
			}
		}
	}
}

proc ::bs::create_bluetiles_net_hier { xDim yDim hierarchy_name {xOff 0} {yOff 0} } {
	set hier_cell [create_bd_cell -type hier $hierarchy_name]
	set hier_router_prefix "[set hierarchy_name]/"

	set hier_clk_net "clk_net"
	set hier_rst_net "rst_net"

	create_bluetiles_net $xDim $yDim $hier_clk_net $hier_rst_net $hier_router_prefix $xOff $yOff

	# Safe to use the previous values above as create_bluetiles_net does this internally
	set xDim [expr {$xDim + $xOff}]
	set yDim [expr {$yDim + $yOff}]

	# Now need to create the external interface ports
	for {set x $xOff} {$x < $xDim} {incr x} {
		for {set y $yOff} {$y < $yDim} {incr y} {
			set hier_port [create_bd_intf_pin -mode Slave -vlnv "york.ac.uk:blueshell:bluetiles_interconnect_rtl:1.0" "[set hierarchy_name]/home_[set x]_[set y]"]
			connect_bd_intf_net [get_bd_intf_pins "[bs::get_bluetiles_router $x $y $hier_router_prefix]/home"] $hier_port
		}
	}

	# Finally, make the external clock pin
	set hier_clk_pin [create_bd_pin -dir I -type CLK "[set hierarchy_name]/CLK"]
	set hier_rst_pin [create_bd_pin -dir I -type RST "[set hierarchy_name]/RST_N"]

	# I can't actually find a prettier way of doing this...
	connect_bd_net $hier_clk_pin [get_bd_pins [get_bluetiles_router $xOff $yOff $hier_router_prefix]/CLK]
	connect_bd_net $hier_rst_pin [get_bd_pins [get_bluetiles_router $xOff $yOff $hier_router_prefix]/RST_N]

	return $hier_cell
}

proc ::bs::get_bluetiles_router { x y { prefix "" } } {
	set router_name "[set prefix]router"
	return [get_bd_cells "[set router_name]_[set x]_[set y]"]
}

proc ::bs::get_bluetiles_routers { {prefix "" } } {
	set router_name "[set prefix]router"
	return [get_bd_cells "[set router_name]_*_*"]
}