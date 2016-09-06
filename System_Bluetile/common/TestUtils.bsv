package TestUtils;

export mkMemBounceServer;
export mkFatMemBounceServer;
export mkRandomMemBounceServer;
export mkMemConsumer;
export mkTreeClient;
//export mkMemConsumer2;
export genPacket;
export genDataPacket;
export genHitPacket;
export mkTreeReceiver;

import BluetreeConfig::*;
import Bluetiles::*;
import FIFO::*;
import FIFOF::*;
import ClientServer::*;
import GetPut::*;
import Randomizable::*;
import Assert::*;

// Packet generation stuff
function BluetreeClientPacket genPacket(BluetreeBlockAddress addr);
    BluetreeClientPacket rv = unpack(0);
    rv.address = addr;
    
    return rv;
endfunction

function BluetreeClientPacket genDataPacket(BluetreeBlockAddress addr, BluetreeData data);
    BluetreeClientPacket rv = unpack(0);
    rv.address = addr;
    rv.data = data;
    
    return rv;
endfunction

function BluetreeClientPacket genHitPacket(BluetreeBlockAddress addr);
    BluetreeClientPacket rv = unpack(0);
    rv.address = addr;
    rv.message_type = BT_PREFETCH_HIT;
    
    return rv;
endfunction

function BluetreeClientPacket genPkt(BluetreeBlockAddress addr, BluetreeClientMessageType t);
    BluetreeClientPacket rv = unpack(0);
    rv.address = addr;
    rv.message_type = t;

    return rv;
endfunction

function BluetreeServerPacket genSrvPkt(BluetreeBlockAddress addr, BluetreeMessageType t);
    BluetreeServerPacket rv = unpack(0);
    rv.address = addr;
    rv.message_type = t;

    return rv;
endfunction

// Helper modules. Just dummy receivers and responders really.
module mkTreeReceiver#(String name) (Put#(BluetreeServerPacket));
    method Action put(BluetreeServerPacket pkt);
	$display("%s: Got packet addr %x data %x", name, pkt.address, pkt.data);
    endmethod
endmodule

module mkTreeClient#(String name, FIFO#(BluetreeClientPacket) sourceFifo) (BluetreeClient);
    Reg#(Bool) requestOutstanding <- mkReg(False);
    
    interface Get request;
        method ActionValue#(BluetreeClientPacket) get() if(!requestOutstanding);
            BluetreeClientPacket pkt = sourceFifo.first();

            requestOutstanding <= True;
            sourceFifo.deq();

            $display("%s: Sending packet addr %x data %x", name, pkt.address, pkt.data);

            return pkt;
        endmethod
    endinterface

    interface Put response;
        // Predicate just to shut the compiler up.
        method Action put(BluetreeServerPacket pkt) if(requestOutstanding);
            $display("%s: Got packet addr %x data %x", name, pkt.address, pkt.data);
            requestOutstanding <= False;
        endmethod
    endinterface
endmodule

// Just a membounce without actually bouncing anything.
(* synthesize *)
module mkMemConsumer#(UInt#(8) acceptInterval)(BluetreeServer);
    Reg#(UInt#(8)) acceptCounter <- mkReg(0); // Zero since the TDM counter is also zero-based, and to
                                              // prevent a dynamic initialiser.

    rule decAcceptCounter;
        if(acceptCounter == 0)
            acceptCounter <= acceptInterval;
        else
            acceptCounter <= acceptCounter - 1;
    endrule

    interface Put request;
        method Action put(BluetreeClientPacket pkt) if(acceptCounter == 0);
            let t <- $time();
            BluetreeData inter_t = zeroExtend(t);
            $display("MEMCONSUMER: Putting packet for CPU %d address %x (%d) @ time %d diff %d", pkt.cpu_id, pkt.address, pkt.address, inter_t, (inter_t - pkt.data) / 10);
        endmethod
    endinterface

    interface Get response;
        // This will, of course, raise a warning about a constant False enable.
        method ActionValue#(BluetreeServerPacket) get() if(False);
            return unpack(0);
        endmethod
    endinterface
endmodule

