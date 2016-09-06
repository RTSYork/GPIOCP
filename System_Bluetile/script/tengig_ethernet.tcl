# Adapted from the output of Xilinx's board TCL writer.
proc ::bs::create_bluetile_to_10g { nameHier } {

  if { $nameHier eq "" } {
     puts "ERROR: create_hier_cell_bluetile_to_10g() - Empty argument(s)!"
     return
  }

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv york.ac.uk:blueshell:bluetiles_interconnect_rtl:1.0 bluetile

  # Create pins
  create_bd_pin -dir I CLK
  create_bd_pin -dir I -from 0 -to 0 RST_N
  create_bd_pin -dir O -from 0 -to 0 si5324_reset
  create_bd_pin -dir I tengig_refclk_n
  create_bd_pin -dir I tengig_refclk_p
  create_bd_pin -dir I tengig_rxn
  create_bd_pin -dir I tengig_rxp
  create_bd_pin -dir I -from 0 -to 0 tengig_signal_detect
  create_bd_pin -dir O tengig_tx_disable
  create_bd_pin -dir I -from 0 -to 0 tengig_tx_fault
  create_bd_pin -dir O tengig_txn
  create_bd_pin -dir O tengig_txp

  # Create instance: axi_10g_ethernet_0, and set properties
  set axi_10g_ethernet_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_10g_ethernet:3.0 axi_10g_ethernet_0 ]
  set_property -dict [ list CONFIG.Management_Interface {false} CONFIG.Statistics_Gathering {false} CONFIG.SupportLevel {1}  ] $axi_10g_ethernet_0

  # Create instance: bluetiles_axis_0, and set properties
  set bluetiles_axis_0 [ create_bd_cell -type ip -vlnv york.ac.uk:blueshell:bluetiles_axis:1.0 bluetiles_axis_0 ]

  # Create instance: pcs_pma_config, and set properties
  set pcs_pma_config [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 pcs_pma_config ]
  set_property -dict [ list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {536}  ] $pcs_pma_config

  # Create instance: rst_inverter, and set properties
  set rst_inverter [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 rst_inverter ]
  set_property -dict [ list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1}  ] $rst_inverter

  # Create instance: rx_cdc, and set properties
  set rx_cdc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 rx_cdc ]

  # Create instance: rx_config, and set properties
  set rx_config [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 rx_config ]
  set_property -dict [ list CONFIG.CONST_VAL {258} CONFIG.CONST_WIDTH {80}  ] $rx_config

  # Create instance: rx_ds, and set properties
  set rx_ds [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 rx_ds ]
  set_property -dict [ list CONFIG.M_TDATA_NUM_BYTES {4}  ] $rx_ds

  # Create instance: rx_pkt_buf, and set properties
  set rx_pkt_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 rx_pkt_buf ]
  set_property -dict [ list CONFIG.FIFO_MODE {2}  ] $rx_pkt_buf

  # Create instance: si5324_rst_driver, and set properties
  set si5324_rst_driver [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 si5324_rst_driver ]

  # Create instance: tx_cdc, and set properties
  set tx_cdc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 tx_cdc ]

  # Create instance: tx_config, and set properties
  set tx_config [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 tx_config ]
  set_property -dict [ list CONFIG.CONST_VAL {2} CONFIG.CONST_WIDTH {80}  ] $tx_config

  # Create instance: tx_pkt_buf, and set properties
  set tx_pkt_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 tx_pkt_buf ]
  set_property -dict [ list CONFIG.FIFO_MODE {2}  ] $tx_pkt_buf

  # Create instance: tx_us, and set properties
  set tx_us [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 tx_us ]
  set_property -dict [ list CONFIG.HAS_MI_TKEEP {1} CONFIG.M_TDATA_NUM_BYTES {8}  ] $tx_us

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1}  ] $util_vector_logic_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins bluetile] [get_bd_intf_pins bluetiles_axis_0/bluetile]
  connect_bd_intf_net -intf_net axi_10g_ethernet_0_m_axis_rx [get_bd_intf_pins axi_10g_ethernet_0/m_axis_rx] [get_bd_intf_pins rx_pkt_buf/S_AXIS]
  connect_bd_intf_net -intf_net bluetiles_axis_0_M_AXIS [get_bd_intf_pins bluetiles_axis_0/M_AXIS] [get_bd_intf_pins tx_us/S_AXIS]
  connect_bd_intf_net -intf_net rx_cdc_M_AXIS [get_bd_intf_pins rx_cdc/M_AXIS] [get_bd_intf_pins rx_ds/S_AXIS]
  connect_bd_intf_net -intf_net rx_ds_M_AXIS [get_bd_intf_pins bluetiles_axis_0/S_AXIS] [get_bd_intf_pins rx_ds/M_AXIS]
  connect_bd_intf_net -intf_net rx_pkt_buf_M_AXIS [get_bd_intf_pins rx_cdc/S_AXIS] [get_bd_intf_pins rx_pkt_buf/M_AXIS]
  connect_bd_intf_net -intf_net tx_cdc_M_AXIS [get_bd_intf_pins tx_cdc/M_AXIS] [get_bd_intf_pins tx_pkt_buf/S_AXIS]
  connect_bd_intf_net -intf_net tx_pkt_buf_M_AXIS [get_bd_intf_pins axi_10g_ethernet_0/s_axis_tx] [get_bd_intf_pins tx_pkt_buf/M_AXIS]
  connect_bd_intf_net -intf_net tx_us_M_AXIS [get_bd_intf_pins tx_cdc/S_AXIS] [get_bd_intf_pins tx_us/M_AXIS]

  # Create port connections
  connect_bd_net -net CLK_1 [get_bd_pins CLK] [get_bd_pins bluetiles_axis_0/CLK] [get_bd_pins rx_cdc/m_axis_aclk] [get_bd_pins rx_ds/aclk] [get_bd_pins tx_cdc/s_axis_aclk] [get_bd_pins tx_us/aclk]
  connect_bd_net -net RST_N_1 [get_bd_pins RST_N] [get_bd_pins axi_10g_ethernet_0/rx_axis_aresetn] [get_bd_pins axi_10g_ethernet_0/tx_axis_aresetn] [get_bd_pins bluetiles_axis_0/RST_N] [get_bd_pins rst_inverter/Op1] [get_bd_pins rx_cdc/m_axis_aresetn] [get_bd_pins rx_ds/aresetn] [get_bd_pins tx_cdc/s_axis_aresetn] [get_bd_pins tx_us/aresetn]
  connect_bd_net -net axi_10g_ethernet_0_areset_datapathclk_out [get_bd_pins rx_cdc/s_axis_aresetn] [get_bd_pins rx_pkt_buf/s_axis_aresetn] [get_bd_pins tx_cdc/m_axis_aresetn] [get_bd_pins tx_pkt_buf/s_axis_aresetn] [get_bd_pins util_vector_logic_0/Res]
  connect_bd_net -net axi_10g_ethernet_0_areset_datapathclk_out1 [get_bd_pins axi_10g_ethernet_0/areset_datapathclk_out] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net axi_10g_ethernet_0_coreclk_out [get_bd_pins axi_10g_ethernet_0/coreclk_out] [get_bd_pins axi_10g_ethernet_0/dclk] [get_bd_pins rx_cdc/s_axis_aclk] [get_bd_pins rx_pkt_buf/s_axis_aclk] [get_bd_pins tx_cdc/m_axis_aclk] [get_bd_pins tx_pkt_buf/s_axis_aclk]
  connect_bd_net -net axi_10g_ethernet_0_tx_disable [get_bd_pins tengig_tx_disable] [get_bd_pins axi_10g_ethernet_0/tx_disable]
  connect_bd_net -net axi_10g_ethernet_0_txn [get_bd_pins tengig_txn] [get_bd_pins axi_10g_ethernet_0/txn]
  connect_bd_net -net axi_10g_ethernet_0_txp [get_bd_pins tengig_txp] [get_bd_pins axi_10g_ethernet_0/txp]
  connect_bd_net -net pcs_pma_config_dout [get_bd_pins axi_10g_ethernet_0/pcs_pma_configuration_vector] [get_bd_pins pcs_pma_config/dout]
  connect_bd_net -net refclk_n_1 [get_bd_pins tengig_refclk_n] [get_bd_pins axi_10g_ethernet_0/refclk_n]
  connect_bd_net -net refclk_p_1 [get_bd_pins tengig_refclk_p] [get_bd_pins axi_10g_ethernet_0/refclk_p]
  connect_bd_net -net rst_inverter_Res [get_bd_pins axi_10g_ethernet_0/reset] [get_bd_pins rst_inverter/Res]
  connect_bd_net -net rx_config_dout [get_bd_pins axi_10g_ethernet_0/mac_rx_configuration_vector] [get_bd_pins rx_config/dout]
  connect_bd_net -net rxn_1 [get_bd_pins tengig_rxn] [get_bd_pins axi_10g_ethernet_0/rxn]
  connect_bd_net -net rxp_1 [get_bd_pins tengig_rxp] [get_bd_pins axi_10g_ethernet_0/rxp]
  connect_bd_net -net si5324_rst_driver_dout [get_bd_pins si5324_reset] [get_bd_pins si5324_rst_driver/dout]
  connect_bd_net -net tengig_signal_detect_1 [get_bd_pins tengig_signal_detect] [get_bd_pins axi_10g_ethernet_0/signal_detect]
  connect_bd_net -net tengig_tx_fault_1 [get_bd_pins tengig_tx_fault] [get_bd_pins axi_10g_ethernet_0/tx_fault]
  connect_bd_net -net tx_config_dout [get_bd_pins axi_10g_ethernet_0/mac_tx_configuration_vector] [get_bd_pins tx_config/dout]
}