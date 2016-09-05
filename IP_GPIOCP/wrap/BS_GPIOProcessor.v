module BS_GPIOProcessor(
	  // value method pin_gpio
 	 output [7 : 0] pin_gpio,

  	// action method pin_timer
  	input  [31 : 0] pin_timer_timer_external,

  	// action method pin_gpio_external
  	input  [31 : 0] pin_gpio_external_gpio_external,

	output	[31 : 0] bluetile_client_request_DOUT,
	output		bluetile_client_request_valid,
	input		bluetile_client_request_accept,
	input	[31 : 0] bluetile_client_response_DIN,
	output		bluetile_client_response_canaccept,
	input		bluetile_client_response_commit,
	input		CLK,
	input		RST_N);
mkTop_level inner(
		// value method pin_gpio
 	.pin_gpio(pin_gpio),

  	// action method pin_timer
  	.pin_timer_timer_external(pin_timer_timer_external),

  	// action method pin_gpio_external
  	.pin_gpio_external_gpio_external(pin_gpio_external_gpio_external),
  	
	.EN_bluetile_client_request_get(bluetile_client_request_accept),
	.bluetile_client_request_get(bluetile_client_request_DOUT),
	.RDY_bluetile_client_request_get(bluetile_client_request_valid),
	.bluetile_client_response_put(bluetile_client_response_DIN),
	.EN_bluetile_client_response_put(bluetile_client_response_commit),
	.RDY_bluetile_client_response_put(bluetile_client_response_canaccept),

	.CLK(CLK),
	.RST_N(RST_N)
);

endmodule
