// A simple mutex component which sits on Bluetiles. It is intended to be used to implement
// mutual exclusion in programs in a way which doesn't require cache flushing etc.

// The interface is simple. Send `BT_MUX_LOCK to lock a mutex, and `BT_MUX_UNLOCK to unlock.
// The owner of a mutex (as X/Y coords) can be queried using `BT_MUX_QUERY. All commands expect
// a second word which is the mutex to operate on.
// LOCK/UNLOCK return a 1/0 status on success/fail. QUERY returns a cpu_id in the lower 16 bits
// of the data word.
package BluetilesMutex;

export IfcBluetilesMutex(..);
export mkBluetilesMutex;

import MutexManager::*;
import Bluetiles::*;
import GetPut::*;
import ClientServer::*;
import FIFO::*;
import StmtFSM::*;

`define BT_MUX_LOCK 'hEF
`define BT_MUX_UNLOCK 'hEE
`define BT_MUX_QUERY 'hED

 typedef Tuple2#(LocationX, LocationY) CPU_ID;

interface IfcBluetilesMutex;
    interface BlueClient bluetile;
endinterface

(* synthesize *)
module mkBluetilesMutex(IfcBluetilesMutex)
    provisos (NumAlias#(8, nMux),
              Log#(nMux, nMuxBits),
	      Alias#(Bit#(nMuxBits), mutex_id),
	      Add#(__a, nMuxBits, 32));
    IfcMutexManager#(mutex_id, CPU_ID) mutex <- mkMutexManager();
    
    FIFO#(BlueBits) from_net <- mkFIFO();
    FIFO#(BlueBits) to_net <- mkFIFO();
    
    Reg#(BT_Header_0) rx_h0 <- mkReg(unpack(0));
    Reg#(BT_Header_1) rx_h1 <- mkReg(unpack(0));
    Reg#(BlueBits) reply <- mkReg(unpack(0));
    BT_Header rx_h = bt_header_combine(rx_h0, rx_h1);
    
    
    Stmt loop = 
    seq
	while(True) seq
	    action
		rx_h0 <= unpack(from_net.first());
		from_net.deq();
	    endaction
	    
	    action
		rx_h1 <= unpack(from_net.first());
		from_net.deq();
	    endaction
	    
	    action
		BlueBits resp = unpack(0);
		mutex_id idx = truncate(from_net.first());
		from_net.deq();
		
		if(rx_h1.dest_port == `BT_MUX_LOCK) begin
		    Bool done <- mutex.take_mutex(idx, tuple2(rx_h1.src_x, rx_h1.src_y));
		    if(done)
			resp = 1;
		    else
			resp = 0;
		end
		else if(rx_h1.dest_port == `BT_MUX_UNLOCK) begin
		    Bool status <- mutex.release_mutex(idx, tuple2(rx_h1.src_x, rx_h1.src_y));
		    if(status)
			resp = 1;
		    else
			resp = 0;
		end
		else if(rx_h1.dest_port == `BT_MUX_QUERY) begin
		    CPU_ID val = case (mutex.get_mutex_owner(idx)) matches
				     tagged Invalid : return tuple2(~0, ~0);
				     tagged Valid .v : return v;
				 endcase;
		    
		    
		    resp[15:8] = tpl_1(val);
		    resp[7:0] = tpl_2(val);
		end
		
		reply <= resp;
	    endaction
	    
	    // Re-queue the response
	    action
		BT_Header resp = bt_make_reply(rx_h, 1);
		to_net.enq(pack(resp.h0));
	    endaction
	    
	    action
		BT_Header resp = bt_make_reply(rx_h, 1);
		to_net.enq(pack(resp.h1));
	    endaction
	    
	    action
		to_net.enq(reply);
	    endaction
	endseq
    endseq;

    mkAutoFSM(loop);
    
    interface BlueClient bluetile;
	interface Get request = toGet(to_net);
	interface Put response = toPut(from_net);
    endinterface
endmodule

endpackage