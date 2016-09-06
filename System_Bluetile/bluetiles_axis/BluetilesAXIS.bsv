package BluetilesAXIS;

import Bluetiles::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import AxiStream::*;

interface BluetilesAXIS;
    interface BlueClient bluetile;

    (* prefix = "" *)
    interface AXISMasterLast#(DWord) master;

    (* prefix = "" *)
    interface AXISSlave#(DWord)  slave;
endinterface

(* synthesize *)
module mkBluetilesAXIS(BluetilesAXIS);
    FIFOF#(DWord) cpuToBluetile <- mkFIFOF();
    FIFOF#(DWord) bluetileToCpu <- mkFIFOF();

    PulseWire slaveReady <- mkPulseWire();

    Reg#(PacketSize) flitsRemaining <- mkReg(0);

    // AXI-Stream will relay a packet when both TREADY and TVALID are high in the
    // same cycle. TVALID is mapped to get_data's RDY signal, hence is equivalent
    // to bluetileToCpu.notEmpty. slaveReady is effectively mapped to TREADY.
    rule deqBluetileToCpu(slaveReady);
        bluetileToCpu.deq();
    endrule

    rule setFlitsRemainingNewPacket(flitsRemaining == 0);
        BT_Header_0 header = unpack(bluetileToCpu.first());
        flitsRemaining <= header.size;
    endrule

    // A flit will be relayed when the slave is ready (TREADY high) and we have data to relay (TVALID high)
    rule decFlitsRemaining(flitsRemaining != 0 && slaveReady && bluetileToCpu.notEmpty());
        flitsRemaining <= flitsRemaining - 1;
    endrule

    interface BlueClient bluetile;
        interface request = toGet(cpuToBluetile);
        interface response = toPut(bluetileToCpu);
    endinterface

    interface AXISMasterLast master;
        method DWord get_data();
            return bluetileToCpu.first();
        endmethod

        // This basically just relays TREADY to other rules.
        method Action slave_is_ready();
            slaveReady.send();
        endmethod

        // This is required for proper AXI Memory Mapped FIFO support.
        method Bit#(1) slave_is_last();
            // Are we currently sending the last flit?
            if(flitsRemaining == 1)
                return 1;
            else
                return 0;
        endmethod
    endinterface

    interface AXISSlave slave;
        method Action put_data(DWord data);
            // Guarding this looks a little weird, but bear with me
            // The implicit conditions on .enq will ensure that S_AXIS_TREADY will only
            // go high when the FIFO is not full, as expected. Despite this, S_AXIS_TVALID
            // may still go high even when READY is low, because of the AXI4Stream interface spec.
            // If TVALID goes high when TREADY is low, this would cause the method to fire even though
            // the method logically cannot fire, which can cause a FIFO overflow. Explicitly guarding
            // the FIFO like this prevents such a scenario from happening.
            if(cpuToBluetile.notFull()) begin
                cpuToBluetile.enq(data);
            end
        endmethod
    endinterface
endmodule

endpackage
