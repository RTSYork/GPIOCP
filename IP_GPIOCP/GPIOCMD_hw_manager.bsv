package GPIOCMD_hw_manager;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;
import BRAM::*;

Integer 	numb_cmdq = 9;

interface IfcGPIOCMD_hw_manager;
	method BlueClient bluetile_client;	// Receive messages from routers
	method BlueServer bluetile_server_SUBCMDCPU; // Send messages to sub_command_processor
	method BlueServer bluetile_server_CMDQ;	// Send messages to CMD Queues

	method BlueServer bluetile_server_CMDPROCESSOR;

	method BlueClient bluetile_client_CMDQ;	// Receive GPIO reading value from CMDQ
endinterface

(* synthesize *)
module mkGPIOCMD_hw_manager (IfcGPIOCMD_hw_manager);
	FIFO#(BlueBits) 	i_client <- mkSizedFIFO(100);
	FIFO#(BlueBits) 	o_client <- mkSizedFIFO(100);

	FIFO#(BlueBits) 	i_server_SUBCMDCPU <- mkSizedFIFO(50);
	FIFO#(BlueBits) 	o_server_SUBCMDCPU <- mkSizedFIFO(50);

	FIFO#(BlueBits) 	i_server_CMDQ <- mkSizedFIFO(50);
	FIFO#(BlueBits) 	o_server_CMDQ <- mkSizedFIFO(50);

	FIFO#(BlueBits)		i_server_CMDPROCESSOR <- mkSizedFIFO(50);
	FIFO#(BlueBits)		o_server_CMDPROCESSOR <- mkSizedFIFO(50);

	FIFO#(BlueBits) 	i_client_CMDQ <- mkSizedFIFO(50);
	FIFO#(BlueBits) 	o_client_CMDQ <- mkSizedFIFO(50);

	// Bluetiles headers
	Reg#(BlueBits) 		bluetiles_header0 <- mkReg(0);
	Reg#(BlueBits)		bluetiles_header1 <- mkReg(0);
	Reg#(BlueBits)		bluetiles_header2 <- mkReg(0);
	Bit#(8)				type_mesg	=	bluetiles_header2[31 : 24];	// If "FF" creating new CMDs, if "00" using old CMDs
	Bit#(8)				subcmdcpu_length =	bluetiles_header2[7 : 0]; // Only for "FF"
	Bit#(8)				subcmdcpu_cmd_numb = bluetiles_header2[15 : 8];	// Only for "FF"

	Bit#(8)				cmdq_length = bluetiles_header2[23 : 16]; // Only for "00"

	//	Counter Registers
	Reg#(Bit#(8))		counter_FF <- mkReg(0);
	Reg#(Bit#(8))		counter_00 <- mkReg(0);

	Reg#(Bit#(32))		table_cmdq_cpu[numb_cmdq];
	Reg#(Bit#(32))		cmdq_header0 <- mkReg(0);

	// Initilization
	for (Integer c = 0; c < numb_cmdq; c = c + 1)
	begin
		table_cmdq_cpu[c]	<-	mkReg(0);
	end

	// Main FSM
	Stmt fsm_hw_Manager = seq

		action 
			bluetiles_header0 <= i_client.first();
			i_client.deq();
		endaction

		action
			bluetiles_header1 <= i_client.first();
			i_client.deq();
		endaction

		action 
			bluetiles_header2 <= i_client.first();
			i_client.deq();
		endaction

		if ((type_mesg == 8'hDD)) seq 	// This one to cmd_u directly
			o_server_CMDPROCESSOR.enq(bluetiles_header2);
		endseq

		else seq

			if ((type_mesg == 8'hAA) || (type_mesg == 8'hCC) || (type_mesg == 8'hBB)) seq 
													// Privilege Instruction, only OS level instructions can use it
												    // Using "8'hAA", which means allocate CMD Q with start pins & subcmdcpu_length	
													// An processor ID check will be added in the future

													// Using "8'hCC", which means set the gloabal timer with bit17 - bit8 time, bit1 - bit 0 timebase
													// Using "8'hBB", which means set the serial read with bit23 - bit16 cmdq, bit15 - bit8 pins, bit7 - bit0 how many bits to read?  
				o_server_CMDQ.enq(bluetiles_header2);

				if (type_mesg == 8'hAA) action
					table_cmdq_cpu[bluetiles_header2[23:16]] <= {bluetiles_header1[31:16], 16'h0};
				endaction

				action
					o_server_CMDQ.enq(i_client.first());
					i_client.deq();
				endaction						
			endseq

			else seq 

				if ((type_mesg == 8'hFF) || (type_mesg == 8'hEE)) seq  // Creating a new CMD(W)

					action
						counter_FF <= subcmdcpu_length;	// Initialise the counter for "FF"
						o_server_SUBCMDCPU.enq({type_mesg, 8'h00, subcmdcpu_cmd_numb, subcmdcpu_length});	// "FF" for function of GPIO write
					endaction 

					while (counter_FF != 0) action
						o_server_SUBCMDCPU.enq(i_client.first());
						i_client.deq();
						counter_FF <= counter_FF - 1;
					endaction
				endseq

				if (type_mesg == 8'h00) seq  // type_mesg = 8'h00 Using old CMDs

					action
						counter_00 <= cmdq_length;	// INitialise the counter for "00"
						o_server_CMDQ.enq({24'h000000, cmdq_length});
					endaction

					while (counter_00 != 0) action
						o_server_CMDQ.enq(i_client.first());
						i_client.deq();
						counter_00 <= counter_00 - 1;
					endaction
				endseq
			endseq
		endseq
	endseq;

	// Main FSM
	Stmt fsm_cmdq = seq

		action
			cmdq_header0 <= i_client_CMDQ.first();
			i_client_CMDQ.deq();
		endaction

		// Send messages back to the CPUs
		o_client.enq(table_cmdq_cpu[cmdq_header0[31:24]]|32'h00000001);

		o_client.enq({8'h00, cmdq_header0[23:0]});	// Read from GPIO
	endseq;


	FSM hw_Manager_FSM <- mkFSM(fsm_hw_Manager);
	FSM cmdq_FSM <- mkFSM(fsm_cmdq);

	rule fsm_hw_Manager_rule;
		hw_Manager_FSM.start();
	endrule

	rule fsm_cmdq_rule;
		cmdq_FSM.start();
	endrule

	//	Interfaces
	interface BlueClient bluetile_client;
	 	interface response = toPut(i_client);
        interface request = toGet(o_client);
	endinterface

	interface BlueServer bluetile_server_SUBCMDCPU;
	 	interface request = toPut(i_server_SUBCMDCPU);
	 	interface response = toGet(o_server_SUBCMDCPU);
	endinterface

	interface BlueServer bluetile_server_CMDQ;
	 	interface request = toPut(i_server_CMDQ);
	 	interface response = toGet(o_server_CMDQ);
	endinterface

	interface BlueServer bluetile_server_CMDPROCESSOR;
		interface request = toPut(i_server_CMDPROCESSOR);
	 	interface response = toGet(o_server_CMDPROCESSOR);
	endinterface

	interface BlueClient bluetile_client_CMDQ;	// Receive GPIO reading value from CMDQ
		interface response = toPut(i_client_CMDQ);
        interface request = toGet(o_client_CMDQ);
    endinterface
endmodule

endpackage
