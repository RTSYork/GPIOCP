# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  set ignore [ipgui::add_param $IPINST -name "ignore"]
  set_property tooltip {A Bluetiles port to ignore} ${ignore}

}

proc update_PARAM_VALUE.ignore { PARAM_VALUE.ignore } {
	# Procedure called to update ignore when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ignore { PARAM_VALUE.ignore } {
	# Procedure called to validate ignore
	return true
}


proc update_MODELPARAM_VALUE.ignore { MODELPARAM_VALUE.ignore PARAM_VALUE.ignore } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ignore}] ${MODELPARAM_VALUE.ignore}
}