/*module mkMemConsumer2#(UInt#(8) acceptInterval)(Server#(client_pkt, server_pkt))
    provisos(BluetreeRoutable#(client_pkt, client_cpu_id),
	     BluetreeDataContainer#(client_pkt, client_data),
	     Bits#(server_pkt, server_pkt_bits),
	     Bits#(client_cpu_id, client_cpu_id_bits),
	     Bits#(client_data, client_data_bits),
	     Add#(_a_, 4, client_cpu_id_bits)
	     );
    Reg#(UInt#(8)) acceptCounter <- mkReg(0); // Zero since the TDM counter is also zero-based, and to
                                              // prevent a dynamic initialiser.
    Reg#(Bit#(32)) cycle_counter <- mkReg(0);
    
    rule tick;
	cycle_counter <= cycle_counter + 1;
    endrule
    
    rule decAcceptCounter;
        if(acceptCounter == 0)
            acceptCounter <= acceptInterval;
        else
            acceptCounter <= acceptCounter - 1;
    endrule

    interface Put request;
        method Action put(client_pkt pkt) if(acceptCounter == 0);
	    client_data data = getData(pkt);
	    client_cpu_id cpu_id = getCpuId(pkt);
	    
	    Bit#(4) cpu_id_trunc = truncate(pack(cpu_id));
	    
            $display("MEMCONSUMER: Putting packet for CPU %d dispatched @ %d received @ %d", unpack(reverseBits(cpu_id_trunc)), data, cycle_counter);
        endmethod
    endinterface

    interface Get response;
        // This will, of course, raise a warning about a constant False enable.
        method ActionValue#(server_pkt) get() if(False);
            return unpack(0);
        endmethod
    endinterface
endmodule*/

(* synthesize *)
module mkMemBounceServer#(UInt#(8) delay_reset) (BluetreeServer);
    FIFO#(BluetreeServerPacket) bounceFifo <- mkSizedFIFO(2);
    FIFO#(BluetreeClientPacket) incomingFifo <- mkSizedFIFO(2);
    Reg#(BluetreeClientPacket) incoming_packet <- mkReg(unpack(0));
    Reg#(UInt#(8)) delay <- mkReg(0);
    Reg#(BluetreeBurstCounter) burst_max <- mkReg(unpack(0));
    Reg#(BluetreeBurstCounter) burst_done <- mkReg(unpack(0));
    Reg#(Bool) pkt_valid <- mkReg(False);
    
    rule wait_delay (delay > 0);
	   delay <= delay - 1;
    endrule
    
    rule forwardPacket(delay == 0 && !pkt_valid);
    	incoming_packet <= incomingFifo.first();
    	incomingFifo.deq();
    	delay <= delay_reset;
    	pkt_valid <= True;
    endrule
    
    rule handlePacket0(delay == 0 && pkt_valid && burst_max == 0);
    	// Fire back the first response and set up bursts
    	BluetreeClientPacket pkt = incoming_packet;
    	
    	BluetreeServerPacket resp;
    	resp.data = pkt.data;
    	resp.address = pkt.address;
    	resp.task_id = pkt.task_id;
    	resp.cpu_id = pkt.cpu_id;
    	
    	if(pkt.message_type == BT_STANDARD)
    	    resp.message_type = BT_READ;
    	else
    	    resp.message_type = BT_PREFETCH;
    	
    	bounceFifo.enq(resp);
    	
    	if(pkt.size > 0) begin
    	    burst_max <= pkt.size;
    	    burst_done <= 0;
    	end 
    	else begin
    	    pkt_valid <= False;
    	    //	    burst_max <= 0;
    	end
    endrule
    
    rule handleBurst(delay == 0 && pkt_valid && burst_max > 0);
    	BluetreeClientPacket pkt = incoming_packet;
    	
    	BluetreeServerPacket resp;
    	resp.data = pkt.data;
    	resp.address = pkt.address + 1 + zeroExtend(burst_done);
    	resp.task_id = pkt.task_id;
    	resp.cpu_id = pkt.cpu_id;
    	resp.message_type = BT_READ;
    	
    	bounceFifo.enq(resp);
    	
    	if(burst_done == burst_max - 1) begin
    	    pkt_valid <= False;
    	    burst_max <= 0;
    	    burst_done <= 0;
    	end
    	else
    	    burst_done <= burst_done + 1;
    endrule
    
    interface Put request;
    	method Action put(BluetreeClientPacket pkt);
            let t <- $time();
            BluetreeData inter_t = zeroExtend(t);
    	    $display("MEMBOUNCE: Putting packet for CPU %d address %x (%d) @ time %d diff %d", pkt.cpu_id, pkt.address, pkt.address, inter_t, (inter_t - pkt.data) / 10);
	       if(pkt.message_type == BT_STANDARD)
                $display("MEMBOUNCE: Packet is standard");
            else if(pkt.message_type == BT_PREFETCH)
                $display("MEMBOUNCE: Packet is prefetch");
            else if(pkt.message_type == BT_PREFETCH_HIT)
                $display("MEMBOUNCE: ERROR: Packet is prefetch hit chain");
            incomingFifo.enq(pkt);
    	endmethod
    endinterface
    
    interface Get response;
    	method ActionValue#(BluetreeServerPacket) get();
    	    bounceFifo.deq();
    	    
    	    return bounceFifo.first();
    	endmethod
    endinterface
