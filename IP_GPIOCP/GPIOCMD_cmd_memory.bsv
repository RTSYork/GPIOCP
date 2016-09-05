package GPIOCMD_cmd_memory;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;
import BRAM::*;

interface IfcGPIOCMD_cmd_memory;
	method BlueClient bluetile_client_SUBCMDCPU;	// Receive new sub-cmd from sub-cmd-processor
	method BlueClient bluetile_client_CMDQ;
	method BlueServer bluetile_server_CMDQ;
endinterface

(* synthesize *)
module mkGPIOCMD_cmd_memory (IfcGPIOCMD_cmd_memory);
	FIFO#(BlueBits) 	i_client_SUBCMDCPU <- mkSizedFIFO(50);
	FIFO#(BlueBits) 	o_client_SUBCMDCPU <- mkSizedFIFO(50);

	FIFO#(BlueBits)		i_client_CMDQ <- mkSizedFIFO(50);
	FIFO#(BlueBits)		o_client_CMDQ <- mkSizedFIFO(50);
	
	FIFO#(BlueBits)		i_server_CMDQ <- mkSizedFIFO(50);
    FIFO#(BlueBits)		o_server_CMDQ <- mkSizedFIFO(50);

	Reg#(BlueBits) 		header0_SUBCMDCPU <- mkReg(0);
	Bit#(14)			subcmdcpu_cmd_numb = {6'h0, header0_SUBCMDCPU[15 : 8]};	
	Bit#(14)			subcmdcpu_length = {6'h0, header0_SUBCMDCPU[7 : 0]};
	Bit#(8)				wr_rd = header0_SUBCMDCPU[31 : 24];
	Reg#(Bit#(14))		pointer_cmd_addr_SUBCMDCPU <- mkReg(0);
	Reg#(Bit#(14))		offset_SUBCMDCPU <- mkReg(0);			
	Reg#(BlueBits)		crnt_subcmd_SUBCMDCPU <- mkReg(0);


	Reg#(BlueBits) 		header0_SUBCMDQ <- mkReg(0);
	Bit#(14)			subcmdq_cmdq_numb = {6'h0, header0_SUBCMDQ[31 : 24]};	// Who request the cmd
	Bit#(14)			subcmdq_cmd_numb = {6'h0, header0_SUBCMDQ[15 : 8]};	// THe number of the cmd
	Reg#(Bit#(14))		pointer_cmd_addr_SUBQ <- mkReg(0);
	Reg#(Bit#(14))		offset_SUBQ <- mkReg(0);			
	Reg#(BlueBits)		crnt_subcmd_SUBQ <- mkReg(0);
	Reg#(BlueBits)		subcmdq_length <- mkReg(0);

	// Block RAM for command memory
    BRAM_Configure cfg = defaultValue ;
    cfg.allowWriteResponseBypass = False;
	cfg.memorySize = 16 * 1024;	// 16 KB
	cfg.loadFormat = tagged Hex "command_memory.txt";
	// Addr width, Data width
    BRAM2Port#(UInt#(14), Bit#(32)) cmd_memory <- mkBRAM2Server (cfg);
    // Cmd mmeory adopts a fixed address map;
    // Specifically, each cmd have 64 address space;
    // For example,  0  ->	63				CMD0;
    //				64 	-> 	127				CMD1;
    //				128	->	191 			CMD2;
    //				192	->	255				CMD3;
    //		  	n * 64	->	(n+1) * 64 - 1	CMDn;
    // Fast:    n << 6  ->  (n+1) << 6 - 1  CMDn;


    // command memory update
    Stmt fsm_cmd_mem_update = seq

    	action
    		header0_SUBCMDCPU <= i_client_SUBCMDCPU.first();
    		i_client_SUBCMDCPU.deq();
    	endaction

    	action // Initialise some parameters
	    	pointer_cmd_addr_SUBCMDCPU	<=	subcmdcpu_cmd_numb << 6;	// Initialise address
	    	offset_SUBCMDCPU	<=	1; // Initialise Counter
	    endaction

	    // Put the first element - length of this cmd
	    cmd_memory.portA.request.put(BRAMRequest{write: True, 
    	 										 responseOnWrite:False,
    	 										 address: unpack(pointer_cmd_addr_SUBCMDCPU),
 	 											 datain: {8'h00, wr_rd, 2'h0, subcmdcpu_length} });


	    // Put reset of elements
	    while (offset_SUBCMDCPU <= subcmdcpu_length) seq

	    	action
	    		crnt_subcmd_SUBCMDCPU <= i_client_SUBCMDCPU.first();
	    		i_client_SUBCMDCPU.deq();
	    	endaction

	    	action
	    		cmd_memory.portA.request.put(BRAMRequest{write: True, 
    	 												 responseOnWrite:False,
    	 												 address: unpack(pointer_cmd_addr_SUBCMDCPU + offset_SUBCMDCPU),
 	 													 datain: crnt_subcmd_SUBCMDCPU});
	    		offset_SUBCMDCPU <= offset_SUBCMDCPU + 1;
	    	endaction

	    endseq
    endseq;


    //	command memory output
    Stmt fsm_cmd_mem_output = seq

    	action
    		header0_SUBCMDQ <=	i_client_CMDQ.first();
    		i_client_CMDQ.deq();
    	endaction

    	if (header0_SUBCMDQ[31:24] == 8'hCC) seq  // Clock operation
    		
    		o_server_CMDQ.enq(header0_SUBCMDQ);
    		action
    			o_server_CMDQ.enq(i_client_CMDQ.first());
    			i_client_CMDQ.deq();
    		endaction
    	endseq

    	else seq
	    	action // Initialise some parameters
		    	pointer_cmd_addr_SUBQ	<=	subcmdq_cmd_numb << 6;	// Initialise address
		    	offset_SUBQ	<=	1; // Initialise Counter
		    endaction

		    // Read Length of this CMD
		    cmd_memory.portB.request.put(BRAMRequest{write: False,
	     											 responseOnWrite:False,
	     											 address: unpack(pointer_cmd_addr_SUBQ),
	     											 datain: 0});  
	     	action 
	     		let cmd_cache_fast <- cmd_memory.portB.response.get(); 
	     		subcmdq_length <= pack(cmd_cache_fast);
	     	endaction
		    o_server_CMDQ.enq(header0_SUBCMDQ|subcmdq_length); // Send back to the requester first message
		    													 // NO.CMDQ, FF/EE, --, Length


		   	// Give back the sub cmds to CMDQ
		    while (offset_SUBQ <= subcmdq_length[13:0]) seq

		    	// Read from CMD MEM
		    	cmd_memory.portB.request.put(BRAMRequest{write: False,
	     												 responseOnWrite:False,
	     												 address: unpack(pointer_cmd_addr_SUBQ + offset_SUBQ),
	     												 datain: 0}); 
		    	action 
	     			let cmd_cache_fast <- cmd_memory.portB.response.get(); 
	     			crnt_subcmd_SUBQ <= pack(cmd_cache_fast);
	     		endaction

	     		action
		     		o_server_CMDQ.enq(crnt_subcmd_SUBQ); 
		     		offset_SUBQ <= offset_SUBQ + 1;
		     	endaction
		    endseq
    	endseq
    endseq;


    
    FSM fsm_cmd_mem_update_FSM <- mkFSM(fsm_cmd_mem_update);
    FSM fsm_cmd_mem_output_FSM <- mkFSM(fsm_cmd_mem_output);


    rule cmd_mem_update_FSM_rule;
    	fsm_cmd_mem_update_FSM.start();
    endrule

    rule cmd_mem_output_FSM_rule;
    	fsm_cmd_mem_output_FSM.start();
    endrule


	// Interfaces
	interface BlueClient bluetile_client_SUBCMDCPU;
		interface response = toPut(i_client_SUBCMDCPU);
		interface request = toGet(o_client_SUBCMDCPU);
	endinterface

	interface BlueClient bluetile_client_CMDQ;
		interface response = toPut(i_client_CMDQ);
		interface request = toGet(o_client_CMDQ);
	endinterface

	interface BlueServer bluetile_server_CMDQ;
		interface request = toPut(i_server_CMDQ);
	 	interface response = toGet(o_server_CMDQ);
	endinterface
endmodule

endpackage