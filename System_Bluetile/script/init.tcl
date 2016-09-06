package require cmdline
package require yaml

namespace eval ::bs {
	# Exported commands
	namespace export create_project create_project_with_board
	namespace export create_bluetiles_net get_bluetiles_router create_bluetiles_net_hier get_bluetiles_routers
	namespace export create_bluetree_net
	namespace export create_bluetile_to_10g
	namespace export create_bd_from_yaml apply_parameters_to_inst

	# Auto-detect the Blueshell root directory (used to define an IP repo)
	variable rootdir [file normalize [file join [file dirname [info script]] "../"]]
}

puts "================================================================"
puts "        Setting up global specific Blueshell procedures"
puts "================================================================"

source [file join [file dirname [info script]] "project_management.tcl"]
source [file join [file dirname [info script]] "yaml2bd.tcl"]
source [file join [file dirname [info script]] "bluetree.tcl"]
source [file join [file dirname [info script]] "bluetiles.tcl"]
source [file join [file dirname [info script]] "tengig_ethernet.tcl"]
source [file join [file dirname [info script]] "specialcase/init.tcl"]
