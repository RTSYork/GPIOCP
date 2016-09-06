// Membership: Bluetiles
// Purpose: Respond to ping packets (for testing)

package TilePingPong;

export IfcTilePingPong(..);
export mkTilePingPong;

import FIFO::*;
import GetPut::*;
import Vector::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;

interface IfcTilePingPong;
    interface BlueClient bluetile;
endinterface

(* synthesize *)
module mkTilePingPong#(parameter Bit#(8) ignore) (IfcTilePingPong);
	FIFO#(BlueBits) i <- mkFIFO();
	FIFO#(BlueBits) o <- mkFIFO();
    Reg#(PacketSize) size_countdown <- mkReg(0);
    Reg#(BT_Header_0) rx_h0 <- mkReg(unpack(0));
    Reg#(BT_Header_1) rx_h1 <- mkReg(unpack(0));
    BT_Header rx_h = bt_header_combine(rx_h0, rx_h1);
    Bool ping_pong = (rx_h1.dest_port == 8'h03);

    Stmt controller = seq
        action
            i.deq();    // Request header 0 received
            rx_h0 <= unpack(i.first());
        endaction
        action
            i.deq();    // Request header 1 received
            rx_h1 <= unpack(i.first());
        endaction
        if (ping_pong) seq
            // Generate ping/pong reply
            o.enq(pack(bt_make_reply(rx_h, rx_h0.size - 1).h0));
            o.enq(pack(bt_make_reply(rx_h, rx_h0.size - 1).h1));
        endseq
        size_countdown <= rx_h0.size - 1;
        // Request payload 
        while (size_countdown != 0) action
            size_countdown <= size_countdown - 1;
            if (ping_pong) begin
                o.enq(i.first());
            end
            i.deq();
        endaction
    endseq;

    FSM controllerFSM <- mkFSM(controller);

    rule on_reset;
        controllerFSM.start();
    endrule

    interface BlueClient bluetile;
        interface response = toPut(i);
        interface request = toGet(o);
    endinterface
endmodule


endpackage