endmodule

(* synthesize *)
module mkFatMemBounceServer#(UInt#(8) delay_reset) (FattreeServer);
    FIFO#(FattreeServerPacket) bounceFifo <- mkSizedFIFO(2);
    FIFO#(FattreeClientPacket) incomingFifo <- mkSizedFIFO(2);
    Reg#(FattreeClientPacket) incoming_packet <- mkReg(unpack(0));
    Reg#(UInt#(8)) delay <- mkReg(0);
    Reg#(BluetreeBurstCounter) burst_max <- mkReg(unpack(0));
    Reg#(BluetreeBurstCounter) burst_done <- mkReg(unpack(0));
    Reg#(Bool) pkt_valid <- mkReg(False);
    
    rule wait_delay (delay > 0);
       delay <= delay - 1;
    endrule
    
    rule forwardPacket(delay == 0 && !pkt_valid);
        incoming_packet <= incomingFifo.first();
        incomingFifo.deq();
        delay <= delay_reset;
        pkt_valid <= True;
    endrule
    
    rule handlePacket0(delay == 0 && pkt_valid && burst_max == 0);
        // Fire back the first response and set up bursts
        FattreeClientPacket pkt = incoming_packet;
        
        FattreeServerPacket resp;
        resp.data = pkt.data;
        resp.address = pkt.address;
        resp.task_id = pkt.task_id;
        resp.cpu_id = pkt.cpu_id;
        resp.steering = pkt.steering;
        
        if(pkt.message_type == BT_STANDARD)
            resp.message_type = BT_READ;
        else
            resp.message_type = BT_PREFETCH;
        
        bounceFifo.enq(resp);
        
        if(pkt.size > 0) begin
            burst_max <= pkt.size;
            burst_done <= 0;
        end 
        else begin
            pkt_valid <= False;
            //      burst_max <= 0;
        end
    endrule
    
    rule handleBurst(delay == 0 && pkt_valid && burst_max > 0);
        FattreeClientPacket pkt = incoming_packet;
        
        FattreeServerPacket resp;
        resp.data = pkt.data;
        resp.address = pkt.address + 1 + zeroExtend(burst_done);
        resp.task_id = pkt.task_id;
        resp.cpu_id = pkt.cpu_id;
        resp.steering = pkt.steering;
        resp.message_type = BT_READ;
        
        bounceFifo.enq(resp);
        
        if(burst_done == burst_max - 1) begin
            pkt_valid <= False;
            burst_max <= 0;
            burst_done <= 0;
        end
        else
            burst_done <= burst_done + 1;
    endrule
    
    interface Put request;
        method Action put(FattreeClientPacket pkt);
            let t <- $time();
            FattreeData inter_t = zeroExtend(t);
            $display("MEMBOUNCE: Putting packet for CPU %d address %x (%d) @ time %d diff %d", pkt.cpu_id, pkt.address, pkt.address, inter_t, (inter_t - pkt.data) / 10);
           if(pkt.message_type == BT_STANDARD)
                $display("MEMBOUNCE: Packet is standard");
            else if(pkt.message_type == BT_PREFETCH)
                $display("MEMBOUNCE: Packet is prefetch");
            else if(pkt.message_type == BT_PREFETCH_HIT)
                $display("MEMBOUNCE: ERROR: Packet is prefetch hit chain");
            incomingFifo.enq(pkt);
        endmethod
    endinterface
    
    interface Get response;
        method ActionValue#(FattreeServerPacket) get();
            bounceFifo.deq();
            
            return bounceFifo.first();
        endmethod
    endinterface
