# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  ipgui::add_param $IPINST -name "xAddr"
  ipgui::add_param $IPINST -name "yAddr"

}

proc update_PARAM_VALUE.xAddr { PARAM_VALUE.xAddr } {
	# Procedure called to update xAddr when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.xAddr { PARAM_VALUE.xAddr } {
	# Procedure called to validate xAddr
	return true
}

proc update_PARAM_VALUE.yAddr { PARAM_VALUE.yAddr } {
	# Procedure called to update yAddr when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.yAddr { PARAM_VALUE.yAddr } {
	# Procedure called to validate yAddr
	return true
}


proc update_MODELPARAM_VALUE.xAddr { MODELPARAM_VALUE.xAddr PARAM_VALUE.xAddr } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.xAddr}] ${MODELPARAM_VALUE.xAddr}
}

proc update_MODELPARAM_VALUE.yAddr { MODELPARAM_VALUE.yAddr PARAM_VALUE.yAddr } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.yAddr}] ${MODELPARAM_VALUE.yAddr}
}

