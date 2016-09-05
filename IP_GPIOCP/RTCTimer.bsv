package RTCTimer;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;
import BRAM::*;

interface IfcRTCTimer;

	method Bit#(24)	pin_timer();
	method Bit#(32)	pin_timer2();
endinterface

(* synthesize *)
module mkRTCTimer (IfcRTCTimer);
	Reg#(Bit#(32))  timer_reg <- mkReg(0);

	rule timer_rule;
		timer_reg <= timer_reg + 1;
	endrule

	method Bit#(24)	pin_timer();
		return timer_reg[23:0] + 24'h2B2B2B;
	endmethod

	method Bit#(32)	pin_timer2();
		return timer_reg;
	endmethod
endmodule

endpackage