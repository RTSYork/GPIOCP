package GPIOCMD_cmd_processor;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;
import BRAM::*;


interface IfcGPIOCMD_cmd_processor;

	method BlueClient bluetile_client;	// Receive messages from cmdq
	method BlueClient bluetile_client_hw_man;	// Reveive messages from hw_man

    method Bit#(32)	pin_gpio();

    method Bit#(32)	pin_gpio_cmd_q();

    // (* always_ready *)
    // (* always_enabled *)
    method Action 	pin_gpio_external(Bit#(32)	gpio_external);
endinterface


(* synthesize *)
module mkGPIOCMD_cmd_processor (IfcGPIOCMD_cmd_processor);
	FIFO#(BlueBits) 	i_client <- mkSizedFIFO(50);
	FIFO#(BlueBits) 	o_client <- mkSizedFIFO(50);

	FIFO#(BlueBits) 	i_client_hw_man <- mkSizedFIFO(50);
	FIFO#(BlueBits) 	o_client_hw_man <- mkSizedFIFO(50);

	Reg#(Bit#(32))		pin_gpio_reg <- mkReg(0);

	// Bluetiles headers
	Reg#(BlueBits) 		header0 <- mkReg(0);
	Bit#(32)			header0_gpio_bit = {16'h0000, header0[31 : 16]};
	Bit#(8)				header0_start_pin = header0[15 : 8];
	Bit#(8)				header0_length = header0[7 : 0];
	Bit#(32)			value_all_one = 32'hFFFFFFFF;

	Reg#(BlueBits)		header1 <- mkReg(0);

	Reg#(BlueBits)		header0_hw_man <- mkReg(0);

	// Used to divide the PINs are input or output
	Reg#(Bit#(32))		in_out_reg <- mkReg(0);	// '1' presents input
												// '0' presents output
	Reg#(Bit#(32))		gpio_pin_external <- mkReg(0);
	Reg#(Bit#(32))		gpio_pin_cmd_q <- mkReg(0);
	Bit#(32)			gpio_pin_cmd_q_val = 0;

	for (Integer c = 0; c < 32; c = c + 1)
	begin
		if (in_out_reg[c] == 1)
			gpio_pin_cmd_q_val[c] = gpio_pin_external[c];
		else	// in_out_reg[c] == 0
			gpio_pin_cmd_q_val[c] = pin_gpio_reg[c];
	end

	rule pin_gpio_cmd_q_rule;
		gpio_pin_cmd_q <= gpio_pin_cmd_q_val;
	endrule

	Stmt fsm_cmd_q = seq

		action
			header0_hw_man <= i_client_hw_man.first();
			i_client_hw_man.deq();
		endaction

		if (header0_hw_man[7 : 0] == 1)
			in_out_reg[header0_hw_man[15:8]] <= 1;
		else
			in_out_reg[header0_hw_man[15:8]] <= 0;
	endseq;


	//	Get sub-CMD from cmd mem
    Stmt fsm_cmd_processor = seq

    	action
    		header0 <= i_client.first();
    		i_client.deq();
    	endaction

    	action
    		header1 <= i_client.first();
    		i_client.deq();
    	endaction

    	action
    		// pin_gpio_reg <= (pin_gpio_reg & (~(value_all_one << (32 - header0_length) >> (32 - header0_length - header0_start_pin)))) | (header0_gpio_bit << (32 - header0_length) >> (32 - header0_length - header0_start_pin));
    		pin_gpio_reg <= (pin_gpio_reg & (~ header1 )) | ((header0_gpio_bit << header0_start_pin) & header1) ;
    	endaction

    endseq;


    FSM fsm_cmd_processor_FSM <- mkFSM(fsm_cmd_processor);
    FSM fsm_cmd_q_FSM <- mkFSM(fsm_cmd_q);

    rule cmd_processor_FSM_rule;
    	fsm_cmd_processor_FSM.start();
    endrule

    rule fsm_cmd_q_FSM_rule;
    	fsm_cmd_q_FSM.start();
    endrule

	//	Interfaces
	interface BlueClient bluetile_client;
	 	interface response = toPut(i_client);
        interface request = toGet(o_client);
	endinterface

	//	Interfaces
	interface BlueClient bluetile_client_hw_man;
	 	interface response = toPut(i_client_hw_man);
       	interface request = toGet(o_client_hw_man);
	endinterface

	method Bit#(32)	pin_gpio();
		return pin_gpio_reg;
	endmethod

	method Bit#(32)	pin_gpio_cmd_q();
		return gpio_pin_cmd_q;
	endmethod


	method Action pin_gpio_external(Bit#(32)	gpio_external);
		gpio_pin_external <= gpio_external;
    endmethod

endmodule
endpackage