endmodule

//(* synthesize *)
module mkRandomMemBounceServer#(UInt#(8) delay_min, UInt#(8) delay_max) (BluetreeServer);
    FIFO#(BluetreeServerPacket) bounceFifo <- mkSizedFIFO(2);
    FIFO#(BluetreeClientPacket) incomingFifo <- mkSizedFIFO(2);
    Reg#(BluetreeClientPacket) incoming_packet <- mkReg(unpack(0));
    Reg#(UInt#(8)) delay <- mkReg(0);
    Reg#(BluetreeBurstCounter) burst_max <- mkReg(unpack(0));
    Reg#(BluetreeBurstCounter) burst_done <- mkReg(unpack(0));
    Reg#(Bool) pkt_valid <- mkReg(False);
    Reg#(Bool) doInit <- mkReg(True);

    //staticAssert(delay_min == delay_max, "Minimim delay cannot be larger than the maximum delay!");
    Randomize#(UInt#(8)) delayRand <- mkConstrainedRandomizer(delay_min, delay_max);

    rule init(doInit);
        delayRand.cntrl.init();
        doInit <= False;
    endrule

    rule wait_delay (delay > 0);
       delay <= delay - 1;
    endrule
    
    rule forwardPacket(delay == 0 && !pkt_valid);
        incoming_packet <= incomingFifo.first();
        incomingFifo.deq();
        //delay <= delay_reset;
        UInt#(8) randVal <- delayRand.next();
        delay <= randVal;
        pkt_valid <= True;

        $display("Delaying for %d ticks", randVal);
    endrule
    
    rule handlePacket0(delay == 0 && pkt_valid && burst_max == 0);
        // Fire back the first response and set up bursts
        BluetreeClientPacket pkt = incoming_packet;
        
        BluetreeServerPacket resp;
        resp.data = pkt.data;
        resp.address = pkt.address;
        resp.task_id = pkt.task_id;
        resp.cpu_id = pkt.cpu_id;
        
        if(pkt.message_type == BT_STANDARD)
            resp.message_type = BT_READ;
        else
            resp.message_type = BT_PREFETCH;
        
        bounceFifo.enq(resp);
        
        if(pkt.size > 0) begin
            burst_max <= pkt.size;
            burst_done <= 0;
        end 
        else begin
            pkt_valid <= False;
            //      burst_max <= 0;
        end
    endrule
    
    rule handleBurst(delay == 0 && pkt_valid && burst_max > 0);
        BluetreeClientPacket pkt = incoming_packet;
        
        BluetreeServerPacket resp;
        resp.data = pkt.data;
        resp.address = pkt.address + 1 + zeroExtend(burst_done);
        resp.task_id = pkt.task_id;
        resp.cpu_id = pkt.cpu_id;
        resp.message_type = BT_READ;
        
        bounceFifo.enq(resp);
        
        if(burst_done == burst_max - 1) begin
            pkt_valid <= False;
            burst_max <= 0;
            burst_done <= 0;
        end
        else
            burst_done <= burst_done + 1;
    endrule
    
    interface Put request;
        method Action put(BluetreeClientPacket pkt);
            let t <- $time();
            BluetreeData inter_t = zeroExtend(t);
            $display("MEMBOUNCE: Putting packet for CPU %d address %x (%d) @ time %d diff %d", pkt.cpu_id, pkt.address, pkt.address, inter_t, (inter_t - pkt.data) / 10);
           if(pkt.message_type == BT_STANDARD)
                $display("MEMBOUNCE: Packet is standard");
            else if(pkt.message_type == BT_PREFETCH)
                $display("MEMBOUNCE: Packet is prefetch");
            else if(pkt.message_type == BT_PREFETCH_HIT)
                $display("MEMBOUNCE: ERROR: Packet is prefetch hit chain");
            incomingFifo.enq(pkt);
        endmethod
    endinterface
    
    interface Get response;
        method ActionValue#(BluetreeServerPacket) get();
            bounceFifo.deq();
            
            return bounceFifo.first();
        endmethod
    endinterface
endmodule



endpackage