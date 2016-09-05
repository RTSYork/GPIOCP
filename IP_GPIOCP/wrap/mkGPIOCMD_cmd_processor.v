//
// Generated by Bluespec Compiler, version 2012.01.A (build 26572, 2012-01-17)
//
// On Tue Jun 28 13:54:58 BST 2016
//
// Method conflict info:
// Method: bluetile_client_request_get
// Conflict-free: bluetile_client_response_put,
// 	       bluetile_client_hw_man_request_get,
// 	       bluetile_client_hw_man_response_put,
// 	       pin_gpio,
// 	       pin_gpio_cmd_q,
// 	       pin_gpio_external
// Conflicts: bluetile_client_request_get
//
// Method: bluetile_client_response_put
// Conflict-free: bluetile_client_request_get,
// 	       bluetile_client_hw_man_request_get,
// 	       bluetile_client_hw_man_response_put,
// 	       pin_gpio,
// 	       pin_gpio_cmd_q,
// 	       pin_gpio_external
// Conflicts: bluetile_client_response_put
//
// Method: bluetile_client_hw_man_request_get
// Conflict-free: bluetile_client_request_get,
// 	       bluetile_client_response_put,
// 	       bluetile_client_hw_man_response_put,
// 	       pin_gpio,
// 	       pin_gpio_cmd_q,
// 	       pin_gpio_external
// Conflicts: bluetile_client_hw_man_request_get
//
// Method: bluetile_client_hw_man_response_put
// Conflict-free: bluetile_client_request_get,
// 	       bluetile_client_response_put,
// 	       bluetile_client_hw_man_request_get,
// 	       pin_gpio,
// 	       pin_gpio_cmd_q,
// 	       pin_gpio_external
// Conflicts: bluetile_client_hw_man_response_put
//
// Method: pin_gpio
// Conflict-free: bluetile_client_request_get,
// 	       bluetile_client_response_put,
// 	       bluetile_client_hw_man_request_get,
// 	       bluetile_client_hw_man_response_put,
// 	       pin_gpio,
// 	       pin_gpio_cmd_q,
// 	       pin_gpio_external
//
// Method: pin_gpio_cmd_q
// Conflict-free: bluetile_client_request_get,
// 	       bluetile_client_response_put,
// 	       bluetile_client_hw_man_request_get,
// 	       bluetile_client_hw_man_response_put,
// 	       pin_gpio,
// 	       pin_gpio_cmd_q
// Sequenced before (restricted): pin_gpio_external
//
// Method: pin_gpio_external
// Conflict-free: bluetile_client_request_get,
// 	       bluetile_client_response_put,
// 	       bluetile_client_hw_man_request_get,
// 	       bluetile_client_hw_man_response_put,
// 	       pin_gpio
// Sequenced before (restricted): pin_gpio_external
// Sequenced after (restricted): pin_gpio_cmd_q
//
//
// Ports:
// Name                         I/O  size props
// bluetile_client_request_get    O    32 reg
// RDY_bluetile_client_request_get  O     1 reg
// RDY_bluetile_client_response_put  O     1 reg
// bluetile_client_hw_man_request_get  O    32 reg
// RDY_bluetile_client_hw_man_request_get  O     1 reg
// RDY_bluetile_client_hw_man_response_put  O     1 reg
// pin_gpio                       O    32 reg
// RDY_pin_gpio                   O     1 const
// pin_gpio_cmd_q                 O    32 reg
// RDY_pin_gpio_cmd_q             O     1 const
// RDY_pin_gpio_external          O     1 const
// CLK                            I     1 clock
// RST_N                          I     1 reset
// bluetile_client_response_put   I    32 reg
// bluetile_client_hw_man_response_put  I    32 reg
// pin_gpio_external_gpio_external  I    32 reg
// EN_bluetile_client_response_put  I     1
// EN_bluetile_client_hw_man_response_put  I     1
// EN_pin_gpio_external           I     1
// EN_bluetile_client_request_get  I     1
// EN_bluetile_client_hw_man_request_get  I     1
//
// No combinational paths from inputs to outputs
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
`define BSV_ASSIGNMENT_DELAY
`endif

module mkGPIOCMD_cmd_processor(CLK,
			       RST_N,

			       EN_bluetile_client_request_get,
			       bluetile_client_request_get,
			       RDY_bluetile_client_request_get,

			       bluetile_client_response_put,
			       EN_bluetile_client_response_put,
			       RDY_bluetile_client_response_put,

			       EN_bluetile_client_hw_man_request_get,
			       bluetile_client_hw_man_request_get,
			       RDY_bluetile_client_hw_man_request_get,

			       bluetile_client_hw_man_response_put,
			       EN_bluetile_client_hw_man_response_put,
			       RDY_bluetile_client_hw_man_response_put,

			       pin_gpio,
			       RDY_pin_gpio,

			       pin_gpio_cmd_q,
			       RDY_pin_gpio_cmd_q,

			       pin_gpio_external_gpio_external,
			       EN_pin_gpio_external,
			       RDY_pin_gpio_external);
  input  CLK;
  input  RST_N;

  // actionvalue method bluetile_client_request_get
  input  EN_bluetile_client_request_get;
  output [31 : 0] bluetile_client_request_get;
  output RDY_bluetile_client_request_get;

  // action method bluetile_client_response_put
  input  [31 : 0] bluetile_client_response_put;
  input  EN_bluetile_client_response_put;
  output RDY_bluetile_client_response_put;

  // actionvalue method bluetile_client_hw_man_request_get
  input  EN_bluetile_client_hw_man_request_get;
  output [31 : 0] bluetile_client_hw_man_request_get;
  output RDY_bluetile_client_hw_man_request_get;

  // action method bluetile_client_hw_man_response_put
  input  [31 : 0] bluetile_client_hw_man_response_put;
  input  EN_bluetile_client_hw_man_response_put;
  output RDY_bluetile_client_hw_man_response_put;

  // value method pin_gpio
  output [31 : 0] pin_gpio;
  output RDY_pin_gpio;

  // value method pin_gpio_cmd_q
  output [31 : 0] pin_gpio_cmd_q;
  output RDY_pin_gpio_cmd_q;

  // action method pin_gpio_external
  input  [31 : 0] pin_gpio_external_gpio_external;
  input  EN_pin_gpio_external;
  output RDY_pin_gpio_external;

  // signals for module outputs
  wire [31 : 0] bluetile_client_hw_man_request_get,
		bluetile_client_request_get,
		pin_gpio,
		pin_gpio_cmd_q;
  wire RDY_bluetile_client_hw_man_request_get,
       RDY_bluetile_client_hw_man_response_put,
       RDY_bluetile_client_request_get,
       RDY_bluetile_client_response_put,
       RDY_pin_gpio,
       RDY_pin_gpio_cmd_q,
       RDY_pin_gpio_external;

  // inlined wires
  wire fsm_cmd_processor_FSM_start_wire$whas,
       fsm_cmd_processor_FSM_state_set_pw$whas,
       fsm_cmd_q_FSM_start_wire$whas,
       fsm_cmd_q_FSM_state_set_pw$whas;

  // register fsm_cmd_processor_FSM_start_reg
  reg fsm_cmd_processor_FSM_start_reg;
  wire fsm_cmd_processor_FSM_start_reg$D_IN,
       fsm_cmd_processor_FSM_start_reg$EN;

  // register fsm_cmd_processor_FSM_start_reg_1
  reg fsm_cmd_processor_FSM_start_reg_1;
  wire fsm_cmd_processor_FSM_start_reg_1$D_IN,
       fsm_cmd_processor_FSM_start_reg_1$EN;

  // register fsm_cmd_processor_FSM_state_can_overlap
  reg fsm_cmd_processor_FSM_state_can_overlap;
  wire fsm_cmd_processor_FSM_state_can_overlap$D_IN,
       fsm_cmd_processor_FSM_state_can_overlap$EN;

  // register fsm_cmd_processor_FSM_state_fired
  reg fsm_cmd_processor_FSM_state_fired;
  wire fsm_cmd_processor_FSM_state_fired$D_IN,
       fsm_cmd_processor_FSM_state_fired$EN;

  // register fsm_cmd_processor_FSM_state_mkFSMstate
  reg [2 : 0] fsm_cmd_processor_FSM_state_mkFSMstate;
  reg [2 : 0] fsm_cmd_processor_FSM_state_mkFSMstate$D_IN;
  wire fsm_cmd_processor_FSM_state_mkFSMstate$EN;

  // register fsm_cmd_q_FSM_start_reg
  reg fsm_cmd_q_FSM_start_reg;
  wire fsm_cmd_q_FSM_start_reg$D_IN, fsm_cmd_q_FSM_start_reg$EN;

  // register fsm_cmd_q_FSM_start_reg_1
  reg fsm_cmd_q_FSM_start_reg_1;
  wire fsm_cmd_q_FSM_start_reg_1$D_IN, fsm_cmd_q_FSM_start_reg_1$EN;

  // register fsm_cmd_q_FSM_state_can_overlap
  reg fsm_cmd_q_FSM_state_can_overlap;
  wire fsm_cmd_q_FSM_state_can_overlap$D_IN,
       fsm_cmd_q_FSM_state_can_overlap$EN;

  // register fsm_cmd_q_FSM_state_fired
  reg fsm_cmd_q_FSM_state_fired;
  wire fsm_cmd_q_FSM_state_fired$D_IN, fsm_cmd_q_FSM_state_fired$EN;

  // register fsm_cmd_q_FSM_state_mkFSMstate
  reg [2 : 0] fsm_cmd_q_FSM_state_mkFSMstate;
  reg [2 : 0] fsm_cmd_q_FSM_state_mkFSMstate$D_IN;
  wire fsm_cmd_q_FSM_state_mkFSMstate$EN;

  // register gpio_pin_cmd_q
  reg [31 : 0] gpio_pin_cmd_q;
  wire [31 : 0] gpio_pin_cmd_q$D_IN;
  wire gpio_pin_cmd_q$EN;

  // register gpio_pin_external
  reg [31 : 0] gpio_pin_external;
  wire [31 : 0] gpio_pin_external$D_IN;
  wire gpio_pin_external$EN;

  // register header0
  reg [31 : 0] header0;
  wire [31 : 0] header0$D_IN;
  wire header0$EN;

  // register header0_hw_man
  reg [31 : 0] header0_hw_man;
  wire [31 : 0] header0_hw_man$D_IN;
  wire header0_hw_man$EN;

  // register header1
  reg [31 : 0] header1;
  wire [31 : 0] header1$D_IN;
  wire header1$EN;

  // register in_out_reg
  reg [31 : 0] in_out_reg;
  wire [31 : 0] in_out_reg$D_IN;
  wire in_out_reg$EN;

  // register pin_gpio_reg
  reg [31 : 0] pin_gpio_reg;
  wire [31 : 0] pin_gpio_reg$D_IN;
  wire pin_gpio_reg$EN;

  // ports of submodule i_client
  wire [31 : 0] i_client$D_IN, i_client$D_OUT;
  wire i_client$CLR,
       i_client$DEQ,
       i_client$EMPTY_N,
       i_client$ENQ,
       i_client$FULL_N;

  // ports of submodule i_client_hw_man
  wire [31 : 0] i_client_hw_man$D_IN, i_client_hw_man$D_OUT;
  wire i_client_hw_man$CLR,
       i_client_hw_man$DEQ,
       i_client_hw_man$EMPTY_N,
       i_client_hw_man$ENQ,
       i_client_hw_man$FULL_N;

  // ports of submodule o_client
  wire [31 : 0] o_client$D_IN, o_client$D_OUT;
  wire o_client$CLR, o_client$DEQ, o_client$EMPTY_N, o_client$ENQ;

  // ports of submodule o_client_hw_man
  wire [31 : 0] o_client_hw_man$D_IN, o_client_hw_man$D_OUT;
  wire o_client_hw_man$CLR,
       o_client_hw_man$DEQ,
       o_client_hw_man$EMPTY_N,
       o_client_hw_man$ENQ;

  // rule scheduling signals
  wire WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l84c9,
       WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l89c9,
       WILL_FIRE_RL_fsm_cmd_processor_FSM_fsm_start,
       WILL_FIRE_RL_fsm_cmd_processor_FSM_idle_l82c30,
       WILL_FIRE_RL_fsm_cmd_q_FSM_action_l69c17,
       WILL_FIRE_RL_fsm_cmd_q_FSM_action_l75c35,
       WILL_FIRE_RL_fsm_cmd_q_FSM_action_l77c35,
       WILL_FIRE_RL_fsm_cmd_q_FSM_fsm_start,
       WILL_FIRE_RL_fsm_cmd_q_FSM_idle_l67c26,
       WILL_FIRE_RL_fsm_cmd_q_FSM_idle_l67c26_1;

  // inputs to muxes for submodule ports
  wire [31 : 0] MUX_in_out_reg$write_1__VAL_1, MUX_in_out_reg$write_1__VAL_2;
  wire MUX_fsm_cmd_q_FSM_state_mkFSMstate$write_1__SEL_1;

  // remaining internal signals
  wire [31 : 0] IF_in_out_reg_BIT_0_THEN_result307_ELSE_result378__q1,
		header0_gpio_bit__h502,
		result__h2307,
		result__h2378,
		x__h15164,
		x__h15170,
		x__h25199,
		y__h15165,
		y__h15167,
		y__h25246;
  wire [29 : 0] IF_in_out_reg_BIT_29_2_THEN_gpio_pin_external__ETC___d149;
  wire [27 : 0] IF_in_out_reg_BIT_27_0_THEN_gpio_pin_external__ETC___d148;
  wire [25 : 0] IF_in_out_reg_BIT_25_8_THEN_gpio_pin_external__ETC___d147;
  wire [23 : 0] IF_in_out_reg_BIT_23_6_THEN_gpio_pin_external__ETC___d146;
  wire [21 : 0] IF_in_out_reg_BIT_21_4_THEN_gpio_pin_external__ETC___d145;
  wire [19 : 0] IF_in_out_reg_BIT_19_2_THEN_gpio_pin_external__ETC___d144;
  wire [17 : 0] IF_in_out_reg_BIT_17_0_THEN_gpio_pin_external__ETC___d143;
  wire [15 : 0] IF_in_out_reg_BIT_15_8_THEN_gpio_pin_external__ETC___d142;
  wire [13 : 0] IF_in_out_reg_BIT_13_6_THEN_gpio_pin_external__ETC___d141;
  wire [11 : 0] IF_in_out_reg_BIT_11_4_THEN_gpio_pin_external__ETC___d140;
  wire [9 : 0] IF_in_out_reg_BIT_9_2_THEN_gpio_pin_external_B_ETC___d139;
  wire [7 : 0] IF_in_out_reg_BIT_7_00_THEN_gpio_pin_external__ETC___d138;
  wire [5 : 0] IF_in_out_reg_BIT_5_08_THEN_gpio_pin_external__ETC___d137;
  wire [3 : 0] IF_in_out_reg_BIT_3_16_THEN_gpio_pin_external__ETC___d136;
  wire [1 : 0] IF_in_out_reg_BIT_1_24_THEN_gpio_pin_external__ETC___d135;
  wire fsm_cmd_processor_FSM_abort_whas__54_AND_fsm_c_ETC___d209,
       fsm_cmd_q_FSM_abort_whas__15_AND_fsm_cmd_q_FSM_ETC___d249;

  // actionvalue method bluetile_client_request_get
  assign bluetile_client_request_get = o_client$D_OUT ;
  assign RDY_bluetile_client_request_get = o_client$EMPTY_N ;

  // action method bluetile_client_response_put
  assign RDY_bluetile_client_response_put = i_client$FULL_N ;

  // actionvalue method bluetile_client_hw_man_request_get
  assign bluetile_client_hw_man_request_get = o_client_hw_man$D_OUT ;
  assign RDY_bluetile_client_hw_man_request_get = o_client_hw_man$EMPTY_N ;

  // action method bluetile_client_hw_man_response_put
  assign RDY_bluetile_client_hw_man_response_put = i_client_hw_man$FULL_N ;

  // value method pin_gpio
  assign pin_gpio = pin_gpio_reg ;
  assign RDY_pin_gpio = 1'd1 ;

  // value method pin_gpio_cmd_q
  assign pin_gpio_cmd_q = gpio_pin_cmd_q ;
  assign RDY_pin_gpio_cmd_q = 1'd1 ;

  // action method pin_gpio_external
  assign RDY_pin_gpio_external = 1'd1 ;

  // submodule i_client
  SizedFIFO #(.p1width(32'd32),
	      .p2depth(32'd50),
	      .p3cntr_width(32'd6),
	      .guarded(32'd1)) i_client(.RST_N(RST_N),
					.CLK(CLK),
					.D_IN(i_client$D_IN),
					.ENQ(i_client$ENQ),
					.DEQ(i_client$DEQ),
					.CLR(i_client$CLR),
					.D_OUT(i_client$D_OUT),
					.FULL_N(i_client$FULL_N),
					.EMPTY_N(i_client$EMPTY_N));

  // submodule i_client_hw_man
  SizedFIFO #(.p1width(32'd32),
	      .p2depth(32'd50),
	      .p3cntr_width(32'd6),
	      .guarded(32'd1)) i_client_hw_man(.RST_N(RST_N),
					       .CLK(CLK),
					       .D_IN(i_client_hw_man$D_IN),
					       .ENQ(i_client_hw_man$ENQ),
					       .DEQ(i_client_hw_man$DEQ),
					       .CLR(i_client_hw_man$CLR),
					       .D_OUT(i_client_hw_man$D_OUT),
					       .FULL_N(i_client_hw_man$FULL_N),
					       .EMPTY_N(i_client_hw_man$EMPTY_N));

  // submodule o_client
  SizedFIFO #(.p1width(32'd32),
	      .p2depth(32'd50),
	      .p3cntr_width(32'd6),
	      .guarded(32'd1)) o_client(.RST_N(RST_N),
					.CLK(CLK),
					.D_IN(o_client$D_IN),
					.ENQ(o_client$ENQ),
					.DEQ(o_client$DEQ),
					.CLR(o_client$CLR),
					.D_OUT(o_client$D_OUT),
					.FULL_N(),
					.EMPTY_N(o_client$EMPTY_N));

  // submodule o_client_hw_man
  SizedFIFO #(.p1width(32'd32),
	      .p2depth(32'd50),
	      .p3cntr_width(32'd6),
	      .guarded(32'd1)) o_client_hw_man(.RST_N(RST_N),
					       .CLK(CLK),
					       .D_IN(o_client_hw_man$D_IN),
					       .ENQ(o_client_hw_man$ENQ),
					       .DEQ(o_client_hw_man$DEQ),
					       .CLR(o_client_hw_man$CLR),
					       .D_OUT(o_client_hw_man$D_OUT),
					       .FULL_N(),
					       .EMPTY_N(o_client_hw_man$EMPTY_N));

  // rule RL_fsm_cmd_processor_FSM_action_l89c9
  assign WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l89c9 =
	     i_client$EMPTY_N &&
	     fsm_cmd_processor_FSM_state_mkFSMstate == 3'd1 ;

  // rule RL_fsm_cmd_processor_FSM_fsm_start
  assign WILL_FIRE_RL_fsm_cmd_processor_FSM_fsm_start =
	     fsm_cmd_processor_FSM_abort_whas__54_AND_fsm_c_ETC___d209 &&
	     fsm_cmd_processor_FSM_start_reg ;

  // rule RL_fsm_cmd_processor_FSM_action_l84c9
  assign WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l84c9 =
	     i_client$EMPTY_N && fsm_cmd_processor_FSM_start_wire$whas &&
	     (fsm_cmd_processor_FSM_state_mkFSMstate == 3'd0 ||
	      fsm_cmd_processor_FSM_state_mkFSMstate == 3'd3) ;

  // rule RL_fsm_cmd_processor_FSM_idle_l82c30
  assign WILL_FIRE_RL_fsm_cmd_processor_FSM_idle_l82c30 =
	     !fsm_cmd_processor_FSM_start_wire$whas &&
	     fsm_cmd_processor_FSM_state_mkFSMstate == 3'd3 ;

  // rule RL_fsm_cmd_q_FSM_action_l75c35
  assign WILL_FIRE_RL_fsm_cmd_q_FSM_action_l75c35 =
	     header0_hw_man[7:0] == 8'd1 &&
	     fsm_cmd_q_FSM_state_mkFSMstate == 3'd1 ;

  // rule RL_fsm_cmd_q_FSM_action_l77c35
  assign WILL_FIRE_RL_fsm_cmd_q_FSM_action_l77c35 =
	     header0_hw_man[7:0] != 8'd1 &&
	     fsm_cmd_q_FSM_state_mkFSMstate == 3'd1 ;

  // rule RL_fsm_cmd_q_FSM_fsm_start
  assign WILL_FIRE_RL_fsm_cmd_q_FSM_fsm_start =
	     fsm_cmd_q_FSM_abort_whas__15_AND_fsm_cmd_q_FSM_ETC___d249 &&
	     (!fsm_cmd_q_FSM_start_reg_1 || fsm_cmd_q_FSM_state_fired) &&
	     fsm_cmd_q_FSM_start_reg ;

  // rule RL_fsm_cmd_q_FSM_action_l69c17
  assign WILL_FIRE_RL_fsm_cmd_q_FSM_action_l69c17 =
	     i_client_hw_man$EMPTY_N && fsm_cmd_q_FSM_start_wire$whas &&
	     fsm_cmd_q_FSM_abort_whas__15_AND_fsm_cmd_q_FSM_ETC___d249 ;

  // rule RL_fsm_cmd_q_FSM_idle_l67c26
  assign WILL_FIRE_RL_fsm_cmd_q_FSM_idle_l67c26 =
	     !fsm_cmd_q_FSM_start_wire$whas &&
	     fsm_cmd_q_FSM_state_mkFSMstate == 3'd2 ;

  // rule RL_fsm_cmd_q_FSM_idle_l67c26_1
  assign WILL_FIRE_RL_fsm_cmd_q_FSM_idle_l67c26_1 =
	     !fsm_cmd_q_FSM_start_wire$whas &&
	     fsm_cmd_q_FSM_state_mkFSMstate == 3'd3 ;

  // inputs to muxes for submodule ports
  assign MUX_fsm_cmd_q_FSM_state_mkFSMstate$write_1__SEL_1 =
	     WILL_FIRE_RL_fsm_cmd_q_FSM_idle_l67c26_1 ||
	     WILL_FIRE_RL_fsm_cmd_q_FSM_idle_l67c26 ;
  assign MUX_in_out_reg$write_1__VAL_1 = in_out_reg | x__h25199 ;
  assign MUX_in_out_reg$write_1__VAL_2 = in_out_reg & y__h25246 ;

  // inlined wires
  assign fsm_cmd_processor_FSM_start_wire$whas =
	     WILL_FIRE_RL_fsm_cmd_processor_FSM_fsm_start ||
	     fsm_cmd_processor_FSM_start_reg_1 &&
	     !fsm_cmd_processor_FSM_state_fired ;
  assign fsm_cmd_q_FSM_start_wire$whas =
	     WILL_FIRE_RL_fsm_cmd_q_FSM_fsm_start ||
	     fsm_cmd_q_FSM_start_reg_1 && !fsm_cmd_q_FSM_state_fired ;
  assign fsm_cmd_processor_FSM_state_set_pw$whas =
	     WILL_FIRE_RL_fsm_cmd_processor_FSM_idle_l82c30 ||
	     fsm_cmd_processor_FSM_state_mkFSMstate == 3'd2 ||
	     WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l89c9 ||
	     WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l84c9 ;
  assign fsm_cmd_q_FSM_state_set_pw$whas =
	     WILL_FIRE_RL_fsm_cmd_q_FSM_idle_l67c26_1 ||
	     WILL_FIRE_RL_fsm_cmd_q_FSM_idle_l67c26 ||
	     WILL_FIRE_RL_fsm_cmd_q_FSM_action_l77c35 ||
	     WILL_FIRE_RL_fsm_cmd_q_FSM_action_l75c35 ||
	     WILL_FIRE_RL_fsm_cmd_q_FSM_action_l69c17 ;

  // register fsm_cmd_processor_FSM_start_reg
  assign fsm_cmd_processor_FSM_start_reg$D_IN =
	     !WILL_FIRE_RL_fsm_cmd_processor_FSM_fsm_start ;
  assign fsm_cmd_processor_FSM_start_reg$EN =
	     WILL_FIRE_RL_fsm_cmd_processor_FSM_fsm_start ||
	     fsm_cmd_processor_FSM_abort_whas__54_AND_fsm_c_ETC___d209 &&
	     !fsm_cmd_processor_FSM_start_reg ;

  // register fsm_cmd_processor_FSM_start_reg_1
  assign fsm_cmd_processor_FSM_start_reg_1$D_IN =
	     fsm_cmd_processor_FSM_start_wire$whas ;
  assign fsm_cmd_processor_FSM_start_reg_1$EN = 1'd1 ;

  // register fsm_cmd_processor_FSM_state_can_overlap
  assign fsm_cmd_processor_FSM_state_can_overlap$D_IN =
	     fsm_cmd_processor_FSM_state_set_pw$whas ||
	     fsm_cmd_processor_FSM_state_can_overlap ;
  assign fsm_cmd_processor_FSM_state_can_overlap$EN = 1'd1 ;

  // register fsm_cmd_processor_FSM_state_fired
  assign fsm_cmd_processor_FSM_state_fired$D_IN =
	     fsm_cmd_processor_FSM_state_set_pw$whas ;
  assign fsm_cmd_processor_FSM_state_fired$EN = 1'd1 ;

  // register fsm_cmd_processor_FSM_state_mkFSMstate
  always@(WILL_FIRE_RL_fsm_cmd_processor_FSM_idle_l82c30 or
	  WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l84c9 or
	  WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l89c9 or
	  fsm_cmd_processor_FSM_state_mkFSMstate)
  begin
    case (1'b1) // synopsys parallel_case
      WILL_FIRE_RL_fsm_cmd_processor_FSM_idle_l82c30:
	  fsm_cmd_processor_FSM_state_mkFSMstate$D_IN = 3'd0;
      WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l84c9:
	  fsm_cmd_processor_FSM_state_mkFSMstate$D_IN = 3'd1;
      WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l89c9:
	  fsm_cmd_processor_FSM_state_mkFSMstate$D_IN = 3'd2;
      fsm_cmd_processor_FSM_state_mkFSMstate == 3'd2:
	  fsm_cmd_processor_FSM_state_mkFSMstate$D_IN = 3'd3;
      default: fsm_cmd_processor_FSM_state_mkFSMstate$D_IN =
		   3'b010 /* unspecified value */ ;
    endcase
  end
  assign fsm_cmd_processor_FSM_state_mkFSMstate$EN =
	     WILL_FIRE_RL_fsm_cmd_processor_FSM_idle_l82c30 ||
	     WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l84c9 ||
	     WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l89c9 ||
	     fsm_cmd_processor_FSM_state_mkFSMstate == 3'd2 ;

  // register fsm_cmd_q_FSM_start_reg
  assign fsm_cmd_q_FSM_start_reg$D_IN =
	     !WILL_FIRE_RL_fsm_cmd_q_FSM_fsm_start ;
  assign fsm_cmd_q_FSM_start_reg$EN =
	     WILL_FIRE_RL_fsm_cmd_q_FSM_fsm_start ||
	     fsm_cmd_q_FSM_abort_whas__15_AND_fsm_cmd_q_FSM_ETC___d249 &&
	     (!fsm_cmd_q_FSM_start_reg_1 || fsm_cmd_q_FSM_state_fired) &&
	     !fsm_cmd_q_FSM_start_reg ;

  // register fsm_cmd_q_FSM_start_reg_1
  assign fsm_cmd_q_FSM_start_reg_1$D_IN = fsm_cmd_q_FSM_start_wire$whas ;
  assign fsm_cmd_q_FSM_start_reg_1$EN = 1'd1 ;

  // register fsm_cmd_q_FSM_state_can_overlap
  assign fsm_cmd_q_FSM_state_can_overlap$D_IN =
	     fsm_cmd_q_FSM_state_set_pw$whas ||
	     fsm_cmd_q_FSM_state_can_overlap ;
  assign fsm_cmd_q_FSM_state_can_overlap$EN = 1'd1 ;

  // register fsm_cmd_q_FSM_state_fired
  assign fsm_cmd_q_FSM_state_fired$D_IN = fsm_cmd_q_FSM_state_set_pw$whas ;
  assign fsm_cmd_q_FSM_state_fired$EN = 1'd1 ;

  // register fsm_cmd_q_FSM_state_mkFSMstate
  always@(MUX_fsm_cmd_q_FSM_state_mkFSMstate$write_1__SEL_1 or
	  WILL_FIRE_RL_fsm_cmd_q_FSM_action_l69c17 or
	  WILL_FIRE_RL_fsm_cmd_q_FSM_action_l75c35 or
	  WILL_FIRE_RL_fsm_cmd_q_FSM_action_l77c35)
  begin
    case (1'b1) // synopsys parallel_case
      MUX_fsm_cmd_q_FSM_state_mkFSMstate$write_1__SEL_1:
	  fsm_cmd_q_FSM_state_mkFSMstate$D_IN = 3'd0;
      WILL_FIRE_RL_fsm_cmd_q_FSM_action_l69c17:
	  fsm_cmd_q_FSM_state_mkFSMstate$D_IN = 3'd1;
      WILL_FIRE_RL_fsm_cmd_q_FSM_action_l75c35:
	  fsm_cmd_q_FSM_state_mkFSMstate$D_IN = 3'd2;
      WILL_FIRE_RL_fsm_cmd_q_FSM_action_l77c35:
	  fsm_cmd_q_FSM_state_mkFSMstate$D_IN = 3'd3;
      default: fsm_cmd_q_FSM_state_mkFSMstate$D_IN =
		   3'b010 /* unspecified value */ ;
    endcase
  end
  assign fsm_cmd_q_FSM_state_mkFSMstate$EN =
	     WILL_FIRE_RL_fsm_cmd_q_FSM_idle_l67c26_1 ||
	     WILL_FIRE_RL_fsm_cmd_q_FSM_idle_l67c26 ||
	     WILL_FIRE_RL_fsm_cmd_q_FSM_action_l69c17 ||
	     WILL_FIRE_RL_fsm_cmd_q_FSM_action_l75c35 ||
	     WILL_FIRE_RL_fsm_cmd_q_FSM_action_l77c35 ;

  // register gpio_pin_cmd_q
  assign gpio_pin_cmd_q$D_IN =
	     { in_out_reg[31] ? gpio_pin_external[31] : pin_gpio_reg[31],
	       in_out_reg[30] ? gpio_pin_external[30] : pin_gpio_reg[30],
	       IF_in_out_reg_BIT_29_2_THEN_gpio_pin_external__ETC___d149 } ;
  assign gpio_pin_cmd_q$EN = 1'd1 ;

  // register gpio_pin_external
  assign gpio_pin_external$D_IN = pin_gpio_external_gpio_external ;
  assign gpio_pin_external$EN = EN_pin_gpio_external ;

  // register header0
  assign header0$D_IN = i_client$D_OUT ;
  assign header0$EN = WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l84c9 ;

  // register header0_hw_man
  assign header0_hw_man$D_IN = i_client_hw_man$D_OUT ;
  assign header0_hw_man$EN = WILL_FIRE_RL_fsm_cmd_q_FSM_action_l69c17 ;

  // register header1
  assign header1$D_IN = i_client$D_OUT ;
  assign header1$EN = WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l89c9 ;

  // register in_out_reg
  assign in_out_reg$D_IN =
	     WILL_FIRE_RL_fsm_cmd_q_FSM_action_l75c35 ?
	       MUX_in_out_reg$write_1__VAL_1 :
	       MUX_in_out_reg$write_1__VAL_2 ;
  assign in_out_reg$EN =
	     WILL_FIRE_RL_fsm_cmd_q_FSM_action_l75c35 ||
	     WILL_FIRE_RL_fsm_cmd_q_FSM_action_l77c35 ;

  // register pin_gpio_reg
  assign pin_gpio_reg$D_IN = x__h15164 | y__h15165 ;
  assign pin_gpio_reg$EN = fsm_cmd_processor_FSM_state_mkFSMstate == 3'd2 ;

  // submodule i_client
  assign i_client$D_IN = bluetile_client_response_put ;
  assign i_client$ENQ = EN_bluetile_client_response_put ;
  assign i_client$DEQ =
	     WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l89c9 ||
	     WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l84c9 ;
  assign i_client$CLR = 1'b0 ;

  // submodule i_client_hw_man
  assign i_client_hw_man$D_IN = bluetile_client_hw_man_response_put ;
  assign i_client_hw_man$ENQ = EN_bluetile_client_hw_man_response_put ;
  assign i_client_hw_man$DEQ = WILL_FIRE_RL_fsm_cmd_q_FSM_action_l69c17 ;
  assign i_client_hw_man$CLR = 1'b0 ;

  // submodule o_client
  assign o_client$D_IN = 32'h0 ;
  assign o_client$ENQ = 1'b0 ;
  assign o_client$DEQ = EN_bluetile_client_request_get ;
  assign o_client$CLR = 1'b0 ;

  // submodule o_client_hw_man
  assign o_client_hw_man$D_IN = 32'h0 ;
  assign o_client_hw_man$ENQ = 1'b0 ;
  assign o_client_hw_man$DEQ = EN_bluetile_client_hw_man_request_get ;
  assign o_client_hw_man$CLR = 1'b0 ;

  // remaining internal signals
  assign IF_in_out_reg_BIT_0_THEN_result307_ELSE_result378__q1 =
	     in_out_reg[0] ? result__h2307 : result__h2378 ;
  assign IF_in_out_reg_BIT_11_4_THEN_gpio_pin_external__ETC___d140 =
	     { in_out_reg[11] ? gpio_pin_external[11] : pin_gpio_reg[11],
	       in_out_reg[10] ? gpio_pin_external[10] : pin_gpio_reg[10],
	       IF_in_out_reg_BIT_9_2_THEN_gpio_pin_external_B_ETC___d139 } ;
  assign IF_in_out_reg_BIT_13_6_THEN_gpio_pin_external__ETC___d141 =
	     { in_out_reg[13] ? gpio_pin_external[13] : pin_gpio_reg[13],
	       in_out_reg[12] ? gpio_pin_external[12] : pin_gpio_reg[12],
	       IF_in_out_reg_BIT_11_4_THEN_gpio_pin_external__ETC___d140 } ;
  assign IF_in_out_reg_BIT_15_8_THEN_gpio_pin_external__ETC___d142 =
	     { in_out_reg[15] ? gpio_pin_external[15] : pin_gpio_reg[15],
	       in_out_reg[14] ? gpio_pin_external[14] : pin_gpio_reg[14],
	       IF_in_out_reg_BIT_13_6_THEN_gpio_pin_external__ETC___d141 } ;
  assign IF_in_out_reg_BIT_17_0_THEN_gpio_pin_external__ETC___d143 =
	     { in_out_reg[17] ? gpio_pin_external[17] : pin_gpio_reg[17],
	       in_out_reg[16] ? gpio_pin_external[16] : pin_gpio_reg[16],
	       IF_in_out_reg_BIT_15_8_THEN_gpio_pin_external__ETC___d142 } ;
  assign IF_in_out_reg_BIT_19_2_THEN_gpio_pin_external__ETC___d144 =
	     { in_out_reg[19] ? gpio_pin_external[19] : pin_gpio_reg[19],
	       in_out_reg[18] ? gpio_pin_external[18] : pin_gpio_reg[18],
	       IF_in_out_reg_BIT_17_0_THEN_gpio_pin_external__ETC___d143 } ;
  assign IF_in_out_reg_BIT_1_24_THEN_gpio_pin_external__ETC___d135 =
	     { in_out_reg[1] ? gpio_pin_external[1] : pin_gpio_reg[1],
	       IF_in_out_reg_BIT_0_THEN_result307_ELSE_result378__q1[0] } ;
  assign IF_in_out_reg_BIT_21_4_THEN_gpio_pin_external__ETC___d145 =
	     { in_out_reg[21] ? gpio_pin_external[21] : pin_gpio_reg[21],
	       in_out_reg[20] ? gpio_pin_external[20] : pin_gpio_reg[20],
	       IF_in_out_reg_BIT_19_2_THEN_gpio_pin_external__ETC___d144 } ;
  assign IF_in_out_reg_BIT_23_6_THEN_gpio_pin_external__ETC___d146 =
	     { in_out_reg[23] ? gpio_pin_external[23] : pin_gpio_reg[23],
	       in_out_reg[22] ? gpio_pin_external[22] : pin_gpio_reg[22],
	       IF_in_out_reg_BIT_21_4_THEN_gpio_pin_external__ETC___d145 } ;
  assign IF_in_out_reg_BIT_25_8_THEN_gpio_pin_external__ETC___d147 =
	     { in_out_reg[25] ? gpio_pin_external[25] : pin_gpio_reg[25],
	       in_out_reg[24] ? gpio_pin_external[24] : pin_gpio_reg[24],
	       IF_in_out_reg_BIT_23_6_THEN_gpio_pin_external__ETC___d146 } ;
  assign IF_in_out_reg_BIT_27_0_THEN_gpio_pin_external__ETC___d148 =
	     { in_out_reg[27] ? gpio_pin_external[27] : pin_gpio_reg[27],
	       in_out_reg[26] ? gpio_pin_external[26] : pin_gpio_reg[26],
	       IF_in_out_reg_BIT_25_8_THEN_gpio_pin_external__ETC___d147 } ;
  assign IF_in_out_reg_BIT_29_2_THEN_gpio_pin_external__ETC___d149 =
	     { in_out_reg[29] ? gpio_pin_external[29] : pin_gpio_reg[29],
	       in_out_reg[28] ? gpio_pin_external[28] : pin_gpio_reg[28],
	       IF_in_out_reg_BIT_27_0_THEN_gpio_pin_external__ETC___d148 } ;
  assign IF_in_out_reg_BIT_3_16_THEN_gpio_pin_external__ETC___d136 =
	     { in_out_reg[3] ? gpio_pin_external[3] : pin_gpio_reg[3],
	       in_out_reg[2] ? gpio_pin_external[2] : pin_gpio_reg[2],
	       IF_in_out_reg_BIT_1_24_THEN_gpio_pin_external__ETC___d135 } ;
  assign IF_in_out_reg_BIT_5_08_THEN_gpio_pin_external__ETC___d137 =
	     { in_out_reg[5] ? gpio_pin_external[5] : pin_gpio_reg[5],
	       in_out_reg[4] ? gpio_pin_external[4] : pin_gpio_reg[4],
	       IF_in_out_reg_BIT_3_16_THEN_gpio_pin_external__ETC___d136 } ;
  assign IF_in_out_reg_BIT_7_00_THEN_gpio_pin_external__ETC___d138 =
	     { in_out_reg[7] ? gpio_pin_external[7] : pin_gpio_reg[7],
	       in_out_reg[6] ? gpio_pin_external[6] : pin_gpio_reg[6],
	       IF_in_out_reg_BIT_5_08_THEN_gpio_pin_external__ETC___d137 } ;
  assign IF_in_out_reg_BIT_9_2_THEN_gpio_pin_external_B_ETC___d139 =
	     { in_out_reg[9] ? gpio_pin_external[9] : pin_gpio_reg[9],
	       in_out_reg[8] ? gpio_pin_external[8] : pin_gpio_reg[8],
	       IF_in_out_reg_BIT_7_00_THEN_gpio_pin_external__ETC___d138 } ;
  assign fsm_cmd_processor_FSM_abort_whas__54_AND_fsm_c_ETC___d209 =
	     (fsm_cmd_processor_FSM_state_mkFSMstate == 3'd0 ||
	      fsm_cmd_processor_FSM_state_mkFSMstate == 3'd3) &&
	     (!fsm_cmd_processor_FSM_start_reg_1 ||
	      fsm_cmd_processor_FSM_state_fired) ;
  assign fsm_cmd_q_FSM_abort_whas__15_AND_fsm_cmd_q_FSM_ETC___d249 =
	     fsm_cmd_q_FSM_state_mkFSMstate == 3'd0 ||
	     fsm_cmd_q_FSM_state_mkFSMstate == 3'd2 ||
	     fsm_cmd_q_FSM_state_mkFSMstate == 3'd3 ;
  assign header0_gpio_bit__h502 = { 16'h0, header0[31:16] } ;
  assign result__h2307 = gpio_pin_external[0] ? 32'd1 : 32'd0 ;
  assign result__h2378 = pin_gpio_reg[0] ? 32'd1 : 32'd0 ;
  assign x__h15164 = pin_gpio_reg & y__h15167 ;
  assign x__h15170 = header0_gpio_bit__h502 << header0[15:8] ;
  assign x__h25199 = 32'd1 << header0_hw_man[15:8] ;
  assign y__h15165 = x__h15170 & header1 ;
  assign y__h15167 = ~header1 ;
  assign y__h25246 = ~x__h25199 ;

  // handling of inlined registers

  always@(posedge CLK)
  begin
    if (!RST_N)
      begin
        fsm_cmd_processor_FSM_start_reg <= `BSV_ASSIGNMENT_DELAY 1'd0;
	fsm_cmd_processor_FSM_start_reg_1 <= `BSV_ASSIGNMENT_DELAY 1'd0;
	fsm_cmd_processor_FSM_state_can_overlap <= `BSV_ASSIGNMENT_DELAY 1'd1;
	fsm_cmd_processor_FSM_state_fired <= `BSV_ASSIGNMENT_DELAY 1'd0;
	fsm_cmd_processor_FSM_state_mkFSMstate <= `BSV_ASSIGNMENT_DELAY 3'd0;
	fsm_cmd_q_FSM_start_reg <= `BSV_ASSIGNMENT_DELAY 1'd0;
	fsm_cmd_q_FSM_start_reg_1 <= `BSV_ASSIGNMENT_DELAY 1'd0;
	fsm_cmd_q_FSM_state_can_overlap <= `BSV_ASSIGNMENT_DELAY 1'd1;
	fsm_cmd_q_FSM_state_fired <= `BSV_ASSIGNMENT_DELAY 1'd0;
	fsm_cmd_q_FSM_state_mkFSMstate <= `BSV_ASSIGNMENT_DELAY 3'd0;
	gpio_pin_cmd_q <= `BSV_ASSIGNMENT_DELAY 32'd0;
	gpio_pin_external <= `BSV_ASSIGNMENT_DELAY 32'd0;
	header0 <= `BSV_ASSIGNMENT_DELAY 32'd0;
	header0_hw_man <= `BSV_ASSIGNMENT_DELAY 32'd0;
	header1 <= `BSV_ASSIGNMENT_DELAY 32'd0;
	in_out_reg <= `BSV_ASSIGNMENT_DELAY 32'd0;
	pin_gpio_reg <= `BSV_ASSIGNMENT_DELAY 32'd0;
      end
    else
      begin
        if (fsm_cmd_processor_FSM_start_reg$EN)
	  fsm_cmd_processor_FSM_start_reg <= `BSV_ASSIGNMENT_DELAY
	      fsm_cmd_processor_FSM_start_reg$D_IN;
	if (fsm_cmd_processor_FSM_start_reg_1$EN)
	  fsm_cmd_processor_FSM_start_reg_1 <= `BSV_ASSIGNMENT_DELAY
	      fsm_cmd_processor_FSM_start_reg_1$D_IN;
	if (fsm_cmd_processor_FSM_state_can_overlap$EN)
	  fsm_cmd_processor_FSM_state_can_overlap <= `BSV_ASSIGNMENT_DELAY
	      fsm_cmd_processor_FSM_state_can_overlap$D_IN;
	if (fsm_cmd_processor_FSM_state_fired$EN)
	  fsm_cmd_processor_FSM_state_fired <= `BSV_ASSIGNMENT_DELAY
	      fsm_cmd_processor_FSM_state_fired$D_IN;
	if (fsm_cmd_processor_FSM_state_mkFSMstate$EN)
	  fsm_cmd_processor_FSM_state_mkFSMstate <= `BSV_ASSIGNMENT_DELAY
	      fsm_cmd_processor_FSM_state_mkFSMstate$D_IN;
	if (fsm_cmd_q_FSM_start_reg$EN)
	  fsm_cmd_q_FSM_start_reg <= `BSV_ASSIGNMENT_DELAY
	      fsm_cmd_q_FSM_start_reg$D_IN;
	if (fsm_cmd_q_FSM_start_reg_1$EN)
	  fsm_cmd_q_FSM_start_reg_1 <= `BSV_ASSIGNMENT_DELAY
	      fsm_cmd_q_FSM_start_reg_1$D_IN;
	if (fsm_cmd_q_FSM_state_can_overlap$EN)
	  fsm_cmd_q_FSM_state_can_overlap <= `BSV_ASSIGNMENT_DELAY
	      fsm_cmd_q_FSM_state_can_overlap$D_IN;
	if (fsm_cmd_q_FSM_state_fired$EN)
	  fsm_cmd_q_FSM_state_fired <= `BSV_ASSIGNMENT_DELAY
	      fsm_cmd_q_FSM_state_fired$D_IN;
	if (fsm_cmd_q_FSM_state_mkFSMstate$EN)
	  fsm_cmd_q_FSM_state_mkFSMstate <= `BSV_ASSIGNMENT_DELAY
	      fsm_cmd_q_FSM_state_mkFSMstate$D_IN;
	if (gpio_pin_cmd_q$EN)
	  gpio_pin_cmd_q <= `BSV_ASSIGNMENT_DELAY gpio_pin_cmd_q$D_IN;
	if (gpio_pin_external$EN)
	  gpio_pin_external <= `BSV_ASSIGNMENT_DELAY gpio_pin_external$D_IN;
	if (header0$EN) header0 <= `BSV_ASSIGNMENT_DELAY header0$D_IN;
	if (header0_hw_man$EN)
	  header0_hw_man <= `BSV_ASSIGNMENT_DELAY header0_hw_man$D_IN;
	if (header1$EN) header1 <= `BSV_ASSIGNMENT_DELAY header1$D_IN;
	if (in_out_reg$EN)
	  in_out_reg <= `BSV_ASSIGNMENT_DELAY in_out_reg$D_IN;
	if (pin_gpio_reg$EN)
	  pin_gpio_reg <= `BSV_ASSIGNMENT_DELAY pin_gpio_reg$D_IN;
      end
  end

  // synopsys translate_off
  `ifdef BSV_NO_INITIAL_BLOCKS
  `else // not BSV_NO_INITIAL_BLOCKS
  initial
  begin
    fsm_cmd_processor_FSM_start_reg = 1'h0;
    fsm_cmd_processor_FSM_start_reg_1 = 1'h0;
    fsm_cmd_processor_FSM_state_can_overlap = 1'h0;
    fsm_cmd_processor_FSM_state_fired = 1'h0;
    fsm_cmd_processor_FSM_state_mkFSMstate = 3'h2;
    fsm_cmd_q_FSM_start_reg = 1'h0;
    fsm_cmd_q_FSM_start_reg_1 = 1'h0;
    fsm_cmd_q_FSM_state_can_overlap = 1'h0;
    fsm_cmd_q_FSM_state_fired = 1'h0;
    fsm_cmd_q_FSM_state_mkFSMstate = 3'h2;
    gpio_pin_cmd_q = 32'hAAAAAAAA;
    gpio_pin_external = 32'hAAAAAAAA;
    header0 = 32'hAAAAAAAA;
    header0_hw_man = 32'hAAAAAAAA;
    header1 = 32'hAAAAAAAA;
    in_out_reg = 32'hAAAAAAAA;
    pin_gpio_reg = 32'hAAAAAAAA;
  end
  `endif // BSV_NO_INITIAL_BLOCKS
  // synopsys translate_on

  // handling of system tasks

  // synopsys translate_off
  always@(negedge CLK)
  begin
    #0;
    if (RST_N)
      if (WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l89c9 &&
	  fsm_cmd_processor_FSM_state_mkFSMstate == 3'd2)
	$display("Error: \"..//GPIOCMD_cmd_processor.bsv\", line 89, column 9: (R0001)\n  Mutually exclusive rules (from the ME sets\n  [RL_fsm_cmd_processor_FSM_action_l89c9] and\n  [RL_fsm_cmd_processor_FSM_action_l94c9] ) fired in the same clock cycle.\n");
    if (RST_N)
      if (WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l84c9 &&
	  (WILL_FIRE_RL_fsm_cmd_processor_FSM_action_l89c9 ||
	   fsm_cmd_processor_FSM_state_mkFSMstate == 3'd2))
	$display("Error: \"..//GPIOCMD_cmd_processor.bsv\", line 84, column 9: (R0001)\n  Mutually exclusive rules (from the ME sets\n  [RL_fsm_cmd_processor_FSM_action_l84c9] and\n  [RL_fsm_cmd_processor_FSM_action_l89c9,\n  RL_fsm_cmd_processor_FSM_action_l94c9] ) fired in the same clock cycle.\n");
    if (RST_N)
      if (WILL_FIRE_RL_fsm_cmd_q_FSM_action_l75c35 &&
	  WILL_FIRE_RL_fsm_cmd_q_FSM_action_l77c35)
	$display("Error: \"..//GPIOCMD_cmd_processor.bsv\", line 75, column 35: (R0001)\n  Mutually exclusive rules (from the ME sets [RL_fsm_cmd_q_FSM_action_l75c35]\n  and [RL_fsm_cmd_q_FSM_action_l77c35] ) fired in the same clock cycle.\n");
    if (RST_N)
      if (WILL_FIRE_RL_fsm_cmd_q_FSM_action_l69c17 &&
	  (WILL_FIRE_RL_fsm_cmd_q_FSM_action_l75c35 ||
	   WILL_FIRE_RL_fsm_cmd_q_FSM_action_l77c35))
	$display("Error: \"..//GPIOCMD_cmd_processor.bsv\", line 69, column 17: (R0001)\n  Mutually exclusive rules (from the ME sets [RL_fsm_cmd_q_FSM_action_l69c17]\n  and [RL_fsm_cmd_q_FSM_action_l75c35, RL_fsm_cmd_q_FSM_action_l77c35] ) fired\n  in the same clock cycle.\n");
  end
  // synopsys translate_on
endmodule  // mkGPIOCMD_cmd_processor
