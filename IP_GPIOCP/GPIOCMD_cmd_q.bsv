package GPIOCMD_cmd_q;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;
import BRAM::*;

Integer 	numb_cmdq = 9;

interface IfcGPIOCMD_cmd_q;

	method BlueClient bluetile_client_HWMAN;
	method BlueServer bluetile_server_HWMAN;

	method BlueClient bluetile_client_CMDMEM;
	method BlueServer bluetile_server_CMDMEM;

	method BlueServer bluetile_server_CMDPROCESSOR;

	// (* always_ready *)
    // (* always_enabled *)
	method Action 	  pin_timer(Bit#(32)	timer_external);

	// (* always_ready *)
    // (* always_enabled *)
	method Action 	  pin_gpio_external(Bit#(32)	gpio_external);
endinterface


(* synthesize *)
module mkGPIOCMD_cmd_q (IfcGPIOCMD_cmd_q);
	FIFO#(BlueBits) 	i_client_HWMAN <- mkSizedFIFO(50);
	FIFO#(BlueBits) 	o_client_HWMAN <- mkSizedFIFO(50);

	FIFO#(BlueBits)		i_server_HWMAN <- mkSizedFIFO(50);
	FIFO#(BlueBits)		o_server_HWMAN <- mkSizedFIFO(50);

	Reg#(BlueBits) 		header0_HWMAN  <- mkReg(0);
	Bit#(12)			hwman_length = {4'h0, header0_HWMAN[7 : 0]};
	Reg#(Bit#(12))		counter_HWMAN  <- mkReg(0);

	FIFO#(BlueBits) 	i_client_CMDMEM <- mkSizedFIFO(50);
	FIFO#(BlueBits) 	o_client_CMDMEM <- mkSizedFIFO(50);
	Reg#(BlueBits) 		header0_CMDMEM  <- mkReg(0);
	Bit#(12)			cmdmem_length = {4'h0, header0_CMDMEM[7 : 0]};
	Bit#(12)			cmdmem_numb_cmdq = {4'h0, header0_CMDMEM[31 : 24]};
	Reg#(Bit#(12))		counter_CMDMEM  <- mkReg(0);

	FIFO#(BlueBits) 	i_server_CMDMEM <- mkSizedFIFO(50);
	FIFO#(BlueBits) 	o_server_CMDMEM <- mkSizedFIFO(50);

	FIFO#(BlueBits) 	i_server_CMDPROCESSOR <- mkSizedFIFO(50);
	FIFO#(BlueBits) 	o_server_CMDPROCESSOR <- mkSizedFIFO(50);

	// CMD Qs
	FIFO#(BlueBits)		sub_cmd_fifo[numb_cmdq];
	Reg#(BlueBits)		cmdq_crnt_subcmd[numb_cmdq];
	Bit#(3)				cmdq_crnt_subcmd_type[numb_cmdq];
	Bit#(32)			cmdq_crnt_subcmd_data[numb_cmdq];
	Reg#(Bit#(32))		gpio_bit[numb_cmdq];	// Storing the status of gpio banks
	Reg#(Bit#(10))		timer[numb_cmdq];
	FIFOF#(BlueBits)	fifo_SUBCMDCPU[numb_cmdq];	// This FIFO is transmit cmd to cmd cpu
	Reg#(Bit#(16))		cmdq_pin_allocation[numb_cmdq];	//	"15 ~ 8" Start pins & "7 ~ 0" Length
	Bit#(8)				cmdq_pin_allocation_start_pin[numb_cmdq];
	Bit#(8)				cmdq_pin_allocation_length[numb_cmdq];
	Reg#(Bit#(32))		cmdq_pin_allocation_fast[numb_cmdq];
	Reg#(Bit#(1))		cmdq_reached_start_time[numb_cmdq]; // '1' for yes; '0' for no

	// CMD Q_EEs
	FIFO#(BlueBits)		sub_cmd_fifo_EE[numb_cmdq];
	Reg#(BlueBits)		cmdq_crnt_subcmd_EE[numb_cmdq];
	Bit#(3)				cmdq_crnt_subcmd_type_EE[numb_cmdq];
	Bit#(32)			cmdq_crnt_subcmd_data_EE[numb_cmdq];
	Reg#(Bit#(32))		gpio_bit_EE[numb_cmdq];	// Storing the status of gpio banks
	Reg#(Bit#(10))		timer_EE[numb_cmdq];
	Reg#(BlueBits)		s_bit_EE[numb_cmdq];
	Reg#(BlueBits)		effective_times_EE[numb_cmdq];
	Reg#(Bit#(1))		h_or_l_EE[numb_cmdq];
	FIFOF#(BlueBits)	fifo_IO_read[numb_cmdq];
	FIFOF#(BlueBits)	fifo_HWMAN[numb_cmdq];	// This FIFO is transmit gpio pins back to hardware manager
	Reg#(Bit#(32))		serial_read_reg_EE[numb_cmdq];	// This Reg is built to control serial reading
	Reg#(Bit#(32))		counter_serial_read[numb_cmdq];
	Reg#(Bit#(32))		serial_data[numb_cmdq];

	// CMDQ -> CMD processor
	Reg#(Bit#(32))		counter_cmd_processor <- mkReg(0);
	Reg#(Bit#(32))		counter_GPIO_back <- mkReg(0);


	// Gloab Timer 
	Reg#(Bit#(32))		timer_global <- mkReg(0);
	Reg#(BlueBits)		timer_global_destination[numb_cmdq];
	Reg#(Bit#(32))		timer_global_starting_flag <- mkReg(0);


	// GPIO Pins for read
	Reg#(Bit#(32))		gpio_pin <- mkReg(0);


	// Initilization
	for (Integer c = 0; c < numb_cmdq; c = c + 1)
	begin
		sub_cmd_fifo[c] <- mkSizedFIFO(500);
		cmdq_crnt_subcmd[c] <- mkReg(0);
		cmdq_crnt_subcmd_type[c] = cmdq_crnt_subcmd[c][31:29];	// "000" Bit(x) -> '0'
																// "010" Bit(x) -> '1'
																// "100" Bit(y) -> "- - - -"
																// "110" wait
																// "001" Read GPIO
		cmdq_crnt_subcmd_data[c] = {3'b000, cmdq_crnt_subcmd[c][28 : 0]};
		timer[c] <- mkReg(0);
		fifo_SUBCMDCPU[c] <- mkSizedFIFOF(500);
		gpio_bit[c] <- mkReg(0);


		sub_cmd_fifo_EE[c] <- mkSizedFIFO(500);
		cmdq_crnt_subcmd_EE[c] <- mkReg(0);
		cmdq_crnt_subcmd_type_EE[c] = cmdq_crnt_subcmd_EE[c][31:29];	// "000" S Bit
																		// "110" wait
		cmdq_crnt_subcmd_data_EE[c] = {3'b000, cmdq_crnt_subcmd_EE[c][28 : 0]};
		timer_EE[c] <- mkReg(0);
		gpio_bit_EE[c]	<- mkReg(0);
		// gpio_bit_previous_last_EE[c] <- mkReg(0);
		s_bit_EE[c] <- mkReg(32'hFFFFFFFF);	// Make sure the s-bit is not the LSB
		effective_times_EE[c] <- mkReg(0);	// The times of no need waiting
		h_or_l_EE[c] <- mkReg(0);
		fifo_IO_read[c] <- mkSizedFIFOF(50);
		fifo_HWMAN[c] <- mkSizedFIFOF(50);
		serial_read_reg_EE[c] <- mkReg(32'hFFFFFFFF);
		counter_serial_read[c] <- mkReg(0);
		serial_data[c] <- mkReg(0);


		cmdq_pin_allocation[c] <- mkReg(0);
		cmdq_pin_allocation_start_pin[c] = cmdq_pin_allocation[c][15 : 8];
		cmdq_pin_allocation_length[c] = cmdq_pin_allocation[c][7 : 0];
		cmdq_pin_allocation_fast[c] <- mkReg(0);

		cmdq_reached_start_time[c] <- mkReg(0);
		timer_global_destination[c] <- mkReg(0);
	end

	// Read from GPIO
	for (Integer c = 0; c < numb_cmdq; c = c + 1)
	begin
		rule gpio_bit_EE_rule;
			// gpio_bit_EE[c] <= ((gpio_pin << (32 - cmdq_pin_allocation_start_pin[c] - cmdq_pin_allocation_length[c])) >> (32 - cmdq_pin_allocation_length[c]));
			gpio_bit_EE[c] <= (gpio_pin & cmdq_pin_allocation_fast[c]) >> cmdq_pin_allocation_start_pin[c];
		endrule
	end



	// Get CMD from hw manager
    Stmt fsm_cmd_receive = seq

    	action
    		header0_HWMAN <= i_client_HWMAN.first();
    		i_client_HWMAN.deq();
    	endaction

    	if (header0_HWMAN[31 : 24] == 8'hBB) seq
    		serial_read_reg_EE[header0_HWMAN[23:16]] <= {16'h0000, header0_HWMAN[15:0]};
    		i_client_HWMAN.deq();	// Dequeue the reservered one
    	endseq

    	else seq 
	    	if (header0_HWMAN[31 : 24] == 8'hCC) seq  // Set Gloab Timer

	    		
	    		o_server_CMDMEM.enq(header0_HWMAN);
	    		action
		    		o_server_CMDMEM.enq(i_client_HWMAN.first());
	    			i_client_HWMAN.deq();
	    		endaction
	    	endseq

	    	else seq 

		    	if (header0_HWMAN[31 : 24] == 8'hAA) seq 
		    		cmdq_pin_allocation[header0_HWMAN[23:16]] <= header0_HWMAN[15:0];

		    		action
		    			cmdq_pin_allocation_fast[header0_HWMAN[23:16]] <= i_client_HWMAN.first();
		    			i_client_HWMAN.deq();	// Dequeue the reservered one
		    		endaction
		    	endseq 

		    	else seq 

/*
			    	counter_HWMAN <= 0;

			    	while (counter_HWMAN < hwman_length) action
			    		o_server_CMDMEM.enq(i_client_HWMAN.first());	// Give it to CMD_Memory
			    		i_client_HWMAN.deq();
			    		counter_HWMAN <= counter_HWMAN + 1;
			    	endaction
*/
			    	for (counter_HWMAN  <= 0; counter_HWMAN < hwman_length; counter_HWMAN <= counter_HWMAN + 1) action
			    		o_server_CMDMEM.enq(i_client_HWMAN.first());	// Give it to CMD_Memory
			    		i_client_HWMAN.deq();
			    	endaction

			    endseq 
			endseq
		endseq
    endseq;

    //	Get sub-CMD from cmd mem
    Stmt fsm_sub_cmd_receive = seq

    	action
    		header0_CMDMEM <= i_client_CMDMEM.first();
    		i_client_CMDMEM.deq();
    	endaction

    	if (header0_CMDMEM[31:24] == 8'hCC) seq
    		sub_cmd_fifo[header0_CMDMEM[15:8]].enq(header0_CMDMEM);

    		action   			
 	   			sub_cmd_fifo[header0_CMDMEM[15:8]].enq(i_client_CMDMEM.first());
    			i_client_CMDMEM.deq();
    		endaction
    	endseq

    	else seq
	    	counter_CMDMEM <= 0;

	    	if (header0_CMDMEM[23 : 16] == 8'hFF) seq 
	    	/*
				while(counter_CMDMEM < cmdmem_length)action
    	 			sub_cmd_fifo[cmdmem_numb_cmdq].enq(i_client_CMDMEM.first());
    				i_client_CMDMEM.deq();
    				counter_CMDMEM <= counter_CMDMEM + 1;
    			endaction
			*/
				for (counter_CMDMEM <= 0; counter_CMDMEM < cmdmem_length; counter_CMDMEM <= counter_CMDMEM + 1) action
					sub_cmd_fifo[cmdmem_numb_cmdq].enq(i_client_CMDMEM.first());
    				i_client_CMDMEM.deq();
				endaction
    		endseq 

    		else seq // header0_CMDMEM[23 : 16] == 8'hEE 
			/*
    			while(counter_CMDMEM < cmdmem_length)action
    				sub_cmd_fifo_EE[cmdmem_numb_cmdq].enq(i_client_CMDMEM.first());
    				i_client_CMDMEM.deq();
    				counter_CMDMEM <= counter_CMDMEM + 1;
    			endaction
    		*/
    			for (counter_CMDMEM <= 0; counter_CMDMEM < cmdmem_length; counter_CMDMEM <= counter_CMDMEM + 1) action
					sub_cmd_fifo_EE[cmdmem_numb_cmdq].enq(i_client_CMDMEM.first());
    				i_client_CMDMEM.deq();
				endaction
    		endseq 
    	endseq
    endseq;


	function Stmt cmd_q(Integer cmdq);
		return seq

			action
				cmdq_crnt_subcmd[cmdq] <= sub_cmd_fifo[cmdq].first();
				sub_cmd_fifo[cmdq].deq();
				timer[cmdq] <= 0;
			endaction

			if (cmdq_crnt_subcmd[cmdq][31:24] == 8'hCC) seq
				action
					timer_global_destination[cmdq] <= sub_cmd_fifo[cmdq].first() - 11; // Timing..
					sub_cmd_fifo[cmdq].deq;
				endaction
			endseq

			else seq
				while (timer_global <= timer_global_destination[cmdq]) action
					cmdq_reached_start_time[cmdq] <= 0;
				endaction
				
				// Check gloabal timer 
				if ((timer_global > timer_global_destination[cmdq]) && (timer_global > 10)) action
					cmdq_reached_start_time[cmdq] <= 1;
				endaction
				
				if (cmdq_reached_start_time[cmdq] == 1) seq 
/*
					if (cmdq_crnt_subcmd_type[cmdq] == 3'b000) action // Set Bit(x) -> 0
						gpio_bit[cmdq] <= gpio_bit[cmdq] & (~(32'h00000001 << cmdq_crnt_subcmd_data[cmdq]));
					endaction

					if (cmdq_crnt_subcmd_type[cmdq] == 3'b010) action // Set Bit(x) -> 1
						gpio_bit[cmdq] <= gpio_bit[cmdq] | (32'h00000001 << cmdq_crnt_subcmd_data[cmdq]);
					endaction
*/
					if (cmdq_crnt_subcmd_type[cmdq] == 3'b100) action // Set Bit(y) -> " **** "
						gpio_bit[cmdq] <= cmdq_crnt_subcmd_data[cmdq];
					endaction

					if (cmdq_crnt_subcmd_type[cmdq] == 3'b110) seq // Waiting...
						while (timer[cmdq] < cmdq_crnt_subcmd[cmdq][17:8] - 14) action
							timer[cmdq] <= timer[cmdq] + 1;
						endaction
					endseq

					if ((cmdq_crnt_subcmd_type[cmdq] == 3'b000) || (cmdq_crnt_subcmd_type[cmdq] == 3'b010) || (cmdq_crnt_subcmd_type[cmdq] == 3'b100))seq
						fifo_SUBCMDCPU[cmdq].enq({gpio_bit[cmdq][15 : 0],  cmdq_pin_allocation[cmdq]});
						fifo_SUBCMDCPU[cmdq].enq(cmdq_pin_allocation_fast[cmdq]);
					endseq

					else seq // Bug this is
						noAction;
						noAction;
						noAction;
						noAction;
						noAction;
						noAction;
					endseq
				endseq
			endseq
		endseq;
	endfunction	


	function Stmt cmd_q_EE(Integer cmdq);
		return seq

			action
				cmdq_crnt_subcmd_EE[cmdq] <= sub_cmd_fifo_EE[cmdq].first();
				sub_cmd_fifo_EE[cmdq].deq();
			endaction

			if (cmdq_crnt_subcmd_type_EE[cmdq] == 3'b100) action // Set S Bit && Effective times
				s_bit_EE[cmdq] <= {24'h000000, cmdq_crnt_subcmd_data_EE[cmdq][7 : 0]};
				effective_times_EE[cmdq] <= {24'h000000, cmdq_crnt_subcmd_data_EE[cmdq][15 : 8]};
				h_or_l_EE[cmdq] <= cmdq_crnt_subcmd_data_EE[cmdq][16];
			endaction
			
			
			// while ((gpio_bit_EE[cmdq] << (31 - s_bit_EE[cmdq]) >> 31) == (gpio_bit_previous_last_EE[cmdq] << (31 - s_bit_EE[cmdq]) >> 31)) action  // Double Check
																		// Double Check
																		// Double Check
			// while ((gpio_bit_EE[cmdq] << (31 - s_bit_EE[cmdq]) >> 31) != {31'h0, h_or_l_EE[cmdq]}) action
			while((gpio_bit_EE[cmdq][s_bit_EE[cmdq]] != h_or_l_EE[cmdq])) action
			 	// timer_EE[cmdq] <= 0;
			 	noAction;
			endaction

			// Now sensitive
			while (effective_times_EE[cmdq] > 0) seq

				action
					effective_times_EE[cmdq] <= effective_times_EE[cmdq] - 1;
					cmdq_crnt_subcmd_EE[cmdq] <= sub_cmd_fifo_EE[cmdq].first();
					sub_cmd_fifo_EE[cmdq].deq();
					timer_EE[cmdq] <= 0;
				endaction

				if (cmdq_crnt_subcmd_type_EE[cmdq] == 3'b010) action // Read pins
					fifo_IO_read[cmdq].enq(gpio_bit_EE[cmdq]);

				endaction

				if (cmdq_crnt_subcmd_type_EE[cmdq] == 3'b110) seq // wait
					while (timer_EE[cmdq] < cmdq_crnt_subcmd_EE[cmdq][17:8] - 7) action // Need Check
						timer_EE[cmdq] <= timer_EE[cmdq] + 1;
					endaction
				endseq
			endseq

			noAction;
			noAction;
			noAction;
			// Initilize s_bit
			s_bit_EE[cmdq] <= 32'hFFFFFFFF;
		endseq;
	endfunction




	function Stmt cmd_q_EE_serial_data_receiving(Integer cmdq);
		return seq
			while (fifo_IO_read[cmdq].notEmpty == False) action
				noAction;
			endaction
	
			if (serial_read_reg_EE[cmdq] == 32'h0000FFFF) action
				fifo_HWMAN[cmdq].enq(fifo_IO_read[cmdq].first());
				fifo_IO_read[cmdq].deq();
			endaction

			else seq
				action
					serial_data[cmdq] <= serial_data[cmdq] | ((fifo_IO_read[cmdq].first() << (31 - serial_read_reg_EE[cmdq][15:8])) >> 31);
					fifo_IO_read[cmdq].deq();
					counter_serial_read[cmdq] <= counter_serial_read[cmdq] + 1;
				endaction

				if (counter_serial_read[cmdq] == {24'h0, serial_read_reg_EE[cmdq][7 : 0]}) action
					fifo_HWMAN[cmdq].enq(serial_data[cmdq]);
					serial_data[cmdq] <= 0;
					counter_serial_read[cmdq] <= 0;
				endaction

				else action
					serial_data[cmdq] <= serial_data[cmdq] << 1;
				endaction
			endseq
		endseq;
	endfunction


	Stmt fsm_cmd_q_0 =
	seq
		cmd_q(0);
	endseq;

	Stmt fsm_cmd_q_1 =
	seq
		cmd_q(1);
	endseq;

	Stmt fsm_cmd_q_2 =
	seq
		cmd_q(2);
	endseq;

	Stmt fsm_cmd_q_3 =
	seq
		cmd_q(3);
	endseq;

	Stmt fsm_cmd_q_4 =
	seq
		cmd_q(4);
	endseq;

	Stmt fsm_cmd_q_5 =
	seq
		cmd_q(5);
	endseq;

	Stmt fsm_cmd_q_6 =
	seq
		cmd_q(6);
	endseq;

	Stmt fsm_cmd_q_7 =
	seq
		cmd_q(7);
	endseq;

	Stmt fsm_cmd_q_8 =
	seq
		cmd_q(8);
	endseq;



	Stmt fsm_cmd_q_EE_0 =
	seq
		cmd_q_EE(0);
	endseq;

	Stmt fsm_cmd_q_EE_1 =
	seq
		cmd_q_EE(1);
	endseq;

	Stmt fsm_cmd_q_EE_2 =
	seq
		cmd_q_EE(2);
	endseq;

	Stmt fsm_cmd_q_EE_3 =
	seq
		cmd_q_EE(3);
	endseq;

	Stmt fsm_cmd_q_EE_4 =
	seq
		cmd_q_EE(4);
	endseq;

	Stmt fsm_cmd_q_EE_5 =
	seq
		cmd_q_EE(5);
	endseq;

	Stmt fsm_cmd_q_EE_6 =
	seq
		cmd_q_EE(6);
	endseq;

	Stmt fsm_cmd_q_EE_7 =
	seq
		cmd_q_EE(7);
	endseq;

	Stmt fsm_cmd_q_EE_8 =
	seq
		cmd_q_EE(8);
	endseq;



	Stmt fsm_cmd_q_EE_serial_data_receiving_0 =
	seq
		cmd_q_EE_serial_data_receiving(0);
	endseq;

	Stmt fsm_cmd_q_EE_serial_data_receiving_1 =
	seq
		cmd_q_EE_serial_data_receiving(1);
	endseq;

	Stmt fsm_cmd_q_EE_serial_data_receiving_2 =
	seq
		cmd_q_EE_serial_data_receiving(2);
	endseq;

	Stmt fsm_cmd_q_EE_serial_data_receiving_3 =
	seq
		cmd_q_EE_serial_data_receiving(3);
	endseq;

	Stmt fsm_cmd_q_EE_serial_data_receiving_4 =
	seq
		cmd_q_EE_serial_data_receiving(4);
	endseq;

	Stmt fsm_cmd_q_EE_serial_data_receiving_5 =
	seq
		cmd_q_EE_serial_data_receiving(5);
	endseq;

	Stmt fsm_cmd_q_EE_serial_data_receiving_6 =
	seq
		cmd_q_EE_serial_data_receiving(6);
	endseq;

	Stmt fsm_cmd_q_EE_serial_data_receiving_7 =
	seq
		cmd_q_EE_serial_data_receiving(7);
	endseq;

	Stmt fsm_cmd_q_EE_serial_data_receiving_8 =
	seq
		cmd_q_EE_serial_data_receiving(8);
	endseq;


	rule counter_cmd_processor_rule;

		if ( counter_cmd_processor >= pack(fromInteger(numb_cmdq - 1))) action 
			counter_cmd_processor <= 0;
		endaction

		else action
			counter_cmd_processor <= counter_cmd_processor + 1;
		endaction		
	endrule

	rule cmd_processor_rule(fifo_SUBCMDCPU[counter_cmd_processor].notEmpty == True);
		o_server_CMDPROCESSOR.enq(fifo_SUBCMDCPU[counter_cmd_processor].first());
		fifo_SUBCMDCPU[counter_cmd_processor].deq();
	endrule


	Stmt fsm_GPIO_back = seq

		// Check fifo_HWMAN...
		if (fifo_HWMAN[counter_GPIO_back].notEmpty == True) seq
			o_server_HWMAN.enq({counter_GPIO_back[7:0], fifo_HWMAN[counter_GPIO_back].first()[23:0]});
			fifo_HWMAN[counter_GPIO_back].deq();
		endseq 

		else seq
			noAction;
		endseq


		if ( counter_GPIO_back == pack(fromInteger(numb_cmdq - 1)) ) seq 
			counter_GPIO_back <= 0;
		endseq 
		else seq  
			counter_GPIO_back <= counter_GPIO_back + 1;
		endseq
		noAction;
	endseq;
	
    FSM fsm_cmd_receive_FSM <- mkFSM(fsm_cmd_receive);
    FSM fsm_sub_cmd_receive_FSM <- mkFSM(fsm_sub_cmd_receive);
    FSM fsm_cmd_q_0_FSM <- mkFSM(fsm_cmd_q_0);
    FSM fsm_cmd_q_1_FSM <- mkFSM(fsm_cmd_q_1);
    FSM fsm_cmd_q_2_FSM <- mkFSM(fsm_cmd_q_2);
    FSM fsm_cmd_q_3_FSM <- mkFSM(fsm_cmd_q_3);
    FSM fsm_cmd_q_4_FSM <- mkFSM(fsm_cmd_q_4);
    FSM fsm_cmd_q_5_FSM <- mkFSM(fsm_cmd_q_5);
    FSM fsm_cmd_q_6_FSM <- mkFSM(fsm_cmd_q_6);
    FSM fsm_cmd_q_7_FSM <- mkFSM(fsm_cmd_q_7);
    FSM fsm_cmd_q_8_FSM <- mkFSM(fsm_cmd_q_8);



    FSM fsm_cmd_q_EE_0_FSM <- mkFSM(fsm_cmd_q_EE_0);
    FSM fsm_cmd_q_EE_1_FSM <- mkFSM(fsm_cmd_q_EE_1);
    FSM fsm_cmd_q_EE_2_FSM <- mkFSM(fsm_cmd_q_EE_2);
    FSM fsm_cmd_q_EE_3_FSM <- mkFSM(fsm_cmd_q_EE_3);
    FSM fsm_cmd_q_EE_4_FSM <- mkFSM(fsm_cmd_q_EE_4);
    FSM fsm_cmd_q_EE_5_FSM <- mkFSM(fsm_cmd_q_EE_5);
    FSM fsm_cmd_q_EE_6_FSM <- mkFSM(fsm_cmd_q_EE_6);
    FSM fsm_cmd_q_EE_7_FSM <- mkFSM(fsm_cmd_q_EE_7);
    FSM fsm_cmd_q_EE_8_FSM <- mkFSM(fsm_cmd_q_EE_8);


    FSM fsm_cmd_q_EE_serial_data_receiving_0_FSM <- mkFSM(fsm_cmd_q_EE_serial_data_receiving_0);
    FSM fsm_cmd_q_EE_serial_data_receiving_1_FSM <- mkFSM(fsm_cmd_q_EE_serial_data_receiving_1);
    FSM fsm_cmd_q_EE_serial_data_receiving_2_FSM <- mkFSM(fsm_cmd_q_EE_serial_data_receiving_2);
    FSM fsm_cmd_q_EE_serial_data_receiving_3_FSM <- mkFSM(fsm_cmd_q_EE_serial_data_receiving_3);
    FSM fsm_cmd_q_EE_serial_data_receiving_4_FSM <- mkFSM(fsm_cmd_q_EE_serial_data_receiving_4);
    FSM fsm_cmd_q_EE_serial_data_receiving_5_FSM <- mkFSM(fsm_cmd_q_EE_serial_data_receiving_5);
    FSM fsm_cmd_q_EE_serial_data_receiving_6_FSM <- mkFSM(fsm_cmd_q_EE_serial_data_receiving_6);
    FSM fsm_cmd_q_EE_serial_data_receiving_7_FSM <- mkFSM(fsm_cmd_q_EE_serial_data_receiving_7);
    FSM fsm_cmd_q_EE_serial_data_receiving_8_FSM <- mkFSM(fsm_cmd_q_EE_serial_data_receiving_8);


    FSM fsm_GPIO_back_FSM <- mkFSM(fsm_GPIO_back);


    rule cmd_receive_FSM_rule;
    	fsm_cmd_receive_FSM.start();
    endrule

    rule sub_cmd_receive_FSM_rule;
    	fsm_sub_cmd_receive_FSM.start();
    endrule

    rule cmd_q_0_FSM_rule;
    	fsm_cmd_q_0_FSM.start();
    endrule

    rule cmd_q_1_FSM_rule;
    	fsm_cmd_q_1_FSM.start();
    endrule

    rule cmd_q_2_FSM_rule;
    	fsm_cmd_q_2_FSM.start();
    endrule

    rule cmd_q_3_FSM_rule;
    	fsm_cmd_q_3_FSM.start();
    endrule

    rule cmd_q_4_FSM_rule;
    	fsm_cmd_q_4_FSM.start();
    endrule

    rule cmd_q_5_FSM_rule;
    	fsm_cmd_q_5_FSM.start();
    endrule

    rule cmd_q_6_FSM_rule;
    	fsm_cmd_q_6_FSM.start();
    endrule

    rule cmd_q_7_FSM_rule;
    	fsm_cmd_q_7_FSM.start();
    endrule

    rule cmd_q_8_FSM_rule;
    	fsm_cmd_q_8_FSM.start();
    endrule



    rule cmd_q_EE_0_FSM_rule;
    	fsm_cmd_q_EE_0_FSM.start();
    endrule

    rule cmd_q_EE_1_FSM_rule;
    	fsm_cmd_q_EE_1_FSM.start();
    endrule

    rule cmd_q_EE_2_FSM_rule;
    	fsm_cmd_q_EE_2_FSM.start();
    endrule

    rule cmd_q_EE_3_FSM_rule;
    	fsm_cmd_q_EE_3_FSM.start();
    endrule

    rule cmd_q_EE_4_FSM_rule;
    	fsm_cmd_q_EE_4_FSM.start();
    endrule

    rule cmd_q_EE_5_FSM_rule;
    	fsm_cmd_q_EE_5_FSM.start();
    endrule

    rule cmd_q_EE_6_FSM_rule;
    	fsm_cmd_q_EE_6_FSM.start();
    endrule

    rule cmd_q_EE_7_FSM_rule;
    	fsm_cmd_q_EE_7_FSM.start();
    endrule

    rule cmd_q_EE_8_FSM_rule;
    	fsm_cmd_q_EE_8_FSM.start();
    endrule

    rule cmd_q_EE_serial_data_receiving_0_FSM_rule;
    	fsm_cmd_q_EE_serial_data_receiving_0_FSM.start();
    endrule

    rule cmd_q_EE_serial_data_receiving_1_FSM_rule;
    	fsm_cmd_q_EE_serial_data_receiving_1_FSM.start();
    endrule

    rule cmd_q_EE_serial_data_receiving_2_FSM_rule;
    	fsm_cmd_q_EE_serial_data_receiving_2_FSM.start();
    endrule

    rule cmd_q_EE_serial_data_receiving_3_FSM_rule;
    	fsm_cmd_q_EE_serial_data_receiving_3_FSM.start();
    endrule

    rule cmd_q_EE_serial_data_receiving_4_FSM_rule;
    	fsm_cmd_q_EE_serial_data_receiving_4_FSM.start();
    endrule

    rule cmd_q_EE_serial_data_receiving_5_FSM_rule;
    	fsm_cmd_q_EE_serial_data_receiving_5_FSM.start();
    endrule

    rule cmd_q_EE_serial_data_receiving_6_FSM_rule;
    	fsm_cmd_q_EE_serial_data_receiving_6_FSM.start();
    endrule

    rule cmd_q_EE_serial_data_receiving_7_FSM_rule;
    	fsm_cmd_q_EE_serial_data_receiving_7_FSM.start();
    endrule

    rule cmd_q_EE_serial_data_receiving_8_FSM_rule;
    	fsm_cmd_q_EE_serial_data_receiving_8_FSM.start();
    endrule

    rule fsm_GPIO_back_FSM_rule;
    	fsm_GPIO_back_FSM.start();
    endrule

	// Interfaces
	interface BlueClient bluetile_client_HWMAN;
		interface response = toPut(i_client_HWMAN);
		interface request = toGet(o_client_HWMAN);
	endinterface

	interface BlueServer bluetile_server_HWMAN;
		interface request = toPut(i_server_HWMAN);
	 	interface response = toGet(o_server_HWMAN);
	endinterface

	interface BlueClient bluetile_client_CMDMEM;
		interface response = toPut(i_client_CMDMEM);
		interface request = toGet(o_client_CMDMEM);
	endinterface

	interface BlueServer bluetile_server_CMDMEM;
		interface request = toPut(i_server_CMDMEM);
	 	interface response = toGet(o_server_CMDMEM);
	endinterface

	interface BlueServer bluetile_server_CMDPROCESSOR;
		interface request = toPut(i_server_CMDPROCESSOR);
	 	interface response = toGet(o_server_CMDPROCESSOR);
	endinterface

	method Action pin_timer(Bit#(32)	timer_external);
		timer_global <= timer_external + 1;
    endmethod

    method Action pin_gpio_external(Bit#(32)	gpio_external);
		gpio_pin <= gpio_external;
    endmethod
endmodule

endpackage
