namespace eval ::bs::specialcase {
	# Mapping of VLNV -> special case creation
	variable specialcaseInst [dict create]

	# Mapping of VLNV -> special case Bluetile connection
	variable specialcaseTileConnect [dict create]

	# Mapping of VLNV -> special case Bluetree connection
	variable specialcaseTreeConnect [dict create]

	namespace export getInstForVLNV
}

proc ::bs::specialcase::getInstForVLNV { VLNV } {
	variable specialcaseInst
	puts $specialcaseInst
	puts $VLNV
	if {[dict exists $specialcaseInst $VLNV]} {
		return "::bs::specialcase::[dict get $specialcaseInst $VLNV]"
	} else {
		return ""
	}
}

proc ::bs::specialcase::getTileConnectForVLNV { VLNV } {
	variable specialcaseTileConnect
	puts $specialcaseTileConnect
	puts $VLNV
	if {[dict exists $specialcaseTileConnect $VLNV]} {
		return "::bs::specialcase::[dict get $specialcaseTileConnect $VLNV]"
	} else {
		return ""
	}
}

proc ::bs::specialcase::getTreeConnectForVLNV { VLNV } {
	variable specialcaseTreeConnect
	puts $specialcaseTreeConnect
	puts $VLNV
	if {[dict exists $specialcaseTreeConnect $VLNV]} {
		return "::bs::specialcase::[dict get $specialcaseTreeConnect $VLNV]"
	} else {
		return ""
	}
}

source [file join [file dirname [info script]] "microblaze.tcl"]
bs::specialcase::microblazeInit
source [file join [file dirname [info script]] "zynq.tcl"]
bs::specialcase::zynqInit